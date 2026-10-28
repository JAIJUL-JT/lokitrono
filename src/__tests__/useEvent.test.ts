import { createEvent } from '../../hooks/useEvent';
import { supabase } from '../../utils/supabaseClient';

jest.mock('../../utils/supabaseClient', () => ({
  supabase: {
    from: jest.fn(() => ({
      insert: jest.fn(() => ({
        select: jest.fn(),
      })),
    })),
  },
}));

describe('createEvent', () => {
  it('creates a new event and returns it', async () => {
    const mockInsert = jest.fn().mockResolvedValue({
      data: [{ id: 'e1', title: 'My Event' }],
      error: null,
    });
    (supabase.from as jest.Mock).mockReturnValue({ insert: mockInsert });

    const payload = {
      title: 'My Event',
      description: '',
      start_date: new Date().toISOString(),
      status: 'published',
      campaign_id: 'c1',
    };
    const result = await createEvent(payload);
    expect(mockInsert).toHaveBeenCalledWith([payload]);
    expect(result).toEqual({ id: 'e1', title: 'My Event' });
  });
});
