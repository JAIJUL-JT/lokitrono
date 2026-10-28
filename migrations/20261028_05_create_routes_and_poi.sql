-- MIGRACION FASE 5: Modulos de Rutas, Patrimonio y Puntos de Interes
-- Compatible 100% con produccion (Zero-Downtime, no destructiva)

-- 1. TABLA tourist_routes
create table if not exists tourist_routes (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id) on delete cascade,
  title text not null,
  slug text unique not null,
  description text,
  route_type text not null,
  difficulty text default 'facil',
  estimated_duration_minutes integer,
  distance_km numeric(6,2),
  banner_url text,
  geojson_track jsonb,
  is_active boolean default true,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_tourist_routes_campaign on tourist_routes(campaign_id);
create index if not exists idx_tourist_routes_type on tourist_routes(route_type);

-- 2. TABLA route_stops
create table if not exists route_stops (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references tourist_routes(id) on delete cascade,
  entity_id uuid references campaign_entities(id) on delete set null,
  stop_order integer not null,
  title text not null,
  description text,
  image_url text,
  audio_guide_url text,
  latitude double precision not null,
  longitude double precision not null,
  estimated_stay_minutes integer default 15,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  unique (route_id, stop_order)
);

create index if not exists idx_route_stops_route on route_stops(route_id);

-- 3. TABLA user_route_completions
create table if not exists user_route_completions (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references tourist_routes(id) on delete cascade,
  user_identifier text not null,
  stops_completed integer default 0,
  total_stops integer not null,
  completed boolean default false,
  completed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (route_id, user_identifier)
);

create index if not exists idx_user_route_completions_user on user_route_completions(user_identifier);

-- 4. RLS Y POLITICAS DE SEGURIDAD
alter table tourist_routes enable row level security;
alter table route_stops enable row level security;
alter table user_route_completions enable row level security;

do 
begin
  if not exists (select 1 from pg_policies where policyname = 'Rutas activas son legibles publicamente') then
    create policy  Rutas activas son legibles publicamente on tourist_routes for select using (is_active = true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Paradas de ruta son legibles publicamente') then
    create policy Paradas de ruta son legibles publicamente on route_stops for select using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Usuarios leen sus progresos de ruta') then
    create policy Usuarios leen sus progresos de ruta on user_route_completions for select using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Usuarios gestionan sus progresos de ruta') then
    create policy Usuarios gestionan sus progresos de ruta on user_route_completions for all using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins gestionan rutas y paradas') then
    create policy Superadmins gestionan rutas y paradas on tourist_routes for all to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins gestionan paradas') then
    create policy Superadmins gestionan paradas on route_stops for all to authenticated using (true);
  end if;
end ;
