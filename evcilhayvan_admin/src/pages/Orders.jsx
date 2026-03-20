import { useEffect, useState } from 'react'
import api from '../api.js'
import Table from '../components/Table.jsx'

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

  useEffect(() => {
    setLoading(true)
    const params = { page }
    if (status !== 'all') params.status = status
    api.get('/admin/orders', { params })
      .then((res) => {
        setOrders(res.data?.data?.orders || [])
        setTotal(res.data?.data?.total || 0)
      })
      .finally(() => setLoading(false))
  }, [page, status])

  const columns = [
    {
      key: 'user',
      label: 'Müşteri',
      render: (r) => r.user?.name || r.user?.email || '—',
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
        <span className="text-sm text-gray-500">{total} sipariş</span>
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
    </div>
  )
}
