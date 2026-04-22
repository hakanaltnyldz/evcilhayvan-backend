import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { vi } from 'vitest'
import ModerationQueue from '../ModerationQueue.jsx'
import api from '../../api.js'
import toast from 'react-hot-toast'

vi.mock('../../api.js', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
    defaults: { baseURL: 'http://localhost:3000/api' },
  },
}))

vi.mock('react-hot-toast', () => ({
  default: {
    success: vi.fn(),
    error: vi.fn(),
  },
}))

describe('ModerationQueue', () => {
  it('loads moderation items and applies a moderation action', async () => {
    api.get.mockResolvedValue({
      data: {
        items: [
          {
            queueId: 'support:ticket-1',
            source: 'support',
            entityId: 'ticket-1',
            createdAt: '2026-04-22T09:00:00.000Z',
            status: 'reviewing',
            priority: 'high',
            badge: 'Inceleniyor',
            title: 'Support ticket',
            subtitle: 'Sikayet eden: Tester',
            excerpt: 'Icerik inceleme talebi',
            metrics: [{ label: 'Durum', value: 'Inceleniyor' }],
            actions: ['closed'],
            media: null,
          },
        ],
        total: 1,
        summary: {
          totalOpenItems: 1,
          openReports: 0,
          openSupportTickets: 1,
          hiddenPosts: 0,
          recentCareReports: 0,
        },
      },
    })
    api.patch.mockResolvedValue({ data: { item: { source: 'support', id: 'ticket-1', status: 'closed' } } })

    render(<ModerationQueue />)

    await waitFor(() => {
      expect(api.get).toHaveBeenCalledWith('/admin/moderation/queue', {
        params: {
          page: 1,
          source: 'all',
          status: 'open',
        },
      })
    })

    expect(await screen.findByText('Support ticket')).toBeInTheDocument()
    expect(screen.getByText('Icerik inceleme talebi')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Kapat' }))

    await waitFor(() => {
      expect(api.patch).toHaveBeenCalledWith('/admin/moderation/queue/support/ticket-1', {
        action: 'closed',
      })
    })

    expect(toast.success).toHaveBeenCalledWith('Kapat uygulandi')
  }, 10000)
})
