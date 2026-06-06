import { NavLink } from 'react-router-dom'
import { useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import api from '../api.js'
import Table from '../components/Table.jsx'

const TRACKING_URLS = {
  Yurtici: (trackingNumber) => `https://www.yurticikargo.com/tr/online-islemler/gonderi-sorgula?code=${trackingNumber}`,
  MNG: (trackingNumber) => `https://www.mngkargo.com.tr/gonderi-sorgula?trackingNo=${trackingNumber}`,
  Aras: (trackingNumber) => `https://www.araskargo.com.tr/kargo-takip?trackingNo=${trackingNumber}`,
  PTT: (trackingNumber) => `https://gonderitakip.ptt.gov.tr/Track/Verify?q=${trackingNumber}`,
  Surat: (trackingNumber) => `https://www.suratkargo.com.tr/KargoTakip?TakipNo=${trackingNumber}`,
  UPS: (trackingNumber) => `https://www.ups.com/track?tracknum=${trackingNumber}`,
  DHL: (trackingNumber) => `https://www.dhl.com/tr-tr/home/tracking.html?tracking-id=${trackingNumber}`,
}

const STATUS_LABELS = {
  pending: 'Bekliyor',
  processing: 'Hazirlaniyor',
  shipped: 'Yolda',
  delivered: 'Teslim edildi',
  cancelled: 'Iptal',
}

const STATUS_COLORS = {
  pending: 'bg-yellow-100 text-yellow-700',
  processing: 'bg-blue-100 text-blue-700',
  shipped: 'bg-indigo-100 text-indigo-700',
  delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-600',
}

const PAYMENT_LABELS = {
  paid: 'Odendi',
  pending: 'Bekliyor',
  failed: 'Basarisiz',
  refunded: 'Iade edildi',
}

const PAYMENT_COLORS = {
  paid: 'bg-green-100 text-green-700',
  pending: 'bg-yellow-100 text-yellow-700',
  failed: 'bg-red-100 text-red-600',
  refunded: 'bg-emerald-50 text-emerald-700',
}

const RETURN_LABELS = {
  pending: 'Incelemede',
  approved: 'Onaylandi',
  rejected: 'Reddedildi',
}

const RETURN_COLORS = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-emerald-50 text-emerald-700',
  rejected: 'bg-rose-50 text-rose-700',
}

const FILTER_BUTTONS = [
  ['all', 'Tumu'],
  ['pending', 'Bekliyor'],
  ['processing', 'Hazirlaniyor'],
  ['shipped', 'Yolda'],
  ['delivered', 'Teslim'],
  ['cancelled', 'Iptal'],
]

const CARRIERS = ['Yurtici', 'MNG', 'Aras', 'PTT', 'Surat', 'UPS', 'DHL', 'Diger']

export default function Orders() {
  const [orders, setOrders] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('all')
  const [loading, setLoading] = useState(true)
  const [trackingModal, setTrackingModal] = useState(null)
  const [trackingForm, setTrackingForm] = useState({
    carrier: 'Yurtici',
    trackingNumber: '',
    estimatedDelivery: '',
  })
  const [savingTracking, setSavingTracking] = useState(false)
  const [exporting, setExporting] = useState(false)
  const [guestSensitiveModal, setGuestSensitiveModal] = useState(null)

  useEffect(() => {
    loadOrders(page, status)
  }, [page, status])

  async function loadOrders(nextPage, nextStatus) {
    setLoading(true)
    try {
      const params = { page: nextPage }
      if (nextStatus !== 'all') params.status = nextStatus
      const response = await api.get('/admin/orders', { params })
      setOrders(response.data?.orders || [])
      setTotal(response.data?.total || 0)
    } catch (error) {
      toast.error(error.response?.data?.message || 'Siparisler yuklenemedi')
    } finally {
      setLoading(false)
    }
  }

  async function exportCsv() {
    setExporting(true)
    try {
      const params = {}
      if (status !== 'all') params.status = status
      const response = await api.get('/admin/orders/export', {
        params,
        responseType: 'blob',
      })
      const url = URL.createObjectURL(new Blob([response.data], { type: 'text/csv;charset=utf-8;' }))
      const link = document.createElement('a')
      link.href = url
      link.download = `siparisler-${new Date().toISOString().slice(0, 10)}.csv`
      link.click()
      URL.revokeObjectURL(url)
    } catch {
      toast.error('Export basarisiz')
    } finally {
      setExporting(false)
    }
  }

  function openTrackingModal(order) {
    setTrackingModal(order)
    setTrackingForm({
      carrier: normalizeCarrier(order.carrier) || 'Yurtici',
      trackingNumber: order.trackingNumber || '',
      estimatedDelivery: order.estimatedDelivery ? String(order.estimatedDelivery).slice(0, 10) : '',
    })
  }

  function openGuestSensitiveModal(order) {
    setGuestSensitiveModal({
      order,
      password: '',
      data: null,
      loading: false,
      error: '',
    })
  }

  async function fetchGuestSensitiveData(event) {
    event.preventDefault()
    if (!guestSensitiveModal?.order || !guestSensitiveModal.password.trim()) {
      setGuestSensitiveModal((current) => current ? { ...current, error: 'Ek veri sifresi gerekli' } : current)
      return
    }

    setGuestSensitiveModal((current) => current ? { ...current, loading: true, error: '' } : current)
    try {
      const response = await api.get(`/admin/orders/${guestSensitiveModal.order._id}/guest-sensitive`, {
        headers: { 'x-admin-data-password': guestSensitiveModal.password },
      })
      setGuestSensitiveModal((current) =>
        current ? { ...current, data: response.data || {}, loading: false, password: '' } : current
      )
    } catch (error) {
      setGuestSensitiveModal((current) =>
        current
          ? {
              ...current,
              loading: false,
              error: error.response?.data?.message || 'Misafir verisi acilamadi',
            }
          : current
      )
    }
  }

  async function saveTracking() {
    if (!trackingModal) return

    setSavingTracking(true)
    try {
      const response = await api.patch(`/admin/orders/${trackingModal._id}/tracking`, {
        carrier: denormalizeCarrier(trackingForm.carrier),
        trackingNumber: trackingForm.trackingNumber,
        estimatedDelivery: trackingForm.estimatedDelivery,
      })
      setOrders((current) =>
        current.map((order) => (order._id === trackingModal._id ? response.data?.order ?? order : order))
      )
      setTrackingModal(null)
      toast.success('Kargo bilgisi kaydedildi')
    } catch (error) {
      toast.error(error.response?.data?.message || 'Islem basarisiz')
    } finally {
      setSavingTracking(false)
    }
  }

  const columns = [
    {
      key: 'user',
      label: 'Musteri',
      render: (row) => {
        if (row.user?.name || row.user?.email) {
          return <span>{row.user.name || row.user.email}</span>
        }

        if (row.guestInfo?.name) {
          return (
            <div className="space-y-1">
              <span className="flex items-center gap-1">
                <span className="rounded bg-orange-100 px-1.5 py-0.5 text-xs font-semibold text-orange-700">Misafir</span>
                <span className="text-sm">{row.guestInfo.name}</span>
              </span>
              <button
                type="button"
                onClick={() => openGuestSensitiveModal(row)}
                className="rounded-lg bg-amber-50 px-2 py-1 text-xs font-semibold text-amber-700 hover:bg-amber-100"
              >
                Hassas veri
              </button>
            </div>
          )
        }

        return <span className="text-gray-400">—</span>
      },
    },
    {
      key: 'totalAmount',
      label: 'Tutar',
      render: (row) =>
        row.totalAmount != null
          ? `₺${Number(row.totalAmount).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}`
          : '—',
    },
    {
      key: 'items',
      label: 'Urun',
      render: (row) => `${Array.isArray(row.items) ? row.items.length : 0} urun`,
    },
    {
      key: 'status',
      label: 'Durum',
      render: (row) => (
        <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${STATUS_COLORS[row.status] || 'bg-gray-100 text-gray-500'}`}>
          {STATUS_LABELS[row.status] || row.status}
        </span>
      ),
    },
    {
      key: 'paymentStatus',
      label: 'Odeme',
      render: (row) => (
        <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${PAYMENT_COLORS[row.paymentStatus] || 'bg-gray-100 text-gray-500'}`}>
          {PAYMENT_LABELS[row.paymentStatus] || row.paymentStatus || '—'}
        </span>
      ),
    },
    {
      key: 'returnRequest',
      label: 'Iade',
      render: (row) => {
        if (!row.returnRequest?.status) {
          return <span className="text-xs text-gray-400">Talep yok</span>
        }

        return (
          <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${RETURN_COLORS[row.returnRequest.status] || 'bg-gray-100 text-gray-500'}`}>
            {RETURN_LABELS[row.returnRequest.status] || row.returnRequest.status}
          </span>
        )
      },
    },
    {
      key: 'createdAt',
      label: 'Tarih',
      render: (row) => (row.createdAt ? new Date(row.createdAt).toLocaleDateString('tr-TR') : '—'),
    },
    {
      key: 'tracking',
      label: 'Kargo',
      render: (row) => {
        if (!row.trackingNumber) return <span className="text-xs text-gray-300">—</span>

        const normalizedCarrier = normalizeCarrier(row.carrier)
        const urlBuilder = TRACKING_URLS[normalizedCarrier]
        const url = urlBuilder ? urlBuilder(row.trackingNumber) : null

        return (
          <div className="text-xs">
            <div className="font-semibold text-gray-700">{row.carrier || 'Kargo'}</div>
            {url ? (
              <a
                href={url}
                target="_blank"
                rel="noopener noreferrer"
                className="font-mono text-indigo-600 underline hover:text-indigo-800"
              >
                {row.trackingNumber}
              </a>
            ) : (
              <div className="font-mono text-gray-400">{row.trackingNumber}</div>
            )}
            {row.estimatedDelivery ? (
              <div className="mt-0.5 text-gray-400">
                Tahmini: {new Date(row.estimatedDelivery).toLocaleDateString('tr-TR')}
              </div>
            ) : null}
          </div>
        )
      },
    },
    {
      key: 'cargoAction',
      label: '',
      render: (row) => (
        <button
          type="button"
          onClick={() => openTrackingModal(row)}
          className="whitespace-nowrap rounded-lg bg-blue-50 px-2 py-1 text-xs font-semibold text-blue-700 transition-colors hover:bg-blue-100"
        >
          {row.trackingNumber ? 'Guncelle' : 'Kargo Ekle'}
        </button>
      ),
    },
  ]

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="mb-4 flex flex-wrap gap-2">
        <NavLink
          to="/orders"
          end
          className={({ isActive }) =>
            `rounded-2xl px-4 py-2 text-sm font-semibold transition ${
              isActive
                ? 'bg-indigo-600 text-white'
                : 'border border-gray-200 bg-white text-gray-600 hover:bg-gray-50'
            }`
          }
        >
          Siparisler
        </NavLink>
        <NavLink
          to="/returns"
          className={({ isActive }) =>
            `rounded-2xl px-4 py-2 text-sm font-semibold transition ${
              isActive
                ? 'bg-indigo-600 text-white'
                : 'border border-gray-200 bg-white text-gray-600 hover:bg-gray-50'
            }`
          }
        >
          Iade Talepleri
        </NavLink>
      </div>

      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800">Siparisler</h1>
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={exportCsv}
            disabled={exporting}
            className="rounded-xl border border-green-200 bg-green-50 px-4 py-2 text-sm font-semibold text-green-700 transition-colors hover:bg-green-100 disabled:opacity-50"
          >
            {exporting ? 'Indiriliyor...' : 'CSV Indir'}
          </button>
          <span className="text-sm text-gray-500">{total} siparis</span>
        </div>
      </div>

      <div className="mb-6 flex flex-wrap gap-2">
        {FILTER_BUTTONS.map(([value, label]) => (
          <button
            key={value}
            type="button"
            onClick={() => {
              setStatus(value)
              setPage(1)
            }}
            className={`rounded-xl px-4 py-2 text-sm font-semibold transition-colors ${
              status === value
                ? 'bg-indigo-600 text-white'
                : 'border border-gray-200 bg-white text-gray-600 hover:bg-gray-50'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="rounded-2xl bg-white p-4 shadow-sm">
        <Table columns={columns} rows={orders} loading={loading} emptyText="Siparis bulunamadi" />
      </div>

      {totalPages > 1 ? (
        <div className="mt-6 flex justify-center gap-2">
          <button
            type="button"
            onClick={() => setPage((current) => Math.max(1, current - 1))}
            disabled={page === 1}
            className="rounded-xl border px-4 py-2 text-sm disabled:opacity-40 hover:bg-gray-50"
          >
            ← Onceki
          </button>
          <span className="px-4 py-2 text-sm text-gray-500">{page} / {totalPages}</span>
          <button
            type="button"
            onClick={() => setPage((current) => Math.min(totalPages, current + 1))}
            disabled={page === totalPages}
            className="rounded-xl border px-4 py-2 text-sm disabled:opacity-40 hover:bg-gray-50"
          >
            Sonraki →
          </button>
        </div>
      ) : null}

      {trackingModal ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="w-96 rounded-2xl bg-white p-6 shadow-xl">
            <h2 className="mb-1 text-lg font-bold">Kargo Bilgisi</h2>
            <p className="mb-4 text-xs text-gray-500">Siparis #{trackingModal._id?.slice(-6)}</p>
            <div className="space-y-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Kargo Firmasi</label>
                <select
                  value={trackingForm.carrier}
                  onChange={(event) =>
                    setTrackingForm((current) => ({ ...current, carrier: event.target.value }))
                  }
                  className="w-full rounded-xl border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-300"
                >
                  {CARRIERS.map((carrier) => (
                    <option key={carrier} value={carrier}>
                      {carrier}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Takip Numarasi</label>
                <input
                  value={trackingForm.trackingNumber}
                  onChange={(event) =>
                    setTrackingForm((current) => ({ ...current, trackingNumber: event.target.value }))
                  }
                  placeholder="Orn: 1234567890"
                  className="w-full rounded-xl border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-300"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Tahmini Teslim Tarihi</label>
                <input
                  type="date"
                  value={trackingForm.estimatedDelivery}
                  onChange={(event) =>
                    setTrackingForm((current) => ({ ...current, estimatedDelivery: event.target.value }))
                  }
                  className="w-full rounded-xl border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-300"
                />
              </div>
            </div>
            <div className="mt-5 flex gap-2">
              <button
                type="button"
                onClick={() => setTrackingModal(null)}
                className="flex-1 rounded-xl border border-gray-200 py-2 text-sm text-gray-600 hover:bg-gray-50"
              >
                Iptal
              </button>
              <button
                type="button"
                onClick={saveTracking}
                disabled={savingTracking}
                className="flex-1 rounded-xl bg-blue-600 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
              >
                {savingTracking ? 'Kaydediliyor...' : 'Kaydet'}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {guestSensitiveModal ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4">
              <h2 className="text-lg font-bold text-slate-900">Misafir Siparis Verisi</h2>
              <p className="mt-1 text-xs text-slate-500">
                Siparis #{guestSensitiveModal.order?._id?.slice(-6)}
              </p>
            </div>

            {guestSensitiveModal.data ? (
              <div className="space-y-3">
                <SensitiveRow label="Ad" value={guestSensitiveModal.data.name} />
                <SensitiveRow label="Telefon" value={guestSensitiveModal.data.phone} />
                <SensitiveRow label="E-posta" value={guestSensitiveModal.data.email} />
                <SensitiveRow label="TC Kimlik" value={guestSensitiveModal.data.nationalId} />
              </div>
            ) : (
              <form onSubmit={fetchGuestSensitiveData} className="space-y-3">
                <div>
                  <label className="mb-1 block text-xs font-medium text-slate-600">
                    Ek veri sifresi
                  </label>
                  <input
                    type="password"
                    value={guestSensitiveModal.password}
                    onChange={(event) =>
                      setGuestSensitiveModal((current) =>
                        current ? { ...current, password: event.target.value, error: '' } : current
                      )
                    }
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-200"
                    autoFocus
                  />
                </div>
                {guestSensitiveModal.error ? (
                  <p className="rounded-xl bg-red-50 px-3 py-2 text-xs font-semibold text-red-700">
                    {guestSensitiveModal.error}
                  </p>
                ) : null}
                <button
                  type="submit"
                  disabled={guestSensitiveModal.loading}
                  className="w-full rounded-xl bg-amber-600 py-2 text-sm font-semibold text-white hover:bg-amber-700 disabled:opacity-50"
                >
                  {guestSensitiveModal.loading ? 'Aciluyor...' : 'Veriyi Ac'}
                </button>
              </form>
            )}

            <button
              type="button"
              onClick={() => setGuestSensitiveModal(null)}
              className="mt-4 w-full rounded-xl border border-slate-200 py-2 text-sm text-slate-600 hover:bg-slate-50"
            >
              Kapat
            </button>
          </div>
        </div>
      ) : null}
    </div>
  )
}

function SensitiveRow({ label, value }) {
  return (
    <div className="rounded-2xl bg-slate-50 px-4 py-3">
      <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">{label}</p>
      <p className="mt-1 font-mono text-sm font-semibold text-slate-900">{value || '-'}</p>
    </div>
  )
}

function normalizeCarrier(value) {
  if (!value) return null

  const raw = String(value)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
  if (raw.includes('yurti')) return 'Yurtici'
  if (raw.includes('mng')) return 'MNG'
  if (raw.includes('aras')) return 'Aras'
  if (raw.includes('ptt')) return 'PTT'
  if (raw.includes('surat')) return 'Surat'
  if (raw.includes('ups')) return 'UPS'
  if (raw.includes('dhl')) return 'DHL'
  return 'Diger'
}

function denormalizeCarrier(value) {
  if (value === 'Diger') return 'Diger'
  return value
}
