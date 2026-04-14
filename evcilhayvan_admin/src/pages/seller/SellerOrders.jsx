import { useEffect, useMemo, useState } from 'react'
import {
  EyeIcon,
  MagnifyingGlassIcon,
  TruckIcon,
} from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'
import api from '../../api.js'
import { resolveMediaUrl } from '../../lib/media.js'

const statusLabels = {
  pending: 'Bekliyor',
  processing: 'Hazirlaniyor',
  shipped: 'Kargoda',
  delivered: 'Teslim',
  cancelled: 'Iptal',
}

const statusColors = {
  pending: 'bg-amber-50 text-amber-700',
  processing: 'bg-sky-50 text-sky-700',
  shipped: 'bg-violet-50 text-violet-700',
  delivered: 'bg-emerald-50 text-emerald-700',
  cancelled: 'bg-rose-50 text-rose-700',
}

const statusFlow = ['pending', 'processing', 'shipped', 'delivered']

export default function SellerOrders() {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [detailOrder, setDetailOrder] = useState(null)
  const [shippingOrder, setShippingOrder] = useState(null)
  const [shippingForm, setShippingForm] = useState({
    trackingNumber: '',
    carrier: 'Yurtici',
    estimatedDelivery: '',
  })
  const [saving, setSaving] = useState(null)

  useEffect(() => {
    loadOrders()
  }, [])

  async function loadOrders() {
    setLoading(true)
    try {
      const response = await api.get('/seller/orders', { params: { limit: 100 } })
      setOrders(response.data?.orders || [])
    } catch (error) {
      toast.error(error.response?.data?.message || 'Siparisler yuklenemedi')
    } finally {
      setLoading(false)
    }
  }

  const filteredOrders = useMemo(() => {
    return orders.filter((order) => {
      const matchesStatus = statusFilter === 'all' || order.status === statusFilter
      const query = search.trim().toLowerCase()
      const matchesSearch =
        !query ||
        order._id?.toLowerCase().includes(query) ||
        order.user?.name?.toLowerCase().includes(query) ||
        order.user?.email?.toLowerCase().includes(query)

      return matchesStatus && matchesSearch
    })
  }, [orders, search, statusFilter])

  function nextStatus(status) {
    const currentIndex = statusFlow.indexOf(status)
    if (currentIndex < 0 || currentIndex >= statusFlow.length - 1) return null
    return statusFlow[currentIndex + 1]
  }

  async function updateStatus(order, status, extraPayload = {}) {
    setSaving(order._id)
    try {
      await api.patch(`/seller/orders/${order._id}/status`, {
        status,
        ...extraPayload,
      })
      toast.success(`Durum guncellendi: ${statusLabels[status] || status}`)
      setShippingOrder(null)
      setShippingForm({ trackingNumber: '', carrier: 'Yurtici', estimatedDelivery: '' })
      loadOrders()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Siparis guncellenemedi')
    } finally {
      setSaving(null)
    }
  }

  function openShippingModal(order) {
    setShippingOrder(order)
    setShippingForm({
      trackingNumber: order.trackingNumber || '',
      carrier: order.carrier || 'Yurtici',
      estimatedDelivery: order.estimatedDelivery ? String(order.estimatedDelivery).slice(0, 10) : '',
    })
  }

  return (
    <div className="space-y-6">
      <div className="rounded-[32px] bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 p-6 text-white shadow-panel">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-primary-100">Operasyon</p>
        <h2 className="mt-2 text-3xl font-black">Seller Siparis Yonetimi</h2>
        <p className="mt-2 max-w-3xl text-sm leading-7 text-primary-100">
          Hazirlama, kargo ve teslim akisini seller workspace icinde yonetin. Takip numarasi
          ve tahmini teslim tarihi artik bu panelden kaydolur.
        </p>
      </div>

      <div className="grid gap-4 lg:grid-cols-[1fr_auto]">
        <div className="relative">
          <MagnifyingGlassIcon className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
          <input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Musteri adi, e-posta veya siparis ID ara"
            className="w-full rounded-2xl border border-slate-200 bg-white px-12 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
          />
        </div>
        <div className="flex flex-wrap gap-2">
          {['all', ...Object.keys(statusLabels)].map((status) => (
            <button
              key={status}
              type="button"
              onClick={() => setStatusFilter(status)}
              className={`rounded-2xl px-4 py-3 text-sm font-semibold transition ${
                statusFilter === status
                  ? 'bg-primary-600 text-white'
                  : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
              }`}
            >
              {status === 'all' ? 'Tumu' : statusLabels[status]}
            </button>
          ))}
        </div>
      </div>

      <div className="overflow-hidden rounded-[32px] border border-white bg-white shadow-panel">
        {loading ? (
          <div className="space-y-3 p-6">
            {Array.from({ length: 5 }).map((_, index) => (
              <div key={index} className="h-16 animate-pulse rounded-3xl bg-slate-100" />
            ))}
          </div>
        ) : filteredOrders.length === 0 ? (
          <div className="px-6 py-20 text-center text-slate-400">Filtreye uyan siparis bulunamadi.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-slate-50 text-left text-xs uppercase tracking-[0.18em] text-slate-500">
                <tr>
                  <th className="px-5 py-4 font-semibold">Siparis</th>
                  <th className="px-5 py-4 font-semibold">Musteri</th>
                  <th className="px-5 py-4 font-semibold">Urunler</th>
                  <th className="px-5 py-4 font-semibold">Tutar</th>
                  <th className="px-5 py-4 font-semibold">Durum</th>
                  <th className="px-5 py-4 font-semibold text-right">Islemler</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredOrders.map((order) => {
                  const next = nextStatus(order.status)
                  return (
                    <tr key={order._id} className="hover:bg-slate-50/80">
                      <td className="px-5 py-4">
                        <p className="font-mono text-xs font-semibold text-slate-500">#{order._id?.slice(-8).toUpperCase()}</p>
                        <p className="mt-1 text-xs text-slate-400">{new Date(order.createdAt).toLocaleDateString('tr-TR')}</p>
                      </td>
                      <td className="px-5 py-4">
                        <p className="font-semibold text-slate-900">{order.user?.name || 'Musteri'}</p>
                        <p className="mt-1 text-xs text-slate-400">{order.user?.email || '—'}</p>
                      </td>
                      <td className="px-5 py-4 text-slate-600">{order.items?.length || 0} urun</td>
                      <td className="px-5 py-4 font-semibold text-primary-700">
                        ₺{Number(order.sellerTotal ?? order.totalAmount ?? 0).toLocaleString('tr-TR')}
                      </td>
                      <td className="px-5 py-4">
                        <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${statusColors[order.status] || 'bg-slate-100 text-slate-600'}`}>
                          {statusLabels[order.status] || order.status}
                        </span>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex justify-end gap-2">
                          <ActionButton onClick={() => setDetailOrder(order)}>
                            <EyeIcon className="h-4 w-4" />
                          </ActionButton>
                          {next ? (
                            <button
                              type="button"
                              onClick={() => (next === 'shipped' ? openShippingModal(order) : updateStatus(order, next))}
                              disabled={saving === order._id}
                              className="rounded-2xl bg-primary-600 px-4 py-2 text-xs font-semibold text-white transition hover:bg-primary-700 disabled:cursor-not-allowed disabled:opacity-60"
                            >
                              {saving === order._id ? 'Kaydediliyor...' : statusLabels[next]}
                            </button>
                          ) : null}
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {detailOrder ? (
        <OrderModal order={detailOrder} onClose={() => setDetailOrder(null)} />
      ) : null}

      {shippingOrder ? (
        <Modal title="Kargo Bilgisi" onClose={() => setShippingOrder(null)} size="sm">
          <div className="space-y-4">
            <Field label="Takip numarasi" value={shippingForm.trackingNumber} onChange={(value) => setShippingForm((current) => ({ ...current, trackingNumber: value }))} />
            <Field label="Kargo firmasi" value={shippingForm.carrier} onChange={(value) => setShippingForm((current) => ({ ...current, carrier: value }))} />
            <Field label="Tahmini teslim tarihi" type="date" value={shippingForm.estimatedDelivery} onChange={(value) => setShippingForm((current) => ({ ...current, estimatedDelivery: value }))} />
            <div className="flex gap-3">
              <button type="button" onClick={() => setShippingOrder(null)} className="flex-1 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-600">
                Iptal
              </button>
              <button
                type="button"
                onClick={() => updateStatus(shippingOrder, 'shipped', shippingForm)}
                disabled={saving === shippingOrder._id}
                className="flex-1 rounded-2xl bg-primary-600 px-4 py-3 text-sm font-semibold text-white disabled:cursor-not-allowed disabled:opacity-60"
              >
                {saving === shippingOrder._id ? 'Kaydediliyor...' : 'Kargoya ver'}
              </button>
            </div>
          </div>
        </Modal>
      ) : null}
    </div>
  )
}

function OrderModal({ order, onClose }) {
  return (
    <Modal title={`Siparis #${order._id?.slice(-8).toUpperCase()}`} onClose={onClose}>
      <div className="space-y-5">
        <div className="grid gap-4 sm:grid-cols-2">
          <InfoCard label="Musteri" value={order.user?.name || 'Musteri'} secondary={order.user?.email || '—'} />
          <InfoCard label="Durum" value={statusLabels[order.status] || order.status} secondary={order.trackingNumber || 'Takip bilgisi yok'} />
        </div>

        <div className="rounded-3xl border border-slate-100 bg-slate-50 p-4">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Urunler</p>
          <div className="mt-3 space-y-3">
            {order.items?.map((item, index) => (
              <div key={`${order._id}-${index}`} className="flex items-center gap-3 rounded-3xl bg-white px-3 py-3">
                <div className="flex h-14 w-14 items-center justify-center overflow-hidden rounded-2xl bg-slate-100">
                  {resolveMediaUrl(item.product?.images?.[0] || item.product?.photos?.[0]) ? (
                    <img src={resolveMediaUrl(item.product?.images?.[0] || item.product?.photos?.[0])} alt={item.product?.name || item.name} className="h-full w-full object-cover" />
                  ) : (
                    <TruckIcon className="h-5 w-5 text-slate-300" />
                  )}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-semibold text-slate-900">{item.product?.name || item.name || 'Urun'}</p>
                  <p className="mt-1 text-xs text-slate-500">Adet: {item.quantity}</p>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-primary-700">₺{Number((item.price || 0) * (item.quantity || 0)).toLocaleString('tr-TR')}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <InfoCard label="Adres" value={order.shippingAddress?.street || order.shippingAddress?.addressLine || 'Adres bilgisi yok'} secondary={[order.shippingAddress?.state, order.shippingAddress?.city].filter(Boolean).join(', ')} />
          <InfoCard label="Seller tutari" value={`₺${Number(order.sellerTotal ?? order.totalAmount ?? 0).toLocaleString('tr-TR')}`} secondary={order.carrier ? `Kargo: ${order.carrier}` : 'Kargo firmasi yok'} />
        </div>
      </div>
    </Modal>
  )
}

function InfoCard({ label, value, secondary }) {
  return (
    <div className="rounded-3xl border border-slate-100 bg-slate-50 px-4 py-4">
      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{label}</p>
      <p className="mt-3 font-semibold text-slate-900">{value}</p>
      {secondary ? <p className="mt-1 text-xs text-slate-500">{secondary}</p> : null}
    </div>
  )
}

function ActionButton({ children, ...props }) {
  return (
    <button type="button" className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-slate-200 bg-white text-slate-600 transition hover:bg-slate-100" {...props}>
      {children}
    </button>
  )
}

function Field({ label, type = 'text', value, onChange }) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-semibold text-slate-700">{label}</label>
      <input
        type={type}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
      />
    </div>
  )
}

function Modal({ children, title, onClose, size = 'lg' }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-slate-950/50 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative max-h-[90vh] w-full overflow-y-auto rounded-[32px] bg-white shadow-2xl ${size === 'sm' ? 'max-w-lg' : 'max-w-3xl'}`}>
        <div className="sticky top-0 flex items-center justify-between border-b border-slate-100 bg-white px-6 py-5">
          <h3 className="text-lg font-bold text-slate-900">{title}</h3>
          <button type="button" onClick={onClose} className="rounded-xl p-2 text-slate-400 hover:bg-slate-100">
            ×
          </button>
        </div>
        <div className="p-6">{children}</div>
      </div>
    </div>
  )
}
