-- Run as postgres. All fixtures and changes are rolled back, including failures.
BEGIN;

CREATE TEMP TABLE rls_test_results (test_name text, passed boolean)
ON COMMIT DROP;

DO $tests$
DECLARE
  farmer_id uuid := gen_random_uuid();
  admin_id uuid := gen_random_uuid();
  viewer_id uuid := gen_random_uuid();
  changed integer;
  visible integer;
  observed text;
  denied boolean := false;
  passed_tests text[] := '{}';
BEGIN
  PERFORM set_config('request.jwt.claims', '{}', true);
  INSERT INTO auth.users
    (id, aud, role, email, encrypted_password, raw_user_meta_data, created_at, updated_at)
  SELECT fixture.id, 'authenticated', 'authenticated',
    'm2-' || fixture.id || '@example.invalid', '!',
    jsonb_build_object('username', 'm2_' || replace(fixture.id::text, '-', '')),
    now(), now()
  FROM unnest(ARRAY[farmer_id, admin_id, viewer_id]) AS fixture(id);

  UPDATE public.profiles SET role = 'admin' WHERE id = admin_id;
  UPDATE public.profiles SET role = 'viewer' WHERE id = viewer_id;

  -- TEST: Duplicate username registration is rejected per FR-AUTH-01
  denied := false;
  BEGIN
    INSERT INTO auth.users
      (id, aud, role, email, encrypted_password, raw_user_meta_data, created_at, updated_at)
    VALUES
      (gen_random_uuid(), 'authenticated', 'authenticated',
       'm2-dup@example.invalid', '!',
       jsonb_build_object('username', 'm2_' || replace(farmer_id::text, '-', '')),
       now(), now());
  EXCEPTION WHEN raise_exception OR unique_violation THEN
    denied := true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'Duplicate username registration was not rejected'; END IF;
  passed_tests := array_append(passed_tests, 'Duplicate username registration is rejected');

  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', farmer_id, 'role', 'authenticated')::text, true);
  IF current_user <> 'authenticated' OR auth.uid() IS DISTINCT FROM farmer_id THEN
    RAISE EXCEPTION 'The test is not running as the farmer';
  END IF;

  denied := false;
  BEGIN
    UPDATE public.profiles SET role = 'admin' WHERE id = farmer_id;
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Only an active admin can change profile role or status' THEN
      RAISE;
    END IF;
    denied := true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'Farmer role escalation was not rejected'; END IF;

  SELECT role INTO observed FROM public.profiles WHERE id = farmer_id;
  IF observed IS DISTINCT FROM 'farmer' THEN
    RAISE EXCEPTION 'Farmer role was modified despite denial (expected farmer, got %)', observed;
  END IF;

  passed_tests := array_append(passed_tests, 'Farmer cannot elevate their role');

  UPDATE public.profiles SET full_name = 'M2 allowed update'
    WHERE id = farmer_id RETURNING full_name INTO observed;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 1 OR observed IS DISTINCT FROM 'M2 allowed update' THEN
    RAISE EXCEPTION 'Farmer could not update their own name';
  END IF;
  passed_tests := array_append(passed_tests, 'Farmer can update their name');

  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', viewer_id, 'role', 'authenticated')::text, true);
  SELECT count(*) INTO visible FROM public.profiles
    WHERE id IN (farmer_id, admin_id, viewer_id);
  IF visible <> 1 THEN RAISE EXCEPTION 'Viewer can read another profile'; END IF;
  UPDATE public.profiles SET full_name = 'M2 forbidden update' WHERE id = farmer_id;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 0 THEN RAISE EXCEPTION 'Viewer changed another profile'; END IF;

  -- Switch to farmer to verify the profile was not modified (viewer cannot read farmer's row)
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', farmer_id, 'role', 'authenticated')::text, true);
  SELECT full_name INTO observed FROM public.profiles WHERE id = farmer_id;
  IF observed IS DISTINCT FROM 'M2 allowed update' THEN
    RAISE EXCEPTION 'Farmer profile was modified by viewer despite denial';
  END IF;
  passed_tests := array_append(passed_tests, 'Viewer cannot read or change other profiles');

  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', admin_id, 'role', 'authenticated')::text, true);
  UPDATE public.profiles SET role = 'viewer'
    WHERE id = farmer_id RETURNING role INTO observed;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 1 OR observed IS DISTINCT FROM 'viewer' THEN
    RAISE EXCEPTION 'Admin could not change the target role';
  END IF;
  passed_tests := array_append(passed_tests, 'Admin can change another account role');

  UPDATE public.profiles SET status = 'suspended'
    WHERE id = farmer_id RETURNING status INTO observed;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 1 OR observed IS DISTINCT FROM 'suspended' THEN
    RAISE EXCEPTION 'Admin could not suspend the target account';
  END IF;
  passed_tests := array_append(passed_tests, 'Admin can suspend an account');

  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', farmer_id, 'role', 'authenticated')::text, true);
  UPDATE public.profiles SET full_name = 'M2 forbidden suspended update'
    WHERE id = farmer_id;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 0 THEN RAISE EXCEPTION 'Suspended account changed its profile'; END IF;
  SELECT full_name INTO observed FROM public.profiles WHERE id = farmer_id;
  IF observed IS DISTINCT FROM 'M2 allowed update' THEN
    RAISE EXCEPTION 'Suspended profile was modified despite denial';
  END IF;
  passed_tests := array_append(passed_tests, 'Suspended account cannot update its profile');

  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', admin_id, 'role', 'authenticated')::text, true);
  UPDATE public.profiles SET status = 'active'
    WHERE id = farmer_id RETURNING status INTO observed;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 1 OR observed IS DISTINCT FROM 'active' THEN
    RAISE EXCEPTION 'Admin could not reactivate the target account';
  END IF;
  passed_tests := array_append(passed_tests, 'Admin can reactivate an account');

  RESET ROLE;
  SET LOCAL ROLE anon;
  PERFORM set_config('request.jwt.claims', '{"role":"anon"}', true);
  BEGIN
    SELECT count(*) INTO visible FROM public.profiles
      WHERE id IN (farmer_id, admin_id, viewer_id);
    IF visible <> 0 THEN RAISE EXCEPTION 'Guest can read private profiles'; END IF;
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
  passed_tests := array_append(passed_tests, 'Guest cannot read private profiles');

  -- =========================================================================
  -- MILESTONE 3: Plant Tracking, Private Images, Notes & Access Control (RLS)
  -- =========================================================================
  RESET ROLE;
  UPDATE public.profiles SET role = 'farmer', status = 'active' WHERE id = farmer_id;

  DECLARE
    m3_plant_id uuid := gen_random_uuid();
    m3_image_id uuid := gen_random_uuid();
    m3_note_id uuid := gen_random_uuid();
  BEGIN
    -- 1. Farmer creates their own plant
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims',
      jsonb_build_object('sub', farmer_id, 'role', 'authenticated')::text, true);

    INSERT INTO public.plants (id, owner_id, name, location, planted_on, notes, status)
    VALUES (m3_plant_id, farmer_id, 'M3 Test Tomato', 'Tower A', CURRENT_DATE, 'Test plant notes', 'active');
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 1 THEN RAISE EXCEPTION 'Farmer could not create plant'; END IF;
    passed_tests := array_append(passed_tests, 'M3: Farmer can create owned plant');

    -- 2. Farmer uploads plant image record
    INSERT INTO public.plant_images (id, plant_id, uploaded_by, storage_path, source, captured_at, file_size_bytes, mime_type)
    VALUES (m3_image_id, m3_plant_id, farmer_id, farmer_id::text || '/' || m3_plant_id::text || '/test_01.jpg', 'camera', now(), 204800, 'image/jpeg');
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 1 THEN RAISE EXCEPTION 'Farmer could not create plant image metadata'; END IF;
    passed_tests := array_append(passed_tests, 'M3: Farmer can register plant image');

    -- 3. Farmer creates observation note
    INSERT INTO public.observation_notes (id, plant_id, author_id, note, observed_at)
    VALUES (m3_note_id, m3_plant_id, farmer_id, 'Leaf growth is healthy and green.', now());
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 1 THEN RAISE EXCEPTION 'Farmer could not create observation note'; END IF;
    passed_tests := array_append(passed_tests, 'M3: Farmer can create observation note');

    -- 4. Viewer cannot see or access farmer plant without explicit grant
    PERFORM set_config('request.jwt.claims',
      jsonb_build_object('sub', viewer_id, 'role', 'authenticated')::text, true);

    SELECT count(*) INTO visible FROM public.plants WHERE id = m3_plant_id;
    IF visible <> 0 THEN RAISE EXCEPTION 'Unpermitted viewer can see farmer plant'; END IF;

    SELECT count(*) INTO visible FROM public.plant_images WHERE plant_id = m3_plant_id;
    IF visible <> 0 THEN RAISE EXCEPTION 'Unpermitted viewer can see farmer plant image'; END IF;

    SELECT count(*) INTO visible FROM public.observation_notes WHERE plant_id = m3_plant_id;
    IF visible <> 0 THEN RAISE EXCEPTION 'Unpermitted viewer can see farmer plant notes'; END IF;
    passed_tests := array_append(passed_tests, 'M3: Viewer cannot access unshared plant data');

    -- 5. Viewer cannot insert image or note for farmer plant
    denied := false;
    BEGIN
      INSERT INTO public.plant_images (plant_id, uploaded_by, storage_path, source)
      VALUES (m3_plant_id, viewer_id, viewer_id::text || '/' || m3_plant_id::text || '/unauthorized.jpg', 'gallery');
    EXCEPTION WHEN insufficient_privilege OR raise_exception THEN
      denied := true;
    END;
    IF NOT denied THEN RAISE EXCEPTION 'Viewer was able to upload image to farmer plant'; END IF;

    denied := false;
    BEGIN
      INSERT INTO public.observation_notes (plant_id, author_id, note)
      VALUES (m3_plant_id, viewer_id, 'Unauthorized note');
    EXCEPTION WHEN insufficient_privilege OR raise_exception THEN
      denied := true;
    END;
    IF NOT denied THEN RAISE EXCEPTION 'Viewer was able to add note to farmer plant'; END IF;
    passed_tests := array_append(passed_tests, 'M3: Viewer cannot mutate unshared plant or children');

    -- 6. Grant viewer explicit read access via plant_access
    PERFORM set_config('request.jwt.claims',
      jsonb_build_object('sub', farmer_id, 'role', 'authenticated')::text, true);

    INSERT INTO public.plant_access (plant_id, viewer_id, granted_by)
    VALUES (m3_plant_id, viewer_id, farmer_id);
    passed_tests := array_append(passed_tests, 'M3: Farmer can grant plant access to viewer');

    -- 7. Permitted Viewer can read plant and images, but STILL cannot mutate
    PERFORM set_config('request.jwt.claims',
      jsonb_build_object('sub', viewer_id, 'role', 'authenticated')::text, true);

    SELECT count(*) INTO visible FROM public.plants WHERE id = m3_plant_id;
    IF visible <> 1 THEN RAISE EXCEPTION 'Permitted viewer cannot read shared plant'; END IF;

    SELECT count(*) INTO visible FROM public.plant_images WHERE plant_id = m3_plant_id;
    IF visible <> 1 THEN RAISE EXCEPTION 'Permitted viewer cannot read shared plant images'; END IF;

    UPDATE public.plants SET name = 'Hacked Name' WHERE id = m3_plant_id;
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 0 THEN RAISE EXCEPTION 'Permitted viewer mutated plant name'; END IF;

    DELETE FROM public.plants WHERE id = m3_plant_id;
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 0 THEN RAISE EXCEPTION 'Permitted viewer deleted plant'; END IF;
    passed_tests := array_append(passed_tests, 'M3: Permitted viewer has read-only access and cannot mutate');

    -- 8. Storage path validation tests
    IF NOT private.is_valid_plant_image_path(farmer_id::text || '/' || m3_plant_id::text || '/pic.jpg', farmer_id) THEN
      RAISE EXCEPTION 'Storage path validation failed for plant owner';
    END IF;

    IF private.is_valid_plant_image_path(viewer_id::text || '/' || m3_plant_id::text || '/pic.jpg', viewer_id) THEN
      RAISE EXCEPTION 'Storage path validation permitted non-owner upload';
    END IF;
    passed_tests := array_append(passed_tests, 'M3: Private storage RLS path validation verified');
  END;

  RESET ROLE;
  INSERT INTO rls_test_results
    SELECT test_name, true FROM unnest(passed_tests) AS results(test_name);
END;
$tests$;

SELECT test_name, passed FROM rls_test_results;
ROLLBACK;
