-- supabase/migrations/20231028061000_multi_tenant.sql
-- Multi‑tenant (organization) schema

CREATE TABLE IF NOT EXISTS public.organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,                -- e.g. "bilbao", "barakaldo"
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.organization_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.authorized_users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'viewer',      -- viewer, editor, admin, master
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (organization_id, user_id)
);

-- Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_org_users_org ON public.organization_users(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_users_user ON public.organization_users(user_id);
