import { useEffect, useState } from 'react'
import api from '../api.js'
import Table from '../components/Table.jsx'
import toast from 'react-hot-toast'

const TRACKING_URLS = {
  'Yurtiçi': (no) => `https://www.yurticikargo.com/tr/online-islemler/gonderi-sorgula?code=${no}`,
  'MNG':     (no) => `https://www.mngkargo.com.tr/gonderi-sorgula?trackingNo=${no}`,
  'Aras':    (no) => `https://www.araskargo.com.tr/kargo-takip?trackingNo=${no}`,
  'PTT':     (no) => `https://gonderitakip.ptt.gov.tr/Track/Verify?q=${no}`,
  'Sürat':   (no) => `https://www.suratkargo.com.tr/KargoTakip?TakipNo=${no}`,
  'UPS':     (no) => `https://www.ups.com/track?tracknum=${no}`,
  'DHL':     (no) => `https://www.dhl.com/tr-tr/home/tracking.html?tracking-id=${no}`,
}

const STATUS_LABELS = {
  pending: 'Bekliyor',
  processing: 'Hazırlanıyor',
  shipped: 'Yolda',
  delivered: 'Teslim Edildi',
  cancelled: 'İptal',
}

const STATUS_COLORS = {
  pending: 'bg-yellow-100 text-yellow-700',
  processing: 'bg-blue-100 text-blue-700',
  shipped: 'bg-indigo-100 text-indigo-700',
  delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-600',
}

const PAYMENT_LABELS = { paid: 'Ödendi', pending: 'Bekliyor', failed: 'Başarısız' }
const PAYMENT_COLORS = {
  paid: 'bg-green-100 text-green-700',
  pending: 'bg-yellow-100 text-yellow-700',
  failed: 'bg-red-100 text-red-600',
}

export default function Orders() {
  const [orders, setOrders] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('all')
  const [loading, setLoading] = useState(true)
  const [trackingModal, setTrackingModal] = useState(null)
  const [trackingForm, setTrackingForm] = useState({ carrier: 'Yurtiçi', trackingNumber: '', estimatedDelivery: '' })
  const [savingTracking, setSavingTracking] = useState(false)
  const [exporting, setExporting] = useState(false)

  async function exportCsv() {
    setExporting(true)
    try {
      const params = {}
      if (status !== 'all') params.status = status
      const res = await api.get('/admin/orders/export', { params, responseType: 'blob' })
      const url = URL.createObjectURL(new Blob([res.data], { type: 'text/csv;charset=utf-8;' }))
      const a = document.createElement('a')
      a.href = url
      a.download = `siparisler-${new Date().toISOString().slice(0, 10)}.csv`
      a.click()
      URL.revokeObjectURL(url)
    } catch {
      toast.error('Export başarısız')
    } finally {
      setExporting(false)
    }
  }

  function openTrackingModal(order) {
    setTrackingModal(order)
    setTrackingForm({
      carrier: order.carrier || 'Yurtiçi',
      trackingNumber: order.trackingNumber || '',
      estimatedDelivery: order.estimatedDelivery ? order.estimatedDelivery.substring(0, 10) : '',
    })
  }

  async function saveTracking() {
    setSavingTracking(true)
    try {
      const res = await api.patch(`/admin/orders/${trackingModal._id}/tracking`, trackingForm)
      setOrders((prev) => prev.map((o) => o._id === trackingModal._id ? (res.data.order ?? o) : o))
      setTrackingModal(null)
      toast.success('Kargo bilgisi kaydedildi')
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setSavingTracking(false)
    }
  }

  useEffect(() => {
    setLoading(true)
    const params = { page }
    if (status !== 'all') params.status = status
    api.get('/admin/orders', { params })
      .then((res) => {
        setOrders(res.data?.orders || [])
        setTotal(res.data?.total || 0)
      })
      .finally(() => setLoading(false))
  }, [page, status])

  const columns = [
    {
      key: 'user',
      label: 'Müşteri',
      render: (r) => {
        if (r.user?.name || r.user?.email) {
          return <span>{r.user.name || r.user.email}</span>
        }
        if (r.guestInfo?.name) {
          return (
            <span className="flex items-center gap-1">
              <span className="px-1.5 py-0.5 bg-orange-100 text-orange-700 text-xs rounded font-semibold">Misafir</span>
              <span className="text-sm">{r.guestInfo.name}</span>
            </span>
          )
        }
        return <span className="text-gray-400">—</span>
      },
    },
    {
      key: 'totalAmount',
      label: 'Tutar',
      render: (r) =>
        r.totalAmount != null
          ? `₺${Number(r.totalAmount).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}`
          : '—',
    },
    {
      key: 'items',
      label: 'Ürün',
      render: (r) => `${Array.isArray(r.items) ? r.items.length : 0} ürün`,
    },
    {
      key: 'status',
      label: 'Durum',
      render: (r) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[r.status] || 'bg-gray-100 text-gray-500'}`}>
          {STATUS_LABELS[r.status] || r.status}
        </span>
      ),
    },
    {
      key: 'paymentStatus',
      label: 'Ödeme',
      render: (r) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${PAYMENT_COLORS[r.paymentStatus] || 'bg-gray-100 text-gray-500'}`}>
          {PAYMENT_LABELS[r.paymentStatus] || r.paymentStatus || '—'}
        </span>
      ),
    },
    {
      key: 'createdAt',
      label: 'Tarih',
      render: (r) =>
        r.createdAt ? new Date(r.createdAt).toLocaleDateString('tr-TR') : '—',
    },
    {
      key: 'tracking',
      label: 'Kargo',
      render: (r) => {
        if (!r.trackingNumber) return <span className="text-gray-300 text-xs">—</span>
        const urlFn = TRACKING_URLS[r.carrier]
        const url = urlFn ? urlFn(r.trackingNumber) : null
        return (
          <div className="text-xs">
            <div className="font-semibold text-gray-700">{r.carrier}</div>
            {url ? (
              <a
                href={url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-indigo-600 hover:text-indigo-800 font-mono underline"
              >
                {r.trackingNumber}
              </a>
            ) : (
              <div className="text-gray-400 font-mono">{r.trackingNumber}</div>
            )}
            {r.estimatedDelivery && (
              <div className="text-gray-400 mt-0.5">
                Tahmini: {new Date(r.estimatedDelivery).toLocaleDateString('tr-TR')}
              </div>
            )}
          </div>
        )
      },
    },
    {
      key: 'cargoAction',
      label: '',
      render: (r) => (
        <button
          onClick={() => openTrackingModal(r)}
          className="px-2 py-1 rounded-lg text-xs font-semibold bg-blue-50 text-blue-700 hover:bg-blue-100 transition-colors whitespace-nowrap"
        >
          {r.trackingNumber ? 'Güncelle' : 'Kargo Ekle'}
        </button>
      ),
    },
  ]

  const totalPages = Math.ceil(total / 20)
  const filterButtons = [
    ['all', 'Tümü'],
    ['pending', 'Bekliyor'],
    ['processing', 'Hazırlanıyor'],
    ['shipped', 'Yolda'],
    ['delivered', 'Teslim'],
    ['cancelled', 'İptal'],
  ]

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Siparişler</h1>
        <div className="flex items-center gap-3">
          <button
            onClick={exportCsv}
            disabled={exporting}
            className="px-4 py-2 rounded-xl text-sm font-semibold bg-green-50 text-green-700 hover:bg-green-100 border border-green-200 transition-colors disabled:opacity-50"
          >
            {exporting ? 'İndiriliyor...' : '⬇ CSV İndir'}
          </button>
          <span className="text-sm text-gray-500">{total} sipariş</span>
        </div>
      </div>

      <div className="flex flex-wrap gap-2 mb-6">
        {filterButtons.map(([val, label]) => (
          <button
            key={val}
            onClick={() => { setStatus(val); setPage(1) }}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-colors ${
              status === val
                ? 'bg-indigo-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-2xl shadow-sm p-4">
        <Table columns={columns} rows={orders} loading={loading} emptyText="Sipariş bulunamadı" />
      </div>

      {totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-6">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-4 py-2 rounded-xl border text-sm disabled:opacity-40 hover:bg-gray-50"
          >
            ← Önceki
          </button>
          <span className="px-4 py-2 text-sm text-gray-500">{page} / {totalPages}</span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page === totalPages}
            className="px-4 py-2 rounded-xl border text-sm disabled:opacity-40 hover:bg-gray-50"
          >
            Sonraki →
          </button>
        </div>
      )}

      {trackingModal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-96 shadow-xl">
            <h2 className="font-bold text-lg mb-1">Kargo Bilgisi</h2>
            <p className="text-xs text-gray-500 mb-4">Sipariş #{trackingModal._id?.slice(-6)}</p>
            <div className="space-y-3">
              <div>
                <label className="text-xs font-medium text-gray-600 mb-1 block">Kargo Firması</label>
                <select
                  value={trackingForm.carrier}
                  onChange={(e) => setTrackingForm({ ...trackingForm, carrier: e.target.value })}
                  className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-300"
                >
                  {['Yurtiçi', 'MNG', 'Aras', 'PTT', 'Sürat', 'UPS', 'DHL', 'Diğer'].map((c) => (
                    <option key={c}>{c}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600 mb-1 block">Takip Numarası</label>
                <input
                  placeholder="Örn: 1234567890"
                  value={trackingForm.trackingNumber}
                  onChange={(e) => setTrackingForm({ ...trackingForm, trackingNumber: e.target.value })}
                  className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-300"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600 mb-1 block">Tahmini Teslim Tarihi</label>
                <input
                  type="date"
                  value={trackingForm.estimatedDelivery}
                  onChange={(e) => setTrackingForm({ ...trackingForm, estimatedDelivery: e.target.value })}
                  className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-300"
                />
              </div>
            </div>
            <div className="flex gap-2 mt-5">
              <button
                onClick={() => setTrackingModal(null)}
                className="flex-1 py-2 rounded-xl border border-gray-200 text-sm text-gray-600 hover:bg-gray-50"
              >
                İptal
              </button>
              <button
                onClick={saveTracking}
                disabled={savingTracking}
                className="flex-1 py-2 rounded-xl bg-blue-600 text-white text-sm font-semibold hover:bg-blue-700 disabled:opacity-50"
              >
                {savingTracking ? 'Kaydediliyor...' : 'Kaydet'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
