import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { vi } from 'vitest'
import PlatformSettings from '../PlatformSettings.jsx'
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

describe('PlatformSettings', () => {
  it('loads platform config and saves updated fee values', async () => {
    api.get.mockResolvedValueOnce({
      data: {
        config: {
          fees: { storeCommissionRate: 16 },
          features: { maintenanceMode: true },
          announcement: {
            enabled: true,
            tone: 'warning',
            message: 'Planli bakim var',
          },
          updatedAt: '2026-04-22T09:00:00.000Z',
          updatedBy: { name: 'Admin User' },
        },
        runtime: {
          env: 'test',
          hasGooglePlacesApiKey: true,
          hasMailerConfig: false,
          hasAnthropicKey: false,
        },
      },
    })

    api.patch.mockResolvedValueOnce({
      data: {
        config: {
          fees: { storeCommissionRate: 18 },
          features: { maintenanceMode: true },
          moderation: {
            autoHideReportThreshold: 3,
            reviewSlaHours: 24,
            careReportReviewWindowHours: 48,
            escalateUserComplaintThreshold: 5,
          },
          contact: {
            supportEmail: '',
            supportPhone: '',
            supportWhatsapp: '',
          },
          announcement: {
            enabled: true,
            tone: 'warning',
            message: 'Planli bakim var',
          },
          updatedAt: '2026-04-22T10:00:00.000Z',
          updatedBy: { name: 'Admin User' },
        },
      },
    })

    render(<PlatformSettings />)

    await waitFor(() => {
      expect(api.get).toHaveBeenCalledWith('/admin/platform-config')
    })

    const feeInput = (await screen.findAllByRole('spinbutton'))[0]
    expect(feeInput).toHaveValue(16)
    expect(screen.getByText('Admin User')).toBeInTheDocument()
    expect(screen.getByText('Hazir')).toBeInTheDocument()

    fireEvent.change(feeInput, { target: { value: '18' } })
    fireEvent.click(screen.getByRole('button', { name: 'Degisiklikleri Kaydet' }))

    await waitFor(() => {
      expect(api.patch).toHaveBeenCalledWith(
        '/admin/platform-config',
        expect.objectContaining({
          fees: expect.objectContaining({
            storeCommissionRate: 18,
          }),
        })
      )
    })

    expect(toast.success).toHaveBeenCalledWith('Platform ayarlari kaydedildi')
  })
})
