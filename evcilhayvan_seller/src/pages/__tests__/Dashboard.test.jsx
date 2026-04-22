import { render, screen, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import Dashboard from '../Dashboard.jsx';
import api from '../../api';

vi.mock('../../api', () => ({
  default: {
    get: vi.fn(),
  },
}));

describe('Seller Dashboard', () => {
  it('loads seller stats and recent orders', async () => {
    localStorage.setItem('seller_user', JSON.stringify({ name: 'Hakan Yildiz' }));

    api.get.mockImplementation((url) => {
      if (url === '/seller/stats') {
        return Promise.resolve({
          data: { totalProducts: 8, activeProducts: 6, outOfStock: 2, totalValue: 4500 },
        });
      }
      if (url === '/seller/orders/stats') {
        return Promise.resolve({
          data: { pending: 2, revenueThisMonth: 1200 },
        });
      }
      if (url === '/seller/orders/chart') {
        return Promise.resolve({ data: { chart: [] } });
      }
      if (url === '/seller/orders?limit=5') {
        return Promise.resolve({
          data: {
            orders: [
              {
                _id: 'order-1',
                user: { name: 'Ayse' },
                createdAt: '2026-04-22T10:00:00.000Z',
                status: 'pending',
                totalAmount: 250,
              },
            ],
          },
        });
      }

      return Promise.reject(new Error(`Unhandled URL: ${url}`));
    });

    render(<Dashboard />);

    expect(await screen.findByText('Ayse')).toBeInTheDocument();

    await waitFor(() => {
      expect(api.get).toHaveBeenCalledWith('/seller/stats');
      expect(api.get).toHaveBeenCalledWith('/seller/orders/stats');
      expect(api.get).toHaveBeenCalledWith('/seller/orders/chart');
      expect(api.get).toHaveBeenCalledWith('/seller/orders?limit=5');
    });
  });
});
