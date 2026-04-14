import { useEffect, useState } from 'react'
import api from '../api.js'
import toast from 'react-hot-toast'

export default function Vets() {
  const [vets, setVets] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [fetchingPhotos, setFetchingPhotos] = useState(null)
  const [verifying, setVerifying] = useState(null)

  useEffect(() => {
    setLoading(true)
    api.get('/admin/vets', { params: { page } })
      .then((res) => {
        setVets(res.data?.vets || [])
        setTotal(res.data?.total || 0)
      })
      .catch(() => toast.error('Veterinerler yüklenemedi'))
      .finally(() => setLoading(false))
  }, [page])

  async function fetchPhotos(vet) {
    const vid = vet.id || vet._id
    setFetchingPhotos(vid)
    try {
      const res = await api.post(`/veterinaries/${vid}/fetch-photos`)
      setVets((prev) =>
        prev.map((v) => (v.id || v._id) === vid ? { ...v, photos: res.data?.photos || v.photos } : v)
      )
      toast.success(res.data?.message || 'Fotoğraflar güncellendi')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Fotoğraf çekilemedi')
    } finally {
      setFetchingPhotos(null)
    }
  }

  async function toggleVerify(vet) {
    const vid = vet.id || vet._id
    setVerifying(vid)
    try {
      const res = await api.patch(`/admin/vets/${vid}/verify`, { isVerified: !vet.isVerified })
      const updated = res.data?.vet
      setVets((prev) =>
        prev.map((v) => (v.id || v._id) === vid ? { ...v, isVerified: updated?.isVerified } : v)
      )
      toast.success(updated?.isVerified ? 'Veteriner doğrulandı' : 'Doğrulama kaldırıldı')
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setVerifying(null)
    }
  }

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Veteriner Klinikleri</h1>
        <span className="text-sm text-gray-500">{total} klinik</span>
      </div>

      {loading ? (
        <div className="text-center py-16 text-gray-400">Yükleniyor...</div>
      ) : (
        <div className="space-y-3">
          {vets.map((vet) => (
            <div key={vet.id || vet._id} className="bg-white rounded-2xl shadow-sm p-4 flex items-center gap-4">
              {/* Fotoğraf */}
              <div className="w-14 h-14 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
                {vet.photos?.[0] ? (
                  <img src={vet.photos[0]} alt={vet.name} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-2xl">🏥</div>
                )}
              </div>

              {/* Bilgi */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-semibold text-gray-800 truncate">{vet.name}</span>
                  {vet.isVerified && (
                    <span className="px-2 py-0.5 rounded-full text-xs bg-green-100 text-green-700 font-medium">
                      ✓ Doğrulanmış
                    </span>
                  )}
                  {vet.userId && (
                    <span className="px-2 py-0.5 rounded-full text-xs bg-blue-100 text-blue-700 font-medium">
                      Sahiplenildi
                    </span>
                  )}
                  {vet.googlePlaceId && (
                    <span className="px-2 py-0.5 rounded-full text-xs bg-yellow-100 text-yellow-700 font-medium">
                      Google
                    </span>
                  )}
                </div>
                <p className="text-sm text-gray-500 truncate mt-0.5">{vet.address || '—'}</p>
                <p className="text-xs text-gray-400">
                  {vet.photos?.length || 0} fotoğraf
                  {vet.googleRating ? ` · ⭐ ${vet.googleRating} (${vet.googleReviewCount})` : ''}
                </p>
              </div>

              {/* Aksiyonlar */}
              <div className="flex items-center gap-2 flex-shrink-0">
                <button
                  onClick={() => fetchPhotos(vet)}
                  disabled={fetchingPhotos === (vet.id || vet._id)}
                  title="Google'dan fotoğraf çek"
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-yellow-50 text-yellow-700 hover:bg-yellow-100 transition-colors disabled:opacity-50"
                >
                  {fetchingPhotos === (vet.id || vet._id) ? '...' : '📷 Fotoğraf'}
                </button>
                <button
                  onClick={() => toggleVerify(vet)}
                  disabled={verifying === (vet.id || vet._id)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors disabled:opacity-50 ${
                    vet.isVerified
                      ? 'bg-gray-100 text-gray-600 hover:bg-red-50 hover:text-red-600'
                      : 'bg-green-50 text-green-700 hover:bg-green-100'
                  }`}
                >
                  {verifying === (vet.id || vet._id) ? '...' : vet.isVerified ? 'Doğrulamayı Kaldır' : 'Doğrula'}
                </button>
              </div>
            </div>
          ))}

          {vets.length === 0 && (
            <div className="text-center py-16 text-gray-400">Veteriner bulunamadı</div>
          )}
        </div>
      )}

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
