-- Migration: Enforce exact unique username matching PRD FR-AUTH-01
-- Replaces previous random UUID suffixing with strict username uniqueness.

create or replace function private.handle_new_user()
 returns trigger
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare
  candidate_username text;
begin
  candidate_username := btrim(coalesce(new.raw_user_meta_data ->> 'username', ''));
  if candidate_username = '' then
    candidate_username := split_part(coalesce(new.email, ''), '@', 1);
  end if;

  candidate_username := lower(btrim(candidate_username));

  if char_length(candidate_username) < 3 or char_length(candidate_username) > 60 then
    raise exception 'Username must be between 3 and 60 characters long';
  end if;

  if candidate_username !~ '^[a-z0-9_]+$' then
    raise exception 'Username can only contain alphanumeric characters and underscores';
  end if;

  if exists (select 1 from public.profiles where lower(username) = candidate_username) then
    raise exception 'Username "%" is already taken', candidate_username
      using errcode = 'unique_violation';
  end if;

  insert into public.profiles (id, username, full_name, role, status)
  values (
    new.id,
    candidate_username,
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    'farmer',
    'active'
  );
  return new;
end;
$function$;

alter table public.profiles replica identity full;
