# TASK-0003: Event Hub y Agregacion de Eventos Externos (Fase 3)

**Estado:** LISTA PARA IMPLEMENTACION POR OPENCODE  
**Fecha:** 2026-10-28  
**Autor:** Antigravity Architect  
**Prioridad:** Alta (Conectividad e Integraciones)  
**Riesgo:** Bajo (100% Aditiva, compatible con produccion)  

---

## 1. Contexto y Objetivos

Implementar el módulo **Event Hub** para permitir la agregación y publicación de agendas culturales, eventos municipales, ferias de comercio y ocio local, admitiendo múltiples orígenes externos sin duplicar servicios ni alterar la tabla de eventos de la competición actual.

### Restricciones Absolutas:
- **NO TOCAR:** La tabla existente eventos ni otos_evento utilizadas por el sistema actual de LokiTrono.
- **TIPO DE MIGRACION:** 100% Aditiva.
- **DESACOPLAMIENTO:** Nuevas tablas independientes con prefijo o namespace claro (external_event_sources, hub_events, event_affiliations, event_sync_logs).

---

## 2. Definicion Tecnica de Tablas Nuevas

### 2.1 Tabla external_event_sources
Catálogo de fuentes externas que alimentan la agenda.
`sql
create table if not exists external_event_sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  source_type text not null, -- 'propio', 'municipal', 'asociado', 'afiliado', 'externo_rss', 'externo_api'
  api_endpoint text,
  feed_url text,
  auth_config jsonb default '{}'::jsonb,
  sync_frequency_minutes integer default 360,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
`

### 2.2 Tabla hub_events
Eventos agregados de las distintas fuentes vinculables a campanas.
`sql
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
  category text, -- 'musica', 'gastronomia', 'infantil', 'feria', 'cultural', 'deporte'
  status text default 'published', -- 'draft', 'published', 'cancelled'
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_hub_events_campaign on hub_events(campaign_id);
create index if not exists idx_hub_events_start on hub_events(start_date);
create index if not exists idx_hub_events_category on hub_events(category);
`

### 2.3 Tabla event_affiliations
Gestión de afiliaciones y conversiones (venta de entradas, enlaces patrocinados o convenios municipales).
`sql
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
`

### 2.4 Tabla event_sync_logs
Trazabilidad y registro de las ejecuciones de sincronización.
`sql
create table if not exists event_sync_logs (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references external_event_sources(id) on delete cascade,
  events_synced integer default 0,
  status text not null, -- 'success', 'warning', 'error'
  error_details text,
  executed_at timestamptz default now()
);
`

---

## 3. Politicas de Seguridad RLS

`sql
alter table external_event_sources enable row level security;
alter table hub_events enable row level security;
alter table event_affiliations enable row level security;
alter table event_sync_logs enable row level security;

create policy  Eventos publicados son legibles publicamente
  on hub_events for select using (status = 'published');

create policy Fuentes de eventos activas son legibles publicamente
  on external_event_sources for select using (is_active = true);

create policy Superadmins tienen control total en Event Hub
  on hub_events for all to authenticated using (true);

create policy Superadmins gestionan fuentes y logs
  on external_event_sources for all to authenticated using (true);
`

---

## 4. Criterios de Aceptacion para OpenCode

- [ ] Archivo de migracion en migrations/20261028_03_create_event_hub.sql.
- [ ] No colisionar con la tabla previa eventos de la base de datos de competicion.
- [ ] Validacion de tests automatizados.
- [ ] Informe de ejecucion en eports/report-task-0003.md.
