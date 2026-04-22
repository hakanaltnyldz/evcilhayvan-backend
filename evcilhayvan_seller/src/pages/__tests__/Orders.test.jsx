import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import Orders from '../Orders.jsx';
import api from '../../api';

vi.mock('../../api', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
  },
}));

vi.mock('react-hot-toast', () => ({
  default: {
    success: vi.fn(),
    error: vi.fn(),
  },
}));

describe('Seller Orders', () => {
  it('filters orders by search query', async () => {
    api.get.mockResolvedValueOnce({
      data: {
        orders: [
          {
            _id: 'order-1',
            user: { name: 'Ayse', email: 'ayse@test.com' },
            totalAmount: 250,
            status: 'pending',
            createdAt: '2026-04-22T10:00:00.000Z',
            items: [],
          },
          {
            _id: 'order-2',
            user: { name: 'Mehmet', email: 'mehmet@test.com' },
            totalAmount: 400,
            status: 'delivered',
            createdAt: '2026-04-21T10:00:00.000Z',
            items: [],
          },
        ],
      },
    });

    render(<Orders />);

    await waitFor(() => {
      expect(api.get).toHaveBeenCalledWith('/seller/orders?limit=100');
    });

    expect(await screen.findByText('Ayse')).toBeInTheDocument();
    expect(screen.getByText('Mehmet')).toBeInTheDocument();

    const searchInput = screen.getByRole('textbox');
    fireEvent.change(searchInput, { target: { value: 'Mehmet' } });

    expect(screen.getByText('Mehmet')).toBeInTheDocument();
    expect(screen.queryByText('Ayse')).not.toBeInTheDocument();
  }, 10000);
});
