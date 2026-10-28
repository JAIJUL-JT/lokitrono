# TASK-0001: Sistema de Plantillas y Fundamentos de Campaña (Fase 1)

**Estado:** LISTA PARA IMPLEMENTACIÓN POR OPENCODE  
**Fecha:** 2026-10-28  
**Autor:** Antigravity Architect  
**Prioridad:** Alta (Fundacional)  
**Riesgo:** Bajo (Migración puramente aditiva / zero-downtime)  

---

## 1. Contexto y Objetivos

Evolucionar la base de datos de LokiTrono para permitir múltiples temáticas (Barrios, Turismo, Escaparates, Comercio, Eventos) mediante un motor desacoplado sin alterar ninguna tabla existente ni romper el sistema de votación actual.

### Restricciones Absolutas:
- **NO TOCAR:** votos, barrios, juegos, authorized_users, clasificacion_barrios ni ninguna tabla existente.
- **TIPO DE MIGRACIÓN:** 100% Aditiva.
- **POLÍTICAS RLS:** Obligatorias en todas las tablas nuevas.

---

## 2. Definición Técnica de Tablas Nuevas

### 2.1 Tabla templates
Almacena los tipos de aplicación disponibles en la plataforma.
`sql
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
`

### 2.2 Tabla campaigns
Instancias concretas de una plantilla.
`sql
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
`

### 2.3 Tabla campaign_theme (Marca Blanca)
Personalización visual por campaña.
`sql
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
`

### 2.4 Tabla campaign_settings
Reglas de negocio por campaña.
`sql
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
`

---

## 3. Semillas de Datos Iniciales (Seeds)

`sql
insert into templates (code, name, category, description)
values
  ('BARRIOS', 'LokiTrono Barrios', 'competition', 'Competición tradicional de barrios y gamificación'),
  ('TURISMO', 'Portal Turismo y Rutas', 'tourism', 'Guía de experiencias, patrimonio, gastronomía y rutas locales'),
  ('ESCAPARATES', 'Concurso de Escaparates', 'competition', 'Votación popular de comercio y escaparates'),
  ('EVENT_HUB', 'Portal de Eventos', 'events', 'Agregador de agenda cultural y eventos')
on conflict (code) do nothing;
`

---

## 4. Políticas de Seguridad RLS (Supabase)

`sql
alter table templates enable row level security;
alter table campaigns enable row level security;
alter table campaign_theme enable row level security;
alter table campaign_settings enable row level security;

create policy  Templates publicos activos son legibles por todos 
  on templates for select using (is_active = true);

create policy Campanas activas son legibles por todos 
  on campaigns for select using (status in ('active', 'completed'));

create policy Temas de campanas son legibles publicamente 
  on campaign_theme for select using (true);

create policy Ajustes de campanas son legibles publicamente 
  on campaign_settings for select using (true);
`

---

## 5. Criterios de Aceptación para OpenCode

- [ ] Archivo de migración ubicado en migrations/20261028_01_create_template_system.sql
- [ ] La migración se ejecuta sin errores en Supabase.
- [ ] Ninguna tabla previa sufre alteraciones.
- [ ] Los tests automatizados confirman la disponibilidad de las nuevas entidades.
- [ ] Informe de ejecución generado en reports/report-task-0001.md.
