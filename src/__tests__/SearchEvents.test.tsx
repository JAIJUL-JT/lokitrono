import { render, screen, waitFor } from '@testing-library/react';
import SearchEvents from '../../components/SearchEvents';
import { supabase } from '../../utils/supabaseClient';

jest.mock('../../utils/supabaseClient', () => ({
  supabase: {
    rpc: jest.fn(),
  },
}));

const mockResults = [
  {
    id: 'ev1',
    title: 'Event 1',
    location_name: 'Bilbao',
    start_date: '2023-10-01T10:00:00Z',
  },
];

describe('SearchEvents component', () => {
  beforeEach(() => {
    (supabase.rpc as jest.Mock).mockResolvedValue({
      data: mockResults,
      error: null,
    });
  });

  it('renders and shows results after search', async () => {
    render(<SearchEvents />);
    // Assuming component has a button labeled "Search"
    const btn = screen.getByRole('button', { name: /search/i });
    btn.click();
    await waitFor(() => {
      expect(screen.getByText('Event 1')).toBeInTheDocument();
      expect(screen.getByText('Bilbao')).toBeInTheDocument();
    });
  });

  it('displays error on RPC failure', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValue({
      data: null,
      error: new Error('RPC failed'),
    });
    render(<SearchEvents />);
    const btn = screen.getByRole('button', { name: /search/i });
    btn.click();
    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });
});
