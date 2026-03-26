import { useState, useEffect, useCallback } from 'react'
import api from '../api.js'
import toast from 'react-hot-toast'

const SERVICE_LABELS = {
  walking: 'Gezdirme',
  home_sitting: 'Eve Bakım',
  boarding: 'Pansiyona Alma',
  daycare: 'Gündüz Bakım',
  grooming: 'Tımar',
}

const VERIFIED_COLORS = {
  true: 'bg-green-100 text-green-700',
  false: 'bg-yellow-100 text-yellow-700',
}

export default function Sitters() {
  const [sitters, setSitters] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [filter, setFilter] = useState('all')
  const [loading, setLoading] = useState(false)
  const [actionId, setActionId] = useState(null)

  const fetchSitters = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get('/admin/pet-sitters', { params: { page, verified: filter } })
      setSitters(res.data?.sitters || [])
      setTotal(res.data?.total || 0)
    } catch (e) {
      toast.error(e.response?.data?.message || 'Bakıcılar yüklenemedi')
    } finally {
      setLoading(false)
    }
  }, [page, filter])

  useEffect(() => { fetchSitters() }, [fetchSitters])

  async function toggleVerify(sitter) {
    setActionId(sitter._id)
    try {
      await api.patch(`/admin/pet-sitters/${sitter._id}/verify`, { isVerified: !sitter.isVerified })
      toast.success(sitter.isVerified ? 'Doğrulama kaldırıldı' : 'Bakıcı doğrulandı')
      fetchSitters()
    } catch (e) {
      toast.error(e.response?.data?.message || 'İşlem başarısız')
    } finally {
      setActionId(null)
    }
  }

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Bakıcı Yönetimi</h1>
          <p className="text-sm text-gray-500 mt-1">Toplam {total} bakıcı</p>
        </div>
        <div className="flex gap-2">
          {[
            { key: 'all', label: 'Tümü' },
            { key: 'false', label: 'Bekliyor' },
            { key: 'true', label: 'Doğrulandı' },
          ].map(({ key, label }) => (
            <button
              key={key}
              onClick={() => { setFilter(key); setPage(1) }}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                filter === key
                  ? 'bg-indigo-600 text-white'
                  : 'bg-white text-gray-600 border hover:bg-gray-50'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="text-center py-16 text-gray-400">Yükleniyor...</div>
        ) : sitters.length === 0 ? (
          <div className="text-center py-16 text-gray-400">Bakıcı bulunamadı</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                {['Bakıcı', 'Hizmetler', 'Tür', 'Puan', 'Durum', 'İşlem'].map(h => (
                  <th key={h} className="text-left px-4 py-3 font-semibold text-gray-600">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {sitters.map(sitter => (
                <tr key={sitter._id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      {sitter.avatar ? (
                        <img src={sitter.avatar} className="w-9 h-9 rounded-full object-cover" alt="" />
                      ) : (
                        <div className="w-9 h-9 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600 font-bold text-sm">
                          {sitter.displayName?.[0]?.toUpperCase() || '?'}
                        </div>
                      )}
                      <div>
                        <div className="font-medium text-gray-900">{sitter.displayName}</div>
                        <div className="text-xs text-gray-400">{sitter.userId?.email || '-'}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-1 max-w-[180px]">
                      {(sitter.services || []).slice(0, 3).map(s => (
                        <span key={s.type} className="px-1.5 py-0.5 bg-blue-50 text-blue-700 rounded text-xs">
                          {SERVICE_LABELS[s.type] || s.type}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-gray-500 text-xs">
                    {(sitter.speciesServed || []).join(', ') || '-'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1">
                      <span className="text-yellow-500">★</span>
                      <span className="font-medium">{sitter.rating?.toFixed(1) || '0.0'}</span>
                      <span className="text-gray-400 text-xs">({sitter.reviewCount || 0})</span>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-1 rounded-full text-xs font-semibold ${VERIFIED_COLORS[String(sitter.isVerified)]}`}>
                      {sitter.isVerified ? '✓ Doğrulandı' : '⏳ Bekliyor'}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => toggleVerify(sitter)}
                      disabled={actionId === sitter._id}
                      className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                        sitter.isVerified
                          ? 'bg-red-50 text-red-600 hover:bg-red-100'
                          : 'bg-green-50 text-green-700 hover:bg-green-100'
                      }`}
                    >
                      {actionId === sitter._id
                        ? '...'
                        : sitter.isVerified
                        ? 'Doğrulamayı Kaldır'
                        : 'Doğrula'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-4">
          <button
            onClick={() => setPage(p => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-3 py-1.5 rounded-lg border text-sm disabled:opacity-40"
          >
            ← Önceki
          </button>
          <span className="px-3 py-1.5 text-sm text-gray-600">{page} / {totalPages}</span>
          <button
            onClick={() => setPage(p => Math.min(totalPages, p + 1))}
            disabled={page === totalPages}
            className="px-3 py-1.5 rounded-lg border text-sm disabled:opacity-40"
          >
            Sonraki →
          </button>
        </div>
      )}
    </div>
  )
}
