import { useEffect, useState } from 'react'
import api from '../api.js'
import Table from '../components/Table.jsx'
import toast from 'react-hot-toast'

const REASON_LABELS = {
  spam: 'Spam',
  harassment: 'Taciz',
  inappropriate_content: 'Uygunsuz İçerik',
  fake_profile: 'Sahte Profil',
  other: 'Diğer',
}

export default function Reports() {
  const [reports, setReports] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('pending')
  const [reason, setReason] = useState('all')
  const [loading, setLoading] = useState(true)
  const [resolving, setResolving] = useState(null)

  useEffect(() => {
    setLoading(true)
    const params = { page, status }
    if (reason !== 'all') params.reason = reason
    api.get('/admin/reports', { params })
      .then((res) => {
        setReports(res.data?.reports || [])
        setTotal(res.data?.total || 0)
      })
      .finally(() => setLoading(false))
  }, [page, status, reason])

  async function resolve(report, action) {
    setResolving(report._id)
    try {
      const res = await api.patch(`/admin/reports/${report._id}/resolve`, { action })
      const updated = res.data?.report
      setReports((prev) =>
        prev.map((r) => (r._id === report._id ? { ...r, status: updated.status } : r))
      )
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setResolving(null)
    }
  }

  const columns = [
    { key: 'reporterId', label: 'Şikayet Eden', render: (r) => r.reporterId?.name || r.reporterId?.email || '—' },
    { key: 'reportedId', label: 'Şikayet Edilen', render: (r) => r.reportedId?.name || r.reportedId?.email || '—' },
    { key: 'reason', label: 'Sebep', render: (r) => (
      <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-orange-100 text-orange-700">
        {REASON_LABELS[r.reason] || r.reason}
      </span>
    )},
    { key: 'status', label: 'Durum', render: (r) => {
      const colors = {
        pending: 'bg-yellow-100 text-yellow-700',
        reviewed: 'bg-green-100 text-green-700',
        dismissed: 'bg-gray-100 text-gray-500',
      }
      const labels = { pending: 'Bekliyor', reviewed: 'İncelendi', dismissed: 'Reddedildi' }
      return (
        <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${colors[r.status] || ''}`}>
          {labels[r.status] || r.status}
        </span>
      )
    }},
    { key: 'createdAt', label: 'Tarih', render: (r) =>
      r.createdAt ? new Date(r.createdAt).toLocaleDateString('tr-TR') : '—'
    },
    { key: 'actions', label: '', render: (r) =>
      r.status === 'pending' ? (
        <div className="flex gap-2">
          <button
            onClick={() => resolve(r, 'reviewed')}
            disabled={resolving === r._id}
            className="px-3 py-1 bg-green-100 text-green-700 hover:bg-green-200 rounded-lg text-xs font-semibold transition-colors"
          >
            {resolving === r._id ? '...' : 'İncele'}
          </button>
          <button
            onClick={() => resolve(r, 'dismissed')}
            disabled={resolving === r._id}
            className="px-3 py-1 bg-gray-100 text-gray-600 hover:bg-gray-200 rounded-lg text-xs font-semibold transition-colors"
          >
            Reddet
          </button>
        </div>
      ) : null
    },
  ]

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Şikayetler</h1>
        <span className="text-sm text-gray-500">{total} şikayet</span>
      </div>

      <div className="flex flex-wrap gap-3 mb-6 items-center">
        <div className="flex gap-2">
          {[['pending', 'Bekleyen'], ['reviewed', 'İncelendi'], ['dismissed', 'Reddedildi']].map(([val, label]) => (
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
        <select
          value={reason}
          onChange={(e) => { setReason(e.target.value); setPage(1) }}
          className="ml-auto px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white"
        >
          <option value="all">Tüm Sebepler</option>
          {Object.entries(REASON_LABELS).map(([val, label]) => (
            <option key={val} value={val}>{label}</option>
          ))}
        </select>
      </div>

      <div className="bg-white rounded-2xl shadow-sm p-4">
        <Table columns={columns} rows={reports} loading={loading} emptyText="Şikayet bulunamadı" />
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
