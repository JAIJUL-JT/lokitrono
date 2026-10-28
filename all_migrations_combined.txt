-- ==============================================================================
-- LOKITRONO PLATFORM - MIGRACION COMPLETA ADITIVA (FASES 1 A 6)
-- Compatible 100% con PostgreSQL / Supabase
-- ==============================================================================

-- 1. TABLA templates
CREATE TABLE IF NOT EXISTS public.templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  description text,
  category text,
  default_config jsonb DEFAULT '{}'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_templates_code ON public.templates(code);

-- 2. TABLA campaigns
CREATE TABLE IF NOT EXISTS public.campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id uuid NOT NULL REFERENCES public.templates(id),
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  description text,
  status text DEFAULT 'draft',
  starts_at timestamptz,
  ends_at timestamptz,
  organization_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_campaigns_template ON public.campaigns(template_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_code ON public.campaigns(code);

-- 3. TABLA campaign_theme (Marca Blanca)
CREATE TABLE IF NOT EXISTS public.campaign_theme (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid UNIQUE NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  logo_url text,
  banner_url text,
  primary_color text DEFAULT '#0284c7',
  secondary_color text DEFAULT '#0f172a',
  background_color text DEFAULT '#f8fafc',
  custom_css text,
  updated_at timestamptz DEFAULT now()
);

-- 4. TABLA campaign_settings
CREATE TABLE IF NOT EXISTS public.campaign_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid UNIQUE NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  login_required boolean DEFAULT false,
  show_ranking boolean DEFAULT true,
  show_rewards boolean DEFAULT true,
  show_history boolean DEFAULT true,
  public_results boolean DEFAULT true,
  max_votes integer DEFAULT 1,
  settings jsonb DEFAULT '{}'::jsonb,
  updated_at timestamptz DEFAULT now()
);

-- 5. TABLA campaign_entities (Entidades, Comercios, Monumentos)
CREATE TABLE IF NOT EXISTS public.campaign_entities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  image_url text,
  entity_type text NOT NULL,
  category text,
  address text,
  latitude double precision,
  longitude double precision,
  metadata jsonb DEFAULT '{}'::jsonb,
  active boolean DEFAULT true,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_campaign_entities_campaign ON public.campaign_entities(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_entities_type ON public.campaign_entities(entity_type);

-- 6. TABLA campaign_rewards
CREATE TABLE IF NOT EXISTS public.campaign_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  reward_type text DEFAULT 'badge',
  points_required integer DEFAULT 0,
  stock integer,
  image_url text,
  metadata jsonb DEFAULT '{}'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_campaign_rewards_campaign ON public.campaign_rewards(campaign_id);

-- 7. TABLA external_event_sources
CREATE TABLE IF NOT EXISTS public.external_event_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  source_type text NOT NULL,
  api_endpoint text,
  feed_url text,
  auth_config jsonb DEFAULT '{}'::jsonb,
  sync_frequency_minutes integer DEFAULT 360,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 8. TABLA hub_events (Event Hub independiente)
CREATE TABLE IF NOT EXISTS public.hub_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid REFERENCES public.campaigns(id) ON DELETE SET NULL,
  source_id uuid REFERENCES public.external_event_sources(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  start_date timestamptz NOT NULL,
  end_date timestamptz,
  location_name text,
  address text,
  latitude double precision,
  longitude double precision,
  external_url text,
  image_url text,
  category text,
  status text DEFAULT 'published',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_hub_events_campaign ON public.hub_events(campaign_id);
CREATE INDEX IF NOT EXISTS idx_hub_events_start ON public.hub_events(start_date);
CREATE INDEX IF NOT EXISTS idx_hub_events_category ON public.hub_events(category);

-- 9. TABLA event_affiliations
CREATE TABLE IF NOT EXISTS public.event_affiliations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.hub_events(id) ON DELETE CASCADE,
  affiliate_partner text NOT NULL,
  referral_url text NOT NULL,
  commission_rate numeric(5,2) DEFAULT 0.00,
  clicks_count integer DEFAULT 0,
  conversions_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_event_affiliations_event ON public.event_affiliations(event_id);

-- 10. TABLA event_sync_logs
CREATE TABLE IF NOT EXISTS public.event_sync_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id uuid NOT NULL REFERENCES public.external_event_sources(id) ON DELETE CASCADE,
  events_synced integer DEFAULT 0,
  status text NOT NULL,
  error_details text,
  executed_at timestamptz DEFAULT now()
);

-- 11. TABLA event_missions (Gamificación)
CREATE TABLE IF NOT EXISTS public.event_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid REFERENCES public.campaigns(id) ON DELETE CASCADE,
  event_id uuid REFERENCES public.hub_events(id) ON DELETE CASCADE,
  entity_id uuid REFERENCES public.campaign_entities(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  mission_type text NOT NULL,
  points_reward integer DEFAULT 50,
  validation_method text DEFAULT 'qr_code',
  validation_payload text,
  latitude double precision,
  longitude double precision,
  radius_meters integer DEFAULT 100,
  is_active boolean DEFAULT true,
  starts_at timestamptz,
  ends_at timestamptz,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_event_missions_campaign ON public.event_missions(campaign_id);
CREATE INDEX IF NOT EXISTS idx_event_missions_event ON public.event_missions(event_id);

-- 12. TABLA user_mission_progress
CREATE TABLE IF NOT EXISTS public.user_mission_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mission_id uuid NOT NULL REFERENCES public.event_missions(id) ON DELETE CASCADE,
  user_identifier text NOT NULL,
  status text DEFAULT 'in_progress',
  points_awarded integer DEFAULT 0,
  completed_at timestamptz,
  claimed_at timestamptz,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (mission_id, user_identifier)
);
CREATE INDEX IF NOT EXISTS idx_user_mission_progress_user ON public.user_mission_progress(user_identifier);
CREATE INDEX IF NOT EXISTS idx_user_mission_progress_mission ON public.user_mission_progress(mission_id);

-- 13. TABLA mission_checkins
CREATE TABLE IF NOT EXISTS public.mission_checkins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mission_id uuid NOT NULL REFERENCES public.event_missions(id) ON DELETE CASCADE,
  user_identifier text NOT NULL,
  verification_method text NOT NULL,
  submitted_payload text,
  latitude double precision,
  longitude double precision,
  verified boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mission_checkins_user ON public.mission_checkins(user_identifier);

-- 14. TABLA tourist_routes (Rutas Turísticas y Patrimoniales)
CREATE TABLE IF NOT EXISTS public.tourist_routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid REFERENCES public.campaigns(id) ON DELETE CASCADE,
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text,
  route_type text NOT NULL,
  difficulty text DEFAULT 'facil',
  estimated_duration_minutes integer,
  distance_km numeric(6,2),
  banner_url text,
  geojson_track jsonb,
  is_active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tourist_routes_campaign ON public.tourist_routes(campaign_id);
CREATE INDEX IF NOT EXISTS idx_tourist_routes_type ON public.tourist_routes(route_type);

-- 15. TABLA route_stops
CREATE TABLE IF NOT EXISTS public.route_stops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL REFERENCES public.tourist_routes(id) ON DELETE CASCADE,
  entity_id uuid REFERENCES public.campaign_entities(id) ON DELETE SET NULL,
  stop_order integer NOT NULL,
  title text NOT NULL,
  description text,
  image_url text,
  audio_guide_url text,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  estimated_stay_minutes integer DEFAULT 15,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  UNIQUE (route_id, stop_order)
);
CREATE INDEX IF NOT EXISTS idx_route_stops_route ON public.route_stops(route_id);

-- 16. TABLA user_route_completions
CREATE TABLE IF NOT EXISTS public.user_route_completions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL REFERENCES public.tourist_routes(id) ON DELETE CASCADE,
  user_identifier text NOT NULL,
  stops_completed integer DEFAULT 0,
  total_stops integer NOT NULL,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (route_id, user_identifier)
);
CREATE INDEX IF NOT EXISTS idx_user_route_completions_user ON public.user_route_completions(user_identifier);

-- 17. TABLA marketplace_packages
CREATE TABLE IF NOT EXISTS public.marketplace_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id uuid NOT NULL REFERENCES public.templates(id) ON DELETE CASCADE,
  package_code text UNIQUE NOT NULL,
  title text NOT NULL,
  summary text,
  detailed_description text,
  author_name text DEFAULT 'LokiTrono Core',
  version text DEFAULT '1.0.0',
  icon_url text,
  preview_images jsonb DEFAULT '[]'::jsonb,
  tags jsonb DEFAULT '[]'::jsonb,
  default_theme jsonb DEFAULT '{}'::jsonb,
  default_settings jsonb DEFAULT '{}'::jsonb,
  sample_entities jsonb DEFAULT '[]'::jsonb,
  sample_missions jsonb DEFAULT '[]'::jsonb,
  is_official boolean DEFAULT true,
  is_published boolean DEFAULT true,
  installs_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_marketplace_packages_template ON public.marketplace_packages(template_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_packages_code ON public.marketplace_packages(package_code);

-- 18. TABLA campaign_installations
CREATE TABLE IF NOT EXISTS public.campaign_installations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  package_id uuid NOT NULL REFERENCES public.marketplace_packages(id) ON DELETE CASCADE,
  campaign_id uuid NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  installed_by text NOT NULL,
  installed_version text NOT NULL,
  configuration_snapshot jsonb DEFAULT '{}'::jsonb,
  installed_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_campaign_installations_campaign ON public.campaign_installations(campaign_id);

-- 19. SEMILLAS DE DATOS BASE
INSERT INTO public.templates (code, name, category, description)
VALUES
  ('BARRIOS', 'LokiTrono Barrios', 'competition', 'Competicion de barrios y gamificacion'),
  ('TURISMO', 'Portal Turismo y Rutas', 'tourism', 'Guia de patrimonio y rutas locales'),
  ('ESCAPARATES', 'Concurso de Escaparates', 'competition', 'Votacion popular de comercios'),
  ('EVENT_HUB', 'Portal de Eventos', 'events', 'Agregador de agenda cultural')
ON CONFLICT (code) DO NOTHING;

-- 20. HABILITAR ROW LEVEL SECURITY (RLS)
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_theme ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.external_event_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hub_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_affiliations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_mission_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mission_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tourist_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_route_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_installations ENABLE ROW LEVEL SECURITY;

-- 21. POLÍTICAS DE LECTURA PÚBLICA (IDEMPOTENTES)
DROP POLICY IF EXISTS "p_templates_read" ON public.templates;
CREATE POLICY "p_templates_read" ON public.templates FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "p_campaigns_read" ON public.campaigns;
CREATE POLICY "p_campaigns_read" ON public.campaigns FOR SELECT USING (status in ('active', 'completed', 'draft'));

DROP POLICY IF EXISTS "p_campaign_theme_read" ON public.campaign_theme;
CREATE POLICY "p_campaign_theme_read" ON public.campaign_theme FOR SELECT USING (true);

DROP POLICY IF EXISTS "p_campaign_settings_read" ON public.campaign_settings;
CREATE POLICY "p_campaign_settings_read" ON public.campaign_settings FOR SELECT USING (true);

DROP POLICY IF EXISTS "p_campaign_entities_read" ON public.campaign_entities;
CREATE POLICY "p_campaign_entities_read" ON public.campaign_entities FOR SELECT USING (active = true);

DROP POLICY IF EXISTS "p_campaign_rewards_read" ON public.campaign_rewards;
CREATE POLICY "p_campaign_rewards_read" ON public.campaign_rewards FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "p_external_sources_read" ON public.external_event_sources;
CREATE POLICY "p_external_sources_read" ON public.external_event_sources FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "p_hub_events_read" ON public.hub_events;
CREATE POLICY "p_hub_events_read" ON public.hub_events FOR SELECT USING (status = 'published');

DROP POLICY IF EXISTS "p_event_missions_read" ON public.event_missions;
CREATE POLICY "p_event_missions_read" ON public.event_missions FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "p_user_progress_read" ON public.user_mission_progress;
CREATE POLICY "p_user_progress_read" ON public.user_mission_progress FOR SELECT USING (true);

DROP POLICY IF EXISTS "p_user_progress_insert" ON public.user_mission_progress;
CREATE POLICY "p_user_progress_insert" ON public.user_mission_progress FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "p_mission_checkins_insert" ON public.mission_checkins;
CREATE POLICY "p_mission_checkins_insert" ON public.mission_checkins FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "p_tourist_routes_read" ON public.tourist_routes;
CREATE POLICY "p_tourist_routes_read" ON public.tourist_routes FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "p_route_stops_read" ON public.route_stops;
CREATE POLICY "p_route_stops_read" ON public.route_stops FOR SELECT USING (true);

DROP POLICY IF EXISTS "p_user_routes_read" ON public.user_route_completions;
CREATE POLICY "p_user_routes_read" ON public.user_route_completions FOR ALL USING (true);

DROP POLICY IF EXISTS "p_marketplace_read" ON public.marketplace_packages;
CREATE POLICY "p_marketplace_read" ON public.marketplace_packages FOR SELECT USING (is_published = true);
