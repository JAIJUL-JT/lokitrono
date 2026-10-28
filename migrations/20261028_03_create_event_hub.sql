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
