import { useEffect, useState } from 'react'
import api from '../api.js'
import toast from 'react-hot-toast'

const STATUS_LABELS = {
  open: { label: 'Açık', cls: 'bg-red-100 text-red-700' },
  reviewing: { label: 'İnceleniyor', cls: 'bg-yellow-100 text-yellow-700' },
  closed: { label: 'Kapalı', cls: 'bg-gray-100 text-gray-600' },
}

const CATEGORY_LABELS = {
  app_bug: { label: 'Uygulama Hatası', cls: 'bg-red-50 text-red-600' },
  content_complaint: { label: 'İçerik Şikayeti', cls: 'bg-purple-50 text-purple-600' },
  user_complaint: { label: 'Kullanıcı Şikayeti', cls: 'bg-orange-50 text-orange-600' },
  payment_issue: { label: 'Ödeme Sorunu', cls: 'bg-yellow-50 text-yellow-600' },
  account_issue: { label: 'Hesap Sorunu', cls: 'bg-blue-50 text-blue-600' },
  other: { label: 'Diğer', cls: 'bg-gray-50 text-gray-600' },
}

export default function Support() {
  const [tickets, setTickets] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [selectedTicket, setSelectedTicket] = useState(null)
  const [modalStatus, setModalStatus] = useState('')
  const [modalNote, setModalNote] = useState('')
  const [saving, setSaving] = useState(false)

  const fetchTickets = (p = 1, status = statusFilter) => {
    setLoading(true)
    const params = { page: p, limit: 20 }
    if (status !== 'all') params.status = status
    api.get('/admin/support', { params })
      .then(res => {
        setTickets(res.data?.tickets || [])
        setTotal(res.data?.total || 0)
        setPage(p)
      })
      .catch(err => setError(err.response?.data?.message || 'Destek ticketları alınamadı'))
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchTickets(1, statusFilter) }, [statusFilter])

  const openModal = (ticket) => {
    setSelectedTicket(ticket)
    setModalStatus(ticket.status)
    setModalNote(ticket.adminNote || '')
  }

  const closeModal = () => setSelectedTicket(null)

  const saveTicket = async () => {
    if (!selectedTicket) return
    const trimmedNote = modalNote.trim()
    if (modalStatus === 'closed' && !trimmedNote) {
      toast.error('Kapatma durumunda admin notu zorunludur')
      return
    }
    if (modalNote && !trimmedNote) {
      toast.error('Admin notu sadece bosluk olamaz')
      return
    }
    if (trimmedNote.length > 500) {
      toast.error('Admin notu en fazla 500 karakter olabilir')
      return
    }
    setSaving(true)
    try {
      await api.patch(`/admin/support/${selectedTicket._id}`, {
        status: modalStatus,
        adminNote: trimmedNote,
      })
      closeModal()
      fetchTickets(page, statusFilter)
    } catch (err) {
      toast.error(err.response?.data?.message || 'Güncelleme başarısız')
    } finally {
      setSaving(false)
    }
  }

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Destek Ticketları</h1>
        <span className="text-sm text-gray-500">{total} kayıt</span>
      </div>

      {/* Status filter tabs */}
      <div className="flex gap-2 mb-5">
        {['all', 'open', 'reviewing', 'closed'].map(s => (
          <button
            key={s}
            onClick={() => setStatusFilter(s)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
              statusFilter === s
                ? 'bg-indigo-600 text-white'
                : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
            }`}
          >
            {s === 'all' ? 'Tümü' : STATUS_LABELS[s]?.label}
          </button>
        ))}
      </div>

      {error && <div className="bg-red-50 text-red-600 rounded-xl p-4 mb-4">{error}</div>}

      {loading ? (
        <div className="flex justify-center items-center h-48 text-gray-400">
          <span className="animate-spin text-3xl">⏳</span>
        </div>
      ) : tickets.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center text-gray-400">
          <div className="text-4xl mb-3">🎫</div>
          <p>Hiç destek ticketı bulunamadı</p>
        </div>
      ) : (
        <>
          <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 uppercase text-xs">
                <tr>
                  <th className="px-4 py-3 text-left">Kullanıcı</th>
                  <th className="px-4 py-3 text-left">Kategori</th>
                  <th className="px-4 py-3 text-left">Mesaj</th>
                  <th className="px-4 py-3 text-left">Durum</th>
                  <th className="px-4 py-3 text-left">Tarih</th>
                  <th className="px-4 py-3 text-left">İşlem</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {tickets.map(ticket => {
                  const cat = CATEGORY_LABELS[ticket.category] || CATEGORY_LABELS.other
                  const st = STATUS_LABELS[ticket.status] || STATUS_LABELS.open
                  const user = ticket.userId
                  return (
                    <tr key={ticket._id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-3">
                        <div className="font-medium text-gray-800">{user?.name || '—'}</div>
                        <div className="text-xs text-gray-400">{user?.email || '—'}</div>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${cat.cls}`}>
                          {cat.label}
                        </span>
                      </td>
                      <td className="px-4 py-3 max-w-xs">
                        <p className="truncate text-gray-600">{ticket.message}</p>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${st.cls}`}>
                          {st.label}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-gray-400 whitespace-nowrap">
                        {new Date(ticket.createdAt).toLocaleDateString('tr-TR')}
                      </td>
                      <td className="px-4 py-3">
                        <button
                          onClick={() => openModal(ticket)}
                          className="text-indigo-600 hover:text-indigo-800 font-medium text-xs"
                        >
                          Detay
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex justify-center gap-2 mt-5">
              <button
                disabled={page <= 1}
                onClick={() => fetchTickets(page - 1, statusFilter)}
                className="px-3 py-1 rounded-lg border text-sm disabled:opacity-40"
              >
                ← Önceki
              </button>
              <span className="px-3 py-1 text-sm text-gray-600">{page} / {totalPages}</span>
              <button
                disabled={page >= totalPages}
                onClick={() => fetchTickets(page + 1, statusFilter)}
                className="px-3 py-1 rounded-lg border text-sm disabled:opacity-40"
              >
                Sonraki →
              </button>
            </div>
          )}
        </>
      )}

      {/* Detail Modal */}
      {selectedTicket && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg">
            <div className="flex items-center justify-between px-6 py-4 border-b">
              <h2 className="font-bold text-lg text-gray-800">Ticket Detayı</h2>
              <button onClick={closeModal} className="text-gray-400 hover:text-gray-600 text-xl">×</button>
            </div>
            <div className="px-6 py-4 space-y-4">
              {/* User info */}
              <div>
                <p className="text-xs text-gray-400 uppercase font-medium mb-1">Kullanıcı</p>
                <p className="font-medium text-gray-800">{selectedTicket.userId?.name || '—'}</p>
                <p className="text-sm text-gray-400">{selectedTicket.userId?.email || '—'}</p>
              </div>
              {/* Category */}
              <div>
                <p className="text-xs text-gray-400 uppercase font-medium mb-1">Kategori</p>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${(CATEGORY_LABELS[selectedTicket.category] || CATEGORY_LABELS.other).cls}`}>
                  {(CATEGORY_LABELS[selectedTicket.category] || CATEGORY_LABELS.other).label}
                </span>
              </div>
              {/* Message */}
              <div>
                <p className="text-xs text-gray-400 uppercase font-medium mb-1">Mesaj</p>
                <p className="text-gray-700 whitespace-pre-wrap bg-gray-50 rounded-lg p-3 text-sm">
                  {selectedTicket.message}
                </p>
              </div>
              {/* Status select */}
              <div>
                <label className="text-xs text-gray-400 uppercase font-medium block mb-1">Durum</label>
                <select
                  value={modalStatus}
                  onChange={e => setModalStatus(e.target.value)}
                  className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                >
                  <option value="open">Açık</option>
                  <option value="reviewing">İnceleniyor</option>
                  <option value="closed">Kapalı</option>
                </select>
              </div>
              {/* Admin note */}
              <div>
                <label className="text-xs text-gray-400 uppercase font-medium block mb-1">Admin Notu</label>
                <textarea
                  value={modalNote}
                  onChange={e => setModalNote(e.target.value)}
                  rows={3}
                  maxLength={500}
                  placeholder="İç not (kullanıcıya gösterilmez)"
                  className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 resize-none"
                />
              </div>
            </div>
            <div className="flex justify-end gap-3 px-6 py-4 border-t">
              <button onClick={closeModal} className="px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-lg">
                İptal
              </button>
              <button
                onClick={saveTicket}
                disabled={saving}
                className="px-4 py-2 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50"
              >
                {saving ? 'Kaydediliyor...' : 'Kaydet'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
