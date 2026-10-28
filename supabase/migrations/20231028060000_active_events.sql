-- supabase/migrations/20231028060000_active_events.sql
-- Migration: create view and RPC for active events

CREATE OR REPLACE VIEW public.view_active_events AS
SELECT e.*, c.name AS campaign_name
FROM hub_events e
JOIN campaigns c ON e.campaign_id = c.id
WHERE e.status = 'published'
  AND (e.start_date >= now() AT TIME ZONE 'UTC')
  AND (e.end_date IS NULL OR e.end_date >= now() AT TIME ZONE 'UTC');

-- Index on start_date for fast range queries
CREATE INDEX IF NOT EXISTS idx_view_active_events_start ON hub_events(start_date);

CREATE OR REPLACE FUNCTION public.search_events(
    p_date_filter text,   -- 'today' | 'week' | 'custom'
    p_start date DEFAULT NULL,
    p_end   date DEFAULT NULL,
    p_city  text DEFAULT NULL
) RETURNS TABLE (
    id uuid,
    title text,
    description text,
    start_date timestamptz,
    end_date timestamptz,
    location_name text,
    address text,
    latitude double precision,
    longitude double precision,
    category text,
    campaign_name text
) LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT e.id, e.title, e.description, e.start_date, e.end_date,
         e.location_name, e.address, e.latitude, e.longitude,
         e.category, c.name AS campaign_name
  FROM hub_events e
  JOIN campaigns c ON e.campaign_id = c.id
  WHERE e.status = 'published'
    AND (
      CASE p_date_filter
        WHEN 'today' THEN e.start_date::date = CURRENT_DATE
        WHEN 'week'  THEN e.start_date::date BETWEEN CURRENT_DATE AND (CURRENT_DATE + interval '6 days')
        WHEN 'custom' THEN e.start_date >= p_start AND e.start_date <= p_end
        ELSE true
      END
    )
    AND (
      p_city IS NULL OR LOWER(e.location_name) LIKE '%' || LOWER(p_city) || '%'
      OR LOWER(e.address) LIKE '%' || LOWER(p_city) || '%'
    );
$$;
