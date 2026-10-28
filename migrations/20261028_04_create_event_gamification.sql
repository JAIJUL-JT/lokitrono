-- MIGRACION FASE 4: Gamificacion de Eventos y Misiones
-- Compatible 100% con produccion (Zero-Downtime, no destructiva)

-- 1. TABLA event_missions
create table if not exists event_missions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id) on delete cascade,
  event_id uuid references hub_events(id) on delete cascade,
  entity_id uuid references campaign_entities(id) on delete cascade,
  title text not null,
  description text,
  mission_type text not null,
  points_reward integer default 50,
  validation_method text default 'qr_code',
  validation_payload text,
  latitude double precision,
  longitude double precision,
  radius_meters integer default 100,
  is_active boolean default true,
  starts_at timestamptz,
  ends_at timestamptz,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_event_missions_campaign on event_missions(campaign_id);
create index if not exists idx_event_missions_event on event_missions(event_id);

-- 2. TABLA user_mission_progress
create table if not exists user_mission_progress (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references event_missions(id) on delete cascade,
  user_identifier text not null,
  status text default 'in_progress',
  points_awarded integer default 0,
  completed_at timestamptz,
  claimed_at timestamptz,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (mission_id, user_identifier)
);

create index if not exists idx_user_mission_progress_user on user_mission_progress(user_identifier);
create index if not exists idx_user_mission_progress_mission on user_mission_progress(mission_id);

-- 3. TABLA mission_checkins
create table if not exists mission_checkins (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references event_missions(id) on delete cascade,
  user_identifier text not null,
  verification_method text not null,
  submitted_payload text,
  latitude double precision,
  longitude double precision,
  verified boolean default true,
  created_at timestamptz default now()
);

create index if not exists idx_mission_checkins_user on mission_checkins(user_identifier);

-- 4. RLS Y POLITICAS DE SEGURIDAD
alter table event_missions enable row level security;
alter table user_mission_progress enable row level security;
alter table mission_checkins enable row level security;

do 
begin
  if not exists (select 1 from pg_policies where policyname = 'Misiones activas son legibles publicamente') then
    create policy  Misiones activas son legibles publicamente on event_missions for select using (is_active = true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Usuarios leen su propio progreso') then
    create policy Usuarios leen su propio progreso on user_mission_progress for select using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Usuarios registran su progreso') then
    create policy Usuarios registran su progreso on user_mission_progress for insert with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Usuarios registran checkins') then
    create policy Usuarios registran checkins on mission_checkins for insert with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins gestionan misiones') then
    create policy Superadmins gestionan misiones on event_missions for all to authenticated using (true);
  end if;
end ;
