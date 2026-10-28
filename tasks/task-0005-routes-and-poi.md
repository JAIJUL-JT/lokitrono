# TASK-0005: Modulos de Rutas, Patrimonio y Puntos de Interes (Fase 5)

**Estado:** LISTA PARA IMPLEMENTACION POR OPENCODE  
**Fecha:** 2026-10-28  
**Autor:** Antigravity Architect  
**Prioridad:** Alta (Experiencia Turistica y Cultural)  
**Riesgo:** Bajo (100% Aditiva, compatible con produccion)  

---

## 1. Contexto y Objetivos

Estructurar rutas turísticas, circuitos patrimoniales, senderos y mapas de puntos de interés (POIs) interactivos. Permite a los usuarios seguir itinerarios guiados conectando entidades de la campaña (campaign_entities) y desbloqueando misiones de gamificación (event_missions).

### Restricciones Absolutas:
- **NO TOCAR:** Tablas geográficas previas (arrios, distritos, ciudades, provincias).
- **TIPO DE MIGRACION:** 100% Aditiva.
- **COMPATIBILIDAD:** Integrable con Leaflet, Mapbox o OpenStreetMap en el frontend.

---

## 2. Definicion Tecnica de Tablas Nuevas

### 2.1 Tabla 	ourist_routes
Itinerarios y recorridos turísticos, patrimoniales o comerciales.
`sql
create table if not exists tourist_routes (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id) on delete cascade,
  title text not null,
  slug text unique not null,
  description text,
  route_type text not null, -- 'patrimonio', 'gastronomica', 'naturaleza', 'comercio', 'cicloturismo'
  difficulty text default 'facil', -- 'facil', 'moderada', 'avanzada'
  estimated_duration_minutes integer,
  distance_km numeric(6,2),
  banner_url text,
  geojson_track jsonb, -- trazado opcional del recorrido en coordenadas GeoJSON
  is_active boolean default true,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_tourist_routes_campaign on tourist_routes(campaign_id);
create index if not exists idx_tourist_routes_type on tourist_routes(route_type);
`

### 2.2 Tabla oute_stops
Paradas o puntos de interés ordenados dentro de una ruta.
`sql
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
`

### 2.3 Tabla user_route_completions
Registro de rutas iniciadas y completadas por participantes.
`sql
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
`

---

## 3. Politicas de Seguridad RLS

`sql
alter table tourist_routes enable row level security;
alter table route_stops enable row level security;
alter table user_route_completions enable row level security;

create policy  Rutas activas son legibles publicamente
  on tourist_routes for select using (is_active = true);

create policy Paradas de ruta son legibles publicamente
  on route_stops for select using (true);

create policy Usuarios leen sus progresos de ruta
  on user_route_completions for select using (true);

create policy Usuarios gestionan sus progresos de ruta
  on user_route_completions for all using (true);

create policy Superadmins gestionan rutas y paradas
  on tourist_routes for all to authenticated using (true);

create policy Superadmins gestionan paradas
  on route_stops for all to authenticated using (true);
`

---

## 4. Criterios de Aceptacion para OpenCode

- [ ] Archivo de migración en migrations/20261028_05_create_routes_and_poi.sql.
- [ ] Datos de semilla para una ruta de muestra (Ruta de la Costa y Miradores).
- [ ] Zero impacto sobre tablas de geografía existentes.
- [ ] Validación mediante suite de tests.
- [ ] Informe de ejecución en eports/report-task-0005.md.
