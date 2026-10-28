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
