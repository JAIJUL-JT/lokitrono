import { createCampaign } from '../../hooks/useCampaign';
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

describe('createCampaign', () => {
  it('should insert campaign and return the first record', async () => {
    const mockInsert = jest.fn().mockResolvedValue({
      data: [{ id: '123', name: 'Test' }],
      error: null,
    });
    (supabase.from as jest.Mock).mockReturnValue({ insert: mockInsert });

    const data = {
      template_id: 'tmpl_1',
      code: 'C001',
      name: 'Demo Campaign',
    };
    const result = await createCampaign(data);
    expect(mockInsert).toHaveBeenCalledWith([data]);
    expect(result).toEqual({ id: '123', name: 'Test' });
  });

  it('should throw on error', async () => {
    const mockInsert = jest.fn().mockResolvedValue({
      data: null,
      error: new Error('Insert failed'),
    });
    (supabase.from as jest.Mock).mockReturnValue({ insert: mockInsert });

    await expect(
      createCampaign({ template_id: '', code: '', name: '' })
    ).rejects.toThrow('Insert failed');
  });
});
