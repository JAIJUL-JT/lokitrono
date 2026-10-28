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
