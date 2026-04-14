import { useCallback, useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import api from '../api.js'

const serviceLabels = {
  walking: 'Gezdirme',
  home_sitting: 'Evde bakim',
  boarding: 'Pansiyon',
  daycare: 'Gunduz bakim',
  grooming: 'Timar',
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
      const response = await api.get('/admin/pet-sitters', { params: { page, verified: filter } })
      setSitters(response.data?.sitters || [])
      setTotal(response.data?.total || 0)
    } catch (error) {
      toast.error(error.response?.data?.message || 'Bakicilar yuklenemedi')
    } finally {
      setLoading(false)
    }
  }, [page, filter])

  useEffect(() => {
    fetchSitters()
  }, [fetchSitters])

  async function toggleVerify(sitter) {
    setActionId(sitter._id)
    try {
      await api.patch(`/admin/pet-sitters/${sitter._id}/verify`, { isVerified: !sitter.isVerified })
      toast.success(sitter.isVerified ? 'Dogrulama kaldirildi' : 'Bakici dogrulandi')
      fetchSitters()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Islem basarisiz')
    } finally {
      setActionId(null)
    }
  }

  async function toggleBan(sitter) {
    setActionId(sitter._id)
    try {
      await api.patch(`/admin/pet-sitters/${sitter._id}/ban`, {
        isBanned: sitter.isActive,
        reason: sitter.isActive ? 'Admin panelinden devre disi birakildi' : 'Admin panelinden tekrar aktif edildi',
      })
      toast.success(sitter.isActive ? 'Bakici devre disi birakildi' : 'Bakici tekrar aktif edildi')
      fetchSitters()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Islem basarisiz')
    } finally {
      setActionId(null)
    }
  }

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Bakici Yonetimi</h1>
          <p className="mt-1 text-sm text-gray-500">Toplam {total} bakici</p>
        </div>
        <div className="flex gap-2">
          {[
            { key: 'all', label: 'Tumu' },
            { key: 'false', label: 'Bekleyen' },
            { key: 'true', label: 'Dogrulanmis' },
          ].map(({ key, label }) => (
            <button
              key={key}
              onClick={() => {
                setFilter(key)
                setPage(1)
              }}
              className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${
                filter === key
                  ? 'bg-indigo-600 text-white'
                  : 'border bg-white text-gray-600 hover:bg-gray-50'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      <div className="overflow-hidden rounded-2xl bg-white shadow-sm">
        {loading ? (
          <div className="py-16 text-center text-gray-400">Yukleniyor...</div>
        ) : sitters.length === 0 ? (
          <div className="py-16 text-center text-gray-400">Bakici bulunamadi</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="border-b bg-gray-50">
              <tr>
                {['Bakici', 'Hizmetler', 'Tur', 'Puan', 'Durum', 'Islem'].map((header) => (
                  <th key={header} className="px-4 py-3 text-left font-semibold text-gray-600">
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {sitters.map((sitter) => (
                <tr key={sitter._id} className="transition-colors hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      {sitter.avatar ? (
                        <img src={sitter.avatar} className="h-9 w-9 rounded-full object-cover" alt="" />
                      ) : (
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-indigo-100 text-sm font-bold text-indigo-600">
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
                    <div className="flex max-w-[200px] flex-wrap gap-1">
                      {(sitter.services || []).slice(0, 3).map((service) => (
                        <span key={service.type} className="rounded bg-blue-50 px-1.5 py-0.5 text-xs text-blue-700">
                          {serviceLabels[service.type] || service.type}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500">
                    {(sitter.speciesServed || []).join(', ') || '-'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1">
                      <span className="text-yellow-500">★</span>
                      <span className="font-medium">{sitter.rating?.toFixed(1) || '0.0'}</span>
                      <span className="text-xs text-gray-400">({sitter.reviewCount || 0})</span>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex flex-col gap-1">
                      <span className={`rounded-full px-2 py-1 text-xs font-semibold ${
                        sitter.isVerified ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                      }`}>
                        {sitter.isVerified ? 'Dogrulandi' : 'Bekliyor'}
                      </span>
                      <span className={`rounded-full px-2 py-1 text-xs font-semibold ${
                        sitter.isActive ? 'bg-blue-50 text-blue-700' : 'bg-red-50 text-red-600'
                      }`}>
                        {sitter.isActive ? 'Aktif' : 'Devre disi'}
                      </span>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-2">
                      <button
                        onClick={() => toggleVerify(sitter)}
                        disabled={actionId === sitter._id}
                        className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors ${
                          sitter.isVerified
                            ? 'bg-red-50 text-red-600 hover:bg-red-100'
                            : 'bg-green-50 text-green-700 hover:bg-green-100'
                        }`}
                      >
                        {actionId === sitter._id ? '...' : sitter.isVerified ? 'Dogrulamayi Kaldir' : 'Dogrula'}
                      </button>
                      <button
                        onClick={() => toggleBan(sitter)}
                        disabled={actionId === sitter._id}
                        className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors ${
                          sitter.isActive
                            ? 'bg-amber-50 text-amber-700 hover:bg-amber-100'
                            : 'bg-blue-50 text-blue-700 hover:bg-blue-100'
                        }`}
                      >
                        {actionId === sitter._id ? '...' : sitter.isActive ? 'Devre Disi Birak' : 'Yeniden Aktif Et'}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {totalPages > 1 ? (
        <div className="mt-4 flex justify-center gap-2">
          <button
            onClick={() => setPage((current) => Math.max(1, current - 1))}
            disabled={page === 1}
            className="rounded-lg border px-3 py-1.5 text-sm disabled:opacity-40"
          >
            ← Onceki
          </button>
          <span className="px-3 py-1.5 text-sm text-gray-600">
            {page} / {totalPages}
          </span>
          <button
            onClick={() => setPage((current) => Math.min(totalPages, current + 1))}
            disabled={page === totalPages}
            className="rounded-lg border px-3 py-1.5 text-sm disabled:opacity-40"
          >
            Sonraki →
          </button>
        </div>
      ) : null}
    </div>
  )
}
