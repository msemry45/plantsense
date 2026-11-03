create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;

revoke all on schema private from public;
revoke all on schema public from public;
grant usage on schema public to anon, authenticated, service_role;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  full_name text,
  avatar_url text,
  role text not null default 'farmer'
    constraint profiles_role_check check (role in ('admin', 'farmer', 'viewer')),
  status text not null default 'active'
    constraint profiles_status_check check (status in ('active', 'suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_length_check check (char_length(username) between 3 and 60)
);

create table public.species (
  id uuid primary key default gen_random_uuid(),
  common_name text not null,
  scientific_name text,
  description text,
  care_instructions text,
  ideal_temperature_min numeric(5,2),
  ideal_temperature_max numeric(5,2),
  ideal_humidity_min numeric(5,2),
  ideal_humidity_max numeric(5,2),
  ideal_light_conditions text,
  image_path text,
  is_published boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint species_temperature_range_check check (
    ideal_temperature_min is null or ideal_temperature_max is null
    or ideal_temperature_min <= ideal_temperature_max
  ),
  constraint species_humidity_values_check check (
    (ideal_humidity_min is null or ideal_humidity_min between 0 and 100)
    and (ideal_humidity_max is null or ideal_humidity_max between 0 and 100)
  ),
  constraint species_humidity_range_check check (
    ideal_humidity_min is null or ideal_humidity_max is null
    or ideal_humidity_min <= ideal_humidity_max
  )
);

create table public.plants (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  species_id uuid references public.species(id) on delete set null,
  name text not null,
  location text,
  planted_on date,
  notes text,
  status text not null default 'active'
    constraint plants_status_check check (status in ('active', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint plants_name_length_check check (char_length(name) between 1 and 100)
);

create table public.plant_access (
  plant_id uuid not null references public.plants(id) on delete cascade,
  viewer_id uuid not null references public.profiles(id) on delete cascade,
  granted_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (plant_id, viewer_id)
);

create table public.plant_images (
  id uuid primary key default gen_random_uuid(),
  plant_id uuid not null references public.plants(id) on delete cascade,
  uploaded_by uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null unique,
  source text not null default 'gallery'
    constraint plant_images_source_check check (source in ('camera', 'gallery')),
  captured_at timestamptz not null default now(),
  width integer,
  height integer,
  file_size_bytes bigint,
  mime_type text,
  created_at timestamptz not null default now(),
  constraint plant_images_width_check check (width is null or width > 0),
  constraint plant_images_height_check check (height is null or height > 0),
  constraint plant_images_size_check check (file_size_bytes is null or file_size_bytes > 0),
  constraint plant_images_mime_check check (
    mime_type is null or mime_type in (
      'image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'
    )
  )
);

create table public.observation_notes (
  id uuid primary key default gen_random_uuid(),
  plant_id uuid not null references public.plants(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  note text not null,
  observed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint observation_notes_note_check check (char_length(btrim(note)) > 0)
);

create table public.analysis_requests (
  id uuid primary key default gen_random_uuid(),
  plant_id uuid not null references public.plants(id) on delete cascade,
  image_id uuid not null references public.plant_images(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade,
  idempotency_key text not null,
  status text not null default 'pending'
    constraint analysis_requests_status_check
      check (status in ('pending', 'processing', 'completed', 'failed')),
  model_provider text,
  model_name text,
  error_message text,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  unique (requested_by, idempotency_key),
  constraint analysis_requests_key_check check (char_length(idempotency_key) between 8 and 200)
);

create table public.diagnoses (
  id uuid primary key default gen_random_uuid(),
  analysis_request_id uuid not null unique
    references public.analysis_requests(id) on delete cascade,
  plant_id uuid not null references public.plants(id) on delete cascade,
  image_id uuid not null references public.plant_images(id) on delete cascade,
  label text not null,
  summary text,
  confidence numeric(5,4),
  severity text not null default 'unknown'
    constraint diagnoses_severity_check
      check (severity in ('healthy', 'low', 'medium', 'high', 'unknown')),
  recommendations jsonb not null default '[]'::jsonb,
  raw_response jsonb,
  created_at timestamptz not null default now(),
  constraint diagnoses_confidence_check check (confidence is null or confidence between 0 and 1),
  constraint diagnoses_recommendations_check check (jsonb_typeof(recommendations) = 'array')
);

create table public.care_tasks (
  id uuid primary key default gen_random_uuid(),
  plant_id uuid not null references public.plants(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  task_type text not null default 'other'
    constraint care_tasks_type_check
      check (task_type in ('watering', 'fertilizing', 'pruning', 'inspection', 'other')),
  due_at timestamptz,
  repeat_every_days integer,
  status text not null default 'pending'
    constraint care_tasks_status_check check (status in ('pending', 'completed', 'cancelled')),
  completed_at timestamptz,
  completed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint care_tasks_title_check check (char_length(btrim(title)) > 0),
  constraint care_tasks_repeat_check check (repeat_every_days is null or repeat_every_days > 0),
  constraint care_tasks_completion_check check (
    (status = 'completed' and completed_at is not null)
    or (status <> 'completed')
  )
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plant_id uuid references public.plants(id) on delete set null,
  diagnosis_id uuid references public.diagnoses(id) on delete set null,
  care_task_id uuid references public.care_tasks(id) on delete set null,
  type text not null default 'general'
    constraint notifications_type_check check (type in ('diagnosis', 'care', 'general')),
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  constraint notifications_title_check check (char_length(btrim(title)) > 0),
  constraint notifications_body_check check (char_length(btrim(body)) > 0)
);

create index profiles_role_status_idx on public.profiles (role, status);
create index species_publish_status_idx on public.species (common_name) where is_published;
create index species_created_by_idx on public.species (created_by) where created_by is not null;
create index species_updated_by_idx on public.species (updated_by) where updated_by is not null;
create index plants_owner_id_idx on public.plants (owner_id);
create index plants_species_id_idx on public.plants (species_id) where species_id is not null;
create index plants_owner_name_idx on public.plants (owner_id, name);
create index plant_access_viewer_id_idx on public.plant_access (viewer_id);
create index plant_access_granted_by_idx on public.plant_access (granted_by) where granted_by is not null;
create index plant_images_plant_captured_idx on public.plant_images (plant_id, captured_at desc);
create index plant_images_uploaded_by_idx on public.plant_images (uploaded_by);
create index observation_notes_plant_observed_idx
  on public.observation_notes (plant_id, observed_at desc);
create index observation_notes_author_id_idx on public.observation_notes (author_id);
create index analysis_requests_plant_created_idx
  on public.analysis_requests (plant_id, created_at desc);
create index analysis_requests_image_id_idx on public.analysis_requests (image_id);
create index analysis_requests_requested_by_idx on public.analysis_requests (requested_by);
create index analysis_requests_pending_idx
  on public.analysis_requests (created_at) where status in ('pending', 'processing');
create index diagnoses_plant_created_idx on public.diagnoses (plant_id, created_at desc);
create index diagnoses_image_id_idx on public.diagnoses (image_id);
create index care_tasks_plant_due_idx on public.care_tasks (plant_id, due_at);
create index care_tasks_created_by_idx on public.care_tasks (created_by);
create index care_tasks_completed_by_idx on public.care_tasks (completed_by)
  where completed_by is not null;
create index care_tasks_pending_due_idx on public.care_tasks (due_at)
  where status = 'pending';
create index notifications_user_created_idx
  on public.notifications (user_id, created_at desc);
create index notifications_user_unread_idx
  on public.notifications (user_id, created_at desc) where not is_read;
create index notifications_plant_id_idx on public.notifications (plant_id)
  where plant_id is not null;
create index notifications_diagnosis_id_idx on public.notifications (diagnosis_id)
  where diagnosis_id is not null;
create index notifications_care_task_id_idx on public.notifications (care_task_id)
  where care_task_id is not null;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function private.is_active_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = p_user_id and p.status = 'active'
  );
$$;

create or replace function private.is_admin(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = p_user_id and p.role = 'admin' and p.status = 'active'
  );
$$;

create or replace function private.is_viewer(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = p_user_id and p.role = 'viewer' and p.status = 'active'
  );
$$;

create or replace function private.is_plant_owner(p_plant_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.plants p
    where p.id = p_plant_id
      and p.owner_id = p_user_id
      and exists (
        select 1 from public.profiles pr
        where pr.id = p_user_id and pr.status = 'active'
      )
  );
$$;

create or replace function private.can_read_plant(p_plant_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.plants p
    where p.id = p_plant_id
      and exists (
        select 1 from public.profiles pr
        where pr.id = p_user_id and pr.status = 'active'
      )
      and (
        p.owner_id = p_user_id
        or exists (
          select 1 from public.plant_access pa
          where pa.plant_id = p.id and pa.viewer_id = p_user_id
        )
      )
  );
$$;

create or replace function private.can_read_image(p_image_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.plant_images pi
    where pi.id = p_image_id
      and private.can_read_plant(pi.plant_id, p_user_id)
  );
$$;

create or replace function private.path_plant_id(object_name text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
begin
  return nullif(split_part(object_name, '/', 2), '')::uuid;
exception
  when invalid_text_representation then return null;
end;
$$;

create or replace function private.is_valid_plant_image_path(object_name text, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    split_part(object_name, '/', 1) = p_user_id::text
    and private.is_plant_owner(private.path_plant_id(object_name), p_user_id);
$$;

create or replace function private.can_read_plant_image_path(object_name text, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.can_read_plant(private.path_plant_id(object_name), p_user_id);
$$;

create or replace function private.protect_profile_admin_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (new.role is distinct from old.role or new.status is distinct from old.status)
     and auth.uid() is not null
     and not private.is_admin(auth.uid()) then
    raise exception 'Only an active admin can change profile role or status';
  end if;
  return new;
end;
$$;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_username text;
begin
  base_username := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'username'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'user'
  );

  insert into public.profiles (id, username, full_name, role, status)
  values (
    new.id,
    left(regexp_replace(lower(base_username), '[^a-z0-9_]+', '_', 'g'), 48)
      || '_' || left(new.id::text, 8),
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    'farmer',
    'active'
  );
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

create trigger profiles_protect_admin_fields
before update on public.profiles
for each row execute function private.protect_profile_admin_fields();

create trigger species_set_updated_at
before update on public.species
for each row execute function private.set_updated_at();

create trigger plants_set_updated_at
before update on public.plants
for each row execute function private.set_updated_at();

create trigger observation_notes_set_updated_at
before update on public.observation_notes
for each row execute function private.set_updated_at();

create trigger care_tasks_set_updated_at
before update on public.care_tasks
for each row execute function private.set_updated_at();

create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_user();

alter table public.profiles enable row level security;
alter table public.species enable row level security;
alter table public.plants enable row level security;
alter table public.plant_access enable row level security;
alter table public.plant_images enable row level security;
alter table public.observation_notes enable row level security;
alter table public.analysis_requests enable row level security;
alter table public.diagnoses enable row level security;
alter table public.care_tasks enable row level security;
alter table public.notifications enable row level security;

create policy profiles_select_self_or_admin
on public.profiles for select to authenticated
using (
  id = (select auth.uid())
  or (select private.is_admin((select auth.uid())))
);

create policy profiles_update_self_or_admin
on public.profiles for update to authenticated
using (
  (id = (select auth.uid()) and (select private.is_active_user((select auth.uid()))))
  or (select private.is_admin((select auth.uid())))
)
with check (
  (id = (select auth.uid()) and (select private.is_active_user((select auth.uid()))))
  or (select private.is_admin((select auth.uid())))
);

create policy species_public_read
on public.species for select to anon
using (is_published);

create policy species_authenticated_read
on public.species for select to authenticated
using (
  is_published
  or (select private.is_admin((select auth.uid())))
);

create policy species_admin_insert
on public.species for insert to authenticated
with check (
  (select private.is_admin((select auth.uid())))
  and (created_by is null or created_by = (select auth.uid()))
  and (updated_by is null or updated_by = (select auth.uid()))
);

create policy species_admin_update
on public.species for update to authenticated
using ((select private.is_admin((select auth.uid()))))
with check (
  (select private.is_admin((select auth.uid())))
  and (updated_by is null or updated_by = (select auth.uid()))
);

create policy species_admin_delete
on public.species for delete to authenticated
using ((select private.is_admin((select auth.uid()))));

create policy plants_read_permitted
on public.plants for select to authenticated
using ((select private.can_read_plant(id, (select auth.uid()))));

create policy plants_owner_insert
on public.plants for insert to authenticated
with check (
  owner_id = (select auth.uid())
  and (select private.is_active_user((select auth.uid())))
);

create policy plants_owner_update
on public.plants for update to authenticated
using ((select private.is_plant_owner(id, (select auth.uid()))))
with check (owner_id = (select auth.uid()));

create policy plants_owner_delete
on public.plants for delete to authenticated
using ((select private.is_plant_owner(id, (select auth.uid()))));

create policy plant_access_read
on public.plant_access for select to authenticated
using (
  viewer_id = (select auth.uid())
  or (select private.is_plant_owner(plant_id, (select auth.uid())))
);

create policy plant_access_owner_insert
on public.plant_access for insert to authenticated
with check (
  (select private.is_plant_owner(plant_id, (select auth.uid())))
  and granted_by = (select auth.uid())
  and (select private.is_viewer(viewer_id))
);

create policy plant_access_owner_delete
on public.plant_access for delete to authenticated
using ((select private.is_plant_owner(plant_id, (select auth.uid()))));

create policy plant_images_read_permitted
on public.plant_images for select to authenticated
using ((select private.can_read_plant(plant_id, (select auth.uid()))));

create policy plant_images_owner_insert
on public.plant_images for insert to authenticated
with check (
  uploaded_by = (select auth.uid())
  and (select private.is_plant_owner(plant_id, (select auth.uid())))
);

create policy plant_images_owner_delete
on public.plant_images for delete to authenticated
using ((select private.is_plant_owner(plant_id, (select auth.uid()))));

create policy observation_notes_read_permitted
on public.observation_notes for select to authenticated
using ((select private.can_read_plant(plant_id, (select auth.uid()))));

create policy observation_notes_owner_insert
on public.observation_notes for insert to authenticated
with check (
  author_id = (select auth.uid())
  and (select private.is_plant_owner(plant_id, (select auth.uid())))
);

create policy observation_notes_owner_update
on public.observation_notes for update to authenticated
using (
  author_id = (select auth.uid())
  and (select private.is_plant_owner(plant_id, (select auth.uid())))
)
with check (
  author_id = (select auth.uid())
  and (select private.is_plant_owner(plant_id, (select auth.uid())))
);

create policy observation_notes_owner_delete
on public.observation_notes for delete to authenticated
using ((select private.is_plant_owner(plant_id, (select auth.uid()))));

create policy analysis_requests_read_permitted
on public.analysis_requests for select to authenticated
using ((select private.can_read_plant(plant_id, (select auth.uid()))));

create policy analysis_requests_owner_insert
on public.analysis_requests for insert to authenticated
with check (
  requested_by = (select auth.uid())
  and (select private.is_plant_owner(plant_id, (select auth.uid())))
  and (select private.can_read_image(image_id, (select auth.uid())))
  and exists (
    select 1 from public.plant_images pi
    where pi.id = image_id and pi.plant_id = plant_id
  )
);

create policy diagnoses_read_permitted
on public.diagnoses for select to authenticated
using ((select private.can_read_plant(plant_id, (select auth.uid()))));

create policy care_tasks_read_permitted
on public.care_tasks for select to authenticated
using ((select private.can_read_plant(plant_id, (select auth.uid()))));

create policy care_tasks_owner_insert
on public.care_tasks for insert to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.is_plant_owner(plant_id, (select auth.uid())))
);

create policy care_tasks_owner_update
on public.care_tasks for update to authenticated
using ((select private.is_plant_owner(plant_id, (select auth.uid()))))
with check (
  (select private.is_plant_owner(plant_id, (select auth.uid())))
  and (completed_by is null or completed_by = (select auth.uid()))
);

create policy care_tasks_owner_delete
on public.care_tasks for delete to authenticated
using ((select private.is_plant_owner(plant_id, (select auth.uid()))));

create policy notifications_owner_select
on public.notifications for select to authenticated
using (user_id = (select auth.uid()));

create policy notifications_owner_update
on public.notifications for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy notifications_owner_delete
on public.notifications for delete to authenticated
using (user_id = (select auth.uid()));

revoke all on all tables in schema public from anon, authenticated;
grant select on public.species to anon;
grant select, insert, update, delete on
  public.profiles,
  public.species,
  public.plants,
  public.plant_access,
  public.plant_images,
  public.observation_notes,
  public.analysis_requests,
  public.diagnoses,
  public.care_tasks,
  public.notifications
to authenticated;
grant all privileges on all tables in schema public to service_role;

revoke all on all functions in schema private from public, anon, authenticated;
grant usage on schema private to authenticated, service_role;
grant execute on function private.is_active_user(uuid) to authenticated, service_role;
grant execute on function private.is_admin(uuid) to authenticated, service_role;
grant execute on function private.is_viewer(uuid) to authenticated, service_role;
grant execute on function private.is_plant_owner(uuid, uuid) to authenticated, service_role;
grant execute on function private.can_read_plant(uuid, uuid) to authenticated, service_role;
grant execute on function private.can_read_image(uuid, uuid) to authenticated, service_role;
grant execute on function private.path_plant_id(text) to authenticated, service_role;
grant execute on function private.is_valid_plant_image_path(text, uuid) to authenticated, service_role;
grant execute on function private.can_read_plant_image_path(text, uuid) to authenticated, service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'plant-images',
    'plant-images',
    false,
    10485760,
    array['image/jpeg','image/png','image/webp','image/heic','image/heif']
  ),
  (
    'species-images',
    'species-images',
    true,
    5242880,
    array['image/jpeg','image/png','image/webp']
  );

create policy plant_images_storage_read
on storage.objects for select to authenticated
using (
  bucket_id = 'plant-images'
  and (select private.can_read_plant_image_path(name, (select auth.uid())))
);

create policy plant_images_storage_insert
on storage.objects for insert to authenticated
with check (
  bucket_id = 'plant-images'
  and (select private.is_valid_plant_image_path(name, (select auth.uid())))
);

create policy plant_images_storage_update
on storage.objects for update to authenticated
using (
  bucket_id = 'plant-images'
  and (select private.is_valid_plant_image_path(name, (select auth.uid())))
)
with check (
  bucket_id = 'plant-images'
  and (select private.is_valid_plant_image_path(name, (select auth.uid())))
);

create policy plant_images_storage_delete
on storage.objects for delete to authenticated
using (
  bucket_id = 'plant-images'
  and (select private.is_valid_plant_image_path(name, (select auth.uid())))
);

create policy species_images_storage_insert
on storage.objects for insert to authenticated
with check (
  bucket_id = 'species-images'
  and (select private.is_admin((select auth.uid())))
);

create policy species_images_storage_update
on storage.objects for update to authenticated
using (
  bucket_id = 'species-images'
  and (select private.is_admin((select auth.uid())))
)
with check (
  bucket_id = 'species-images'
  and (select private.is_admin((select auth.uid())))
);

create policy species_images_storage_delete
on storage.objects for delete to authenticated
using (
  bucket_id = 'species-images'
  and (select private.is_admin((select auth.uid())))
);
