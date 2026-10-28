import { supabase } from '../utils/supabaseClient';

/**
 * Creates a new event (hub_event) in Supabase.
 * @param data Object containing the event fields.
 */
export async function createEvent(data: {
  campaign_id: string;
  title: string;
  description?: string;
  start_date: string; // ISO string
  end_date?: string;
  location_name?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  category?: string;
  status?: string;
}) {
  const { data: event, error } = await supabase
    .from('hub_events')
    .insert([data])
    .select();
  if (error) {
    console.error('Error creating event:', error);
    throw error;
  }
  return event[0];
}
