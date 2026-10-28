CREATE OR REPLACE VIEW public.view_active_events AS
SELECT e.*, c.name AS campaign_name
FROM hub_events e
JOIN campaigns c ON e.campaign_id = c.id
WHERE e.status = 'published'
  AND (e.start_date >= now() AT TIME ZONE 'UTC')
  AND (e.end_date IS NULL OR e.end_date >= now() AT TIME ZONE 'UTC');

CREATE INDEX IF NOT EXISTS idx_view_active_events_start ON hub_events(start_date);
