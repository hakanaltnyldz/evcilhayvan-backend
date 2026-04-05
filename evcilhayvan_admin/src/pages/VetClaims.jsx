import { useEffect, useState } from 'react'
import api from '../api.js'
import toast from 'react-hot-toast'

const STATUS_LABELS = { pending: 'Bekliyor', approved: 'Onaylandı', rejected: 'Reddedildi' }
const STATUS_COLORS = {
  pending: 'bg-yellow-100 text-yellow-700',
  approved: 'bg-green-100 text-green-700',
  rejected: 'bg-red-100 text-red-600',
}

export default function VetClaims() {
  const [claims, setClaims] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState('pending')
  const [loading, setLoading] = useState(true)
  const [reviewing, setReviewing] = useState(null)
  const [noteModal, setNoteModal] = useState(null) // { claimId, action }
  const [adminNote, setAdminNote] = useState('')

  useEffect(() => {
    setLoading(true)
    api.get('/admin/vet-claims', { params: { page, status: statusFilter } })
      .then((res) => {
        setClaims(res.data?.claims || [])
        setTotal(res.data?.total || 0)
      })
      .catch(() => toast.error('Talepler yüklenemedi'))
      .finally(() => setLoading(false))
  }, [page, statusFilter])

  function openReview(claimId, action) {
    setNoteModal({ claimId, action })
    setAdminNote('')
  }

  async function submitReview() {
    if (!noteModal) return
    const { claimId, action } = noteModal
    setReviewing(claimId)
    setNoteModal(null)
    try {
      const res = await api.patch(`/admin/vet-claims/${claimId}/review`, { action, adminNote })
      const updated = res.data?.claim
      setClaims((prev) => prev.filter((c) => c._id !== claimId))
      setTotal((t) => t - 1)
      toast.success(action === 'approved' ? 'Talep onaylandı ✓' : 'Talep reddedildi')
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setReviewing(null)
    }
  }

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Klinik Sahiplenme Talepleri</h1>
        <span className="text-sm text-gray-500">{total} talep</span>
      </div>

      {/* Filtre */}
      <div className="flex gap-2 mb-6">
        {['pending', 'approved', 'rejected'].map((s) => (
          <button
            key={s}
            onClick={() => { setStatusFilter(s); setPage(1) }}
            className={`px-4 py-2 rounded-xl text-sm font-medium border transition-colors ${
              statusFilter === s
                ? 'bg-indigo-600 text-white border-indigo-600'
                : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'
            }`}
          >
            {STATUS_LABELS[s]}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="text-center py-16 text-gray-400">Yükleniyor...</div>
      ) : (
        <div className="space-y-4">
          {claims.map((claim) => (
            <div key={claim._id} className="bg-white rounded-2xl shadow-sm p-5">
              <div className="flex items-start gap-4">
                {/* Kullanıcı avatar */}
                <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center flex-shrink-0 overflow-hidden">
                  {claim.userId?.avatarUrl
                    ? <img src={claim.userId.avatarUrl} alt="" className="w-full h-full object-cover" />
                    : <span className="text-lg">👤</span>}
                </div>

                <div className="flex-1 min-w-0">
                  {/* Durum */}
                  <div className="flex items-center gap-2 mb-2 flex-wrap">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[claim.status]}`}>
                      {STATUS_LABELS[claim.status]}
                    </span>
                    <span className="text-xs text-gray-400">
                      {new Date(claim.createdAt).toLocaleDateString('tr-TR', { day: '2-digit', month: 'long', year: 'numeric' })}
                    </span>
                  </div>

                  <div className="grid grid-cols-2 gap-x-6 gap-y-1 text-sm mb-3">
                    <div>
                      <span className="text-gray-400 text-xs">Talep Eden</span>
                      <p className="font-medium text-gray-800">{claim.userId?.name || '—'}</p>
                      <p className="text-gray-500 text-xs">{claim.userId?.email}</p>
                    </div>
                    <div>
                      <span className="text-gray-400 text-xs">Klinik</span>
                      <p className="font-medium text-gray-800">{claim.vetId?.name || '—'}</p>
                      <p className="text-gray-500 text-xs truncate">{claim.vetId?.address}</p>
                    </div>
                    <div>
                      <span className="text-gray-400 text-xs">Ad Soyad</span>
                      <p className="text-gray-800">{claim.fullName}</p>
                    </div>
                    <div>
                      <span className="text-gray-400 text-xs">Telefon</span>
                      <p className="text-gray-800">{claim.phone}</p>
                    </div>
                    <div>
                      <span className="text-gray-400 text-xs">Klinikdeki Rolü</span>
                      <p className="text-gray-800">{claim.role}</p>
                    </div>
                    {claim.note && (
                      <div className="col-span-2">
                        <span className="text-gray-400 text-xs">Açıklama</span>
                        <p className="text-gray-700">{claim.note}</p>
                      </div>
                    )}
                    {claim.adminNote && (
                      <div className="col-span-2">
                        <span className="text-gray-400 text-xs">Admin Notu</span>
                        <p className="text-gray-600 italic">{claim.adminNote}</p>
                      </div>
                    )}
                  </div>

                  {/* Aksiyon butonları */}
                  {claim.status === 'pending' && (
                    <div className="flex gap-2">
                      <button
                        onClick={() => openReview(claim._id, 'approved')}
                        disabled={reviewing === claim._id}
                        className="px-4 py-1.5 rounded-lg text-xs font-semibold bg-green-50 text-green-700 hover:bg-green-100 transition-colors disabled:opacity-50"
                      >
                        ✓ Onayla
                      </button>
                      <button
                        onClick={() => openReview(claim._id, 'rejected')}
                        disabled={reviewing === claim._id}
                        className="px-4 py-1.5 rounded-lg text-xs font-semibold bg-red-50 text-red-600 hover:bg-red-100 transition-colors disabled:opacity-50"
                      >
                        ✕ Reddet
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}

          {claims.length === 0 && (
            <div className="text-center py-16 text-gray-400">
              {statusFilter === 'pending' ? 'Bekleyen talep yok' : 'Talep bulunamadı'}
            </div>
          )}
        </div>
      )}

      {totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-6">
          <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1}
            className="px-4 py-2 rounded-xl border text-sm disabled:opacity-40 hover:bg-gray-50">← Önceki</button>
          <span className="px-4 py-2 text-sm text-gray-500">{page} / {totalPages}</span>
          <button onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages}
            className="px-4 py-2 rounded-xl border text-sm disabled:opacity-40 hover:bg-gray-50">Sonraki →</button>
        </div>
      )}

      {/* Not modal */}
      {noteModal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
            <h3 className="text-lg font-bold text-gray-800 mb-1">
              {noteModal.action === 'approved' ? '✓ Talebi Onayla' : '✕ Talebi Reddet'}
            </h3>
            <p className="text-sm text-gray-500 mb-4">İsteğe bağlı bir not ekleyebilirsiniz.</p>
            <textarea
              value={adminNote}
              onChange={(e) => setAdminNote(e.target.value)}
              placeholder="Admin notu (opsiyonel)..."
              rows={3}
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 mb-4 resize-none"
            />
            <div className="flex gap-2 justify-end">
              <button onClick={() => setNoteModal(null)}
                className="px-4 py-2 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50">
                İptal
              </button>
              <button
                onClick={submitReview}
                className={`px-5 py-2 rounded-xl text-sm font-semibold text-white transition-colors ${
                  noteModal.action === 'approved'
                    ? 'bg-green-600 hover:bg-green-700'
                    : 'bg-red-600 hover:bg-red-700'
                }`}
              >
                {noteModal.action === 'approved' ? 'Onayla' : 'Reddet'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
