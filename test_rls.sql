-- test_rls.sql
-- This script tests the Supabase RLS policies and triggers for the profiles table.
-- It demonstrates allowed and denied operations based on user roles and JWT claims.

CREATE TEMP TABLE rls_test_results (test_name text, passed boolean, error text);

DO $$
BEGIN
  -- SETUP: Create mock users for testing
  INSERT INTO auth.users (id, aud, role, email, encrypted_password, created_at, updated_at)
  VALUES 
    ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'farmer@test.com', 'test', now(), now()),
    ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'admin@test.com', 'test', now(), now()),
    ('33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'viewer@test.com', 'test', now(), now())
  ON CONFLICT DO NOTHING;
  
  -- Force set the roles and statuses for our test cases
  UPDATE public.profiles SET role = 'farmer', status = 'active' WHERE id = '11111111-1111-1111-1111-111111111111';
  UPDATE public.profiles SET role = 'admin', status = 'active' WHERE id = '22222222-2222-2222-2222-222222222222';
  UPDATE public.profiles SET role = 'viewer', status = 'active' WHERE id = '33333333-3333-3333-3333-333333333333';

  -- TEST 1: Normal user (farmer) updating own role -> DENIED (Trigger exception)
  BEGIN
    SET LOCAL role = authenticated;
    SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';
    UPDATE public.profiles SET role = 'admin' WHERE id = '11111111-1111-1111-1111-111111111111';
    RESET role;
    INSERT INTO rls_test_results VALUES ('Normal user updates own role', false, 'Expected exception but succeeded');
  EXCEPTION WHEN OTHERS THEN
    RESET role;
    INSERT INTO rls_test_results VALUES ('Normal user updates own role', true, SQLERRM);
  END;

  -- TEST 2: Admin updating someone else's role -> ALLOWED
  BEGIN
    SET LOCAL role = authenticated;
    SET LOCAL request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';
    UPDATE public.profiles SET role = 'viewer' WHERE id = '11111111-1111-1111-1111-111111111111';
    RESET role;
    INSERT INTO rls_test_results VALUES ('Admin updates another user role', true, null);
  EXCEPTION WHEN OTHERS THEN
    RESET role;
    INSERT INTO rls_test_results VALUES ('Admin updates another user role', false, SQLERRM);
  END;

  -- TEST 3: User changing own full_name -> ALLOWED
  BEGIN
    SET LOCAL role = authenticated;
    SET LOCAL request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';
    UPDATE public.profiles SET full_name = 'New Name' WHERE id = '11111111-1111-1111-1111-111111111111';
    RESET role;
    INSERT INTO rls_test_results VALUES ('User updates own full_name', true, null);
  EXCEPTION WHEN OTHERS THEN
    RESET role;
    INSERT INTO rls_test_results VALUES ('User updates own full_name', false, SQLERRM);
  END;

  -- TEST 4: Viewer trying to update another user's profile -> DENIED (RLS hides row, 0 affected)
  BEGIN
    SET LOCAL role = authenticated;
    SET LOCAL request.jwt.claims = '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';
    UPDATE public.profiles SET full_name = 'Hacked' WHERE id = '11111111-1111-1111-1111-111111111111';
    IF FOUND THEN
      RESET role;
      INSERT INTO rls_test_results VALUES ('Viewer updates another user profile', false, 'Expected 0 rows affected but updated');
    ELSE
      RESET role;
      INSERT INTO rls_test_results VALUES ('Viewer updates another user profile', true, '0 rows affected due to RLS');
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RESET role;
    INSERT INTO rls_test_results VALUES ('Viewer updates another user profile', true, SQLERRM);
  END;
END;
$$;

SELECT * FROM rls_test_results;
