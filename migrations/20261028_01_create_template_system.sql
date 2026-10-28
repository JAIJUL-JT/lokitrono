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
