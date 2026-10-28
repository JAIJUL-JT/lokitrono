-- MIGRACION FASE 1: Sistema de Plantillas y Fundamentos de Campana
-- Compatible 100% con produccion (Zero-Downtime, no destructiva)

-- 1. TABLA templates
create table if not exists templates (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  category text,
  default_config jsonb default '{}'::jsonb,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_templates_code on templates(code);

-- 2. TABLA campaigns
create table if not exists campaigns (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references templates(id),
  code text unique not null,
  name text not null,
  description text,
  status text default 'draft',
  starts_at timestamptz,
  ends_at timestamptz,
  organization_name text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_campaigns_template on campaigns(template_id);
create index if not exists idx_campaigns_code on campaigns(code);

-- 3. TABLA campaign_theme (Marca Blanca)
create table if not exists campaign_theme (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid unique not null references campaigns(id) on delete cascade,
  logo_url text,
  banner_url text,
  primary_color text default '#0284c7',
  secondary_color text default '#0f172a',
  background_color text default '#f8fafc',
  custom_css text,
  updated_at timestamptz default now()
);

-- 4. TABLA campaign_settings
create table if not exists campaign_settings (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid unique not null references campaigns(id) on delete cascade,
  login_required boolean default false,
  show_ranking boolean default true,
  show_rewards boolean default true,
  show_history boolean default true,
  public_results boolean default true,
  max_votes integer default 1,
  settings jsonb default '{}'::jsonb,
  updated_at timestamptz default now()
);

-- 5. SEMILLAS DE DATOS INICIALES
insert into templates (code, name, category, description)
values
  ('BARRIOS', 'LokiTrono Barrios', 'competition', 'Competicion tradicional de barrios y gamificacion'),
  ('TURISMO', 'Portal Turismo y Rutas', 'tourism', 'Guia de experiencias, patrimonio, gastronomia y rutas locales'),
  ('ESCAPARATES', 'Concurso de Escaparates', 'competition', 'Votacion popular de comercio y escaparates'),
  ('EVENT_HUB', 'Portal de Eventos', 'events', 'Agregador de agenda cultural y eventos')
on conflict (code) do nothing;

-- 6. RLS Y POLITICAS DE SEGURIDAD
alter table templates enable row level security;
alter table campaigns enable row level security;
alter table campaign_theme enable row level security;
alter table campaign_settings enable row level security;

do 
begin
  if not exists (select 1 from pg_policies where policyname = 'Templates publicos activos son legibles por todos') then
    create policy  Templates publicos activos son legibles por todos on templates for select using (is_active = true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Campanas activas son legibles por todos') then
    create policy Campanas activas son legibles por todos on campaigns for select using (status in ('active', 'completed'));
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Temas de campanas son legibles publicamente') then
    create policy Temas de campanas son legibles publicamente on campaign_theme for select using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Ajustes de campanas son legibles publicamente') then
    create policy Ajustes de campanas son legibles publicamente on campaign_settings for select using (true);
  end if;
end ;
-- MIGRACION FASE 2: Entidades Dinamicas y Recompensas de Campana
-- Compatible 100% con produccion (Zero-Downtime, no destructiva)

-- 1. TABLA campaign_entities
create table if not exists campaign_entities (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references campaigns(id) on delete cascade,
  name text not null,
  description text,
  image_url text,
  entity_type text not null,
  category text,
  address text,
  latitude double precision,
  longitude double precision,
  metadata jsonb default '{}'::jsonb,
  active boolean default true,
  display_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_campaign_entities_campaign on campaign_entities(campaign_id);
create index if not exists idx_campaign_entities_type on campaign_entities(entity_type);

-- 2. TABLA campaign_rewards
create table if not exists campaign_rewards (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references campaigns(id) on delete cascade,
  title text not null,
  description text,
  reward_type text default 'badge',
  points_required integer default 0,
  stock integer,
  image_url text,
  metadata jsonb default '{}'::jsonb,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_campaign_rewards_campaign on campaign_rewards(campaign_id);

-- 3. RLS Y POLITICAS DE SEGURIDAD
alter table campaign_entities enable row level security;
alter table campaign_rewards enable row level security;

do 
begin
  if not exists (select 1 from pg_policies where policyname = 'Entidades activas son legibles publicamente') then
    create policy  Entidades activas son legibles publicamente on campaign_entities for select using (active = true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Recompensas activas son legibles publicamente') then
    create policy Recompensas activas son legibles publicamente on campaign_rewards for select using (is_active = true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins pueden gestionar entidades') then
    create policy Superadmins pueden gestionar entidades on campaign_entities for all to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins pueden gestionar recompensas') then
    create policy Superadmins pueden gestionar recompensas on campaign_rewards for all to authenticated using (true);
  end if;
end ;
-- MIGRACION FASE 3: Event Hub y Fuentes Externas
-- Compatible 100% con produccion (Zero-Downtime, no destructiva)

-- 1. TABLA external_event_sources
create table if not exists external_event_sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  source_type text not null,
  api_endpoint text,
  feed_url text,
  auth_config jsonb default '{}'::jsonb,
  sync_frequency_minutes integer default 360,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. TABLA hub_events (Protege la tabla preexistente 'eventos')
create table if not exists hub_events (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id) on delete set null,
  source_id uuid references external_event_sources(id) on delete set null,
  title text not null,
  description text,
  start_date timestamptz not null,
  end_date timestamptz,
  location_name text,
  address text,
  latitude double precision,
  longitude double precision,
  external_url text,
  image_url text,
  category text,
  status text default 'published',
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_hub_events_campaign on hub_events(campaign_id);
create index if not exists idx_hub_events_start on hub_events(start_date);
create index if not exists idx_hub_events_category on hub_events(category);

-- 3. TABLA event_affiliations
create table if not exists event_affiliations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references hub_events(id) on delete cascade,
  affiliate_partner text not null,
  referral_url text not null,
  commission_rate numeric(5,2) default 0.00,
  clicks_count integer default 0,
  conversions_count integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_event_affiliations_event on event_affiliations(event_id);

-- 4. TABLA event_sync_logs
create table if not exists event_sync_logs (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references external_event_sources(id) on delete cascade,
  events_synced integer default 0,
  status text not null,
  error_details text,
  executed_at timestamptz default now()
);

-- 5. RLS Y POLITICAS DE SEGURIDAD
alter table external_event_sources enable row level security;
alter table hub_events enable row level security;
alter table event_affiliations enable row level security;
alter table event_sync_logs enable row level security;

do 
begin
  if not exists (select 1 from pg_policies where policyname = 'Eventos publicados son legibles publicamente') then
    create policy  Eventos publicados son legibles publicamente on hub_events for select using (status = 'published');
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Fuentes de eventos activas son legibles publicamente') then
    create policy Fuentes de eventos activas son legibles publicamente on external_event_sources for select using (is_active = true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins tienen control total en Event Hub') then
    create policy Superadmins tienen control total en Event Hub on hub_events for all to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins gestionan fuentes y logs') then
    create policy Superadmins gestionan fuentes y logs on external_event_sources for all to authenticated using (true);
  end if;
end ;
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
-- MIGRACION FASE 6: Marketplace de Plantillas Instalables
-- Compatible 100% con produccion (Zero-Downtime, no destructiva)

-- 1. TABLA marketplace_packages
create table if not exists marketplace_packages (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references templates(id) on delete cascade,
  package_code text unique not null,
  title text not null,
  summary text,
  detailed_description text,
  author_name text default 'LokiTrono Core',
  version text default '1.0.0',
  icon_url text,
  preview_images jsonb default '[]'::jsonb,
  tags jsonb default '[]'::jsonb,
  default_theme jsonb default '{}'::jsonb,
  default_settings jsonb default '{}'::jsonb,
  sample_entities jsonb default '[]'::jsonb,
  sample_missions jsonb default '[]'::jsonb,
  is_official boolean default true,
  is_published boolean default true,
  installs_count integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_marketplace_packages_template on marketplace_packages(template_id);
create index if not exists idx_marketplace_packages_code on marketplace_packages(package_code);

-- 2. TABLA campaign_installations
create table if not exists campaign_installations (
  id uuid primary key default gen_random_uuid(),
  package_id uuid not null references marketplace_packages(id) on delete cascade,
  campaign_id uuid not null references campaigns(id) on delete cascade,
  installed_by text not null,
  installed_version text not null,
  configuration_snapshot jsonb default '{}'::jsonb,
  installed_at timestamptz default now()
);

create index if not exists idx_campaign_installations_campaign on campaign_installations(campaign_id);

-- 3. SEMILLAS DE PAQUETES INICIALES
insert into marketplace_packages (
  template_id, package_code, title, summary, author_name, tags, default_theme, default_settings
)
select 
  id,
  'PACK_RUTA_GASTRONOMICA',
  'Ruta Gastronomica y Concurso de Tapas',
  'Plantilla completa para rutas de hosteleria con votos populares, mapas de locales y misiones de degustacion.',
  'LokiTrono Platform',
  '[ gastronomia, hosteleria, comercio, turismo]'::jsonb,
  '{primary_color: #d97706, secondary_color: #78350f}'::jsonb,
  '{max_votes: 3, public_results: true, show_ranking: true}'::jsonb
from templates where code = 'TURISMO' limit 1
on conflict (package_code) do nothing;

insert into marketplace_packages (
  template_id, package_code, title, summary, author_name, tags, default_theme, default_settings
)
select 
  id,
  'PACK_PATRIMONIO_CULTURAL',
  'Gymkana de Patrimonio y Monumentos',
  'Ruta interactiva por el casco historico con audioguias, preguntas gamificadas y sellos virtuales.',
  'LokiTrono Platform',
  '[cultura, patrimonio, monumentos, educacion]'::jsonb,
  '{primary_color: #0284c7, secondary_color: #0f172a}'::jsonb,
  '{max_votes: 1, show_rewards: true, show_ranking: true}'::jsonb
from templates where code = 'TURISMO' limit 1
on conflict (package_code) do nothing;

-- 4. RLS Y POLITICAS DE SEGURIDAD
alter table marketplace_packages enable row level security;
alter table campaign_installations enable row level security;

do 
begin
  if not exists (select 1 from pg_policies where policyname = 'Paquetes publicados son legibles publicamente') then
    create policy Paquetes publicados son legibles publicamente on marketplace_packages for select using (is_published = true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins gestionan catalogo del marketplace') then
    create policy Superadmins gestionan catalogo del marketplace on marketplace_packages for all to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Superadmins gestionan instalaciones de campana') then
    create policy Superadmins gestionan instalaciones de campana on campaign_installations for all to authenticated using (true);
  end if;
end ;
