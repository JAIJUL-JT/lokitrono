# TASK-0002: Sistema de Entidades Dinamicas y Modulos (Fase 2)

**Estado:** LISTA PARA IMPLEMENTACION POR OPENCODE  
**Fecha:** 2026-10-28  
**Autor:** Antigravity Architect  
**Prioridad:** Alta (Modularidad de Contenidos)  
**Riesgo:** Bajo (100% Aditiva, compatible con produccion)  

---

## 1. Contexto y Objetivos

Desacoplar los elementos participantes (barrios, comercios, puntos de interes turistico, escaparates, museos o patrimonio) para que cualquier campana pueda definir y gestionar sus propias entidades sin alterar la tabla arrios existente.

### Restricciones Absolutas:
- **NO TOCAR:** La tabla existente arrios, locales_promocion, casas ni juegos.
- **TIPO DE MIGRACION:** 100% Aditiva.
- **POLITICAS RLS:** Habilitadas con lectura publica para entidades activas.

---

## 2. Definicion Tecnica de Tablas Nuevas

### 2.1 Tabla campaign_entities
Entidades asociadas a una campana concreta (comercios, monumentos, participantes, locales, etc.).
`sql
create table if not exists campaign_entities (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references campaigns(id) on delete cascade,
  name text not null,
  description text,
  image_url text,
  entity_type text not null, -- 'barrio', 'comercio', 'patrimonio', 'museo', 'escaparate', 'punto_interes'
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
`

### 2.2 Tabla campaign_rewards
Recompensas y premios especificos por campana (sorteos, descuentos de comercio, insignias).
`sql
create table if not exists campaign_rewards (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references campaigns(id) on delete cascade,
  title text not null,
  description text,
  reward_type text default 'badge', -- 'badge', 'discount', 'raffle_ticket', 'merchandise'
  points_required integer default 0,
  stock integer,
  image_url text,
  metadata jsonb default '{}'::jsonb,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_campaign_rewards_campaign on campaign_rewards(campaign_id);
`

---

## 3. Politicas de Seguridad RLS

`sql
alter table campaign_entities enable row level security;
alter table campaign_rewards enable row level security;

create policy  Entidades activas son legibles publicamente
  on campaign_entities for select using (active = true);

create policy Recompensas activas son legibles publicamente
  on campaign_rewards for select using (is_active = true);

create policy Superadmins pueden gestionar entidades
  on campaign_entities for all to authenticated using (true);

create policy Superadmins pueden gestionar recompensas
  on campaign_rewards for all to authenticated using (true);
`

---

## 4. Criterios de Aceptacion para OpenCode

- [ ] Archivo de migracion en migrations/20261028_02_create_campaign_entities.sql.
- [ ] Creacion de entidades de prueba para Turismo y Barrios.
- [ ] Cero interferencias con las 26 tablas activas de produccion.
- [ ] Validacion automatizada en tests.
- [ ] Documentacion en eports/report-task-0002.md.
