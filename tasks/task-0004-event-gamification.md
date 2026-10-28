# TASK-0004: Gamificacion de Eventos y Misiones (Fase 4)

**Estado:** LISTA PARA IMPLEMENTACION POR OPENCODE  
**Fecha:** 2026-10-28  
**Autor:** Antigravity Architect  
**Prioridad:** Alta (Engagement y Participacion)  
**Riesgo:** Bajo (100% Aditiva, compatible con produccion)  

---

## 1. Contexto y Objetivos

Integrar la mecanica de misiones y recompensas a los eventos del **Event Hub** y rutas de turismo (asistir, visitar un punto patrimonial, comprar en comercio adherido o participar en actividades locales), aprovechando el motor de usuarios y sesiones actual sin modificar las tablas juegos, piezas_puzzle o clasificacion_barrios.

### Restricciones Absolutas:
- **NO TOCAR:** Las tablas juegos, estado_juego, otos, ni piezas_puzzle.
- **TIPO DE MIGRACION:** 100% Aditiva.
- **DESACOPLAMIENTO:** Nuevas tablas (event_missions, user_mission_progress, mission_checkins).

---

## 2. Definicion Tecnica de Tablas Nuevas

### 2.1 Tabla event_missions
Misiones configurables por campaña o asociadas a eventos del Event Hub.
`sql
create table if not exists event_missions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id) on delete cascade,
  event_id uuid references hub_events(id) on delete cascade,
  entity_id uuid references campaign_entities(id) on delete cascade,
  title text not null,
  description text,
  mission_type text not null, -- 'asistir_evento', 'visitar_lugar', 'compra_comercio', 'votar', 'escanear_qr'
  points_reward integer default 50,
  validation_method text default 'qr_code', -- 'qr_code', 'gps_geofence', 'pin_code', 'manual_check'
  validation_payload text, -- codigo PIN secreto o hash QR esperado
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
`

### 2.2 Tabla user_mission_progress
Progreso del usuario en las misiones (compatible con autenticación existente o anónima por token).
`sql
create table if not exists user_mission_progress (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references event_missions(id) on delete cascade,
  user_identifier text not null, -- UUID de usuario autenticado o token anonimo de sesion
  status text default 'in_progress', -- 'in_progress', 'completed', 'claimed'
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
`

### 2.3 Tabla mission_checkins
Registro de validaciones de asistencia o consumo (check-in por GPS, escaneo de QR o PIN).
`sql
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
`

---

## 3. Politicas de Seguridad RLS

`sql
alter table event_missions enable row level security;
alter table user_mission_progress enable row level security;
alter table mission_checkins enable row level security;

create policy  Misiones activas son legibles publicamente
  on event_missions for select using (is_active = true);

create policy Usuarios leen su propio progreso
  on user_mission_progress for select using (true);

create policy Usuarios registran su progreso
  on user_mission_progress for insert with check (true);

create policy Usuarios registran checkins
  on mission_checkins for insert with check (true);

create policy Superadmins gestionan misiones
  on event_missions for all to authenticated using (true);
`

---

## 4. Criterios de Aceptacion para OpenCode

- [ ] Archivo de migración en migrations/20261028_04_create_event_gamification.sql.
- [ ] No alterar las tablas de juegos ni clasificaciones de la competición actual.
- [ ] Validación mediante suite de tests.
- [ ] Informe de ejecución en eports/report-task-0004.md.
