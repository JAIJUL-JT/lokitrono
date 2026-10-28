import { supabase } from '../utils/supabaseClient';

/**
 * Creates a new campaign in Supabase.
 * @param data Object with the campaign fields – see the API guide.
 * @returns The newly created campaign record.
 */
export async function createCampaign(data: {
  template_id: string;
  code: string;
  name: string;
  description?: string;
  status?: string;
  starts_at?: string;
  ends_at?: string;
  organization_name?: string;
}) {
  const { data: campaign, error } = await supabase
    .from('campaigns')
    .insert([data])
    .select();
  if (error) {
    console.error('Error creating campaign:', error);
    throw error;
  }
  return campaign[0];
}
