import { useEffect, useState } from 'react'
import api from '../api.js'
import Table from '../components/Table.jsx'

export default function Pets() {
  const [pets, setPets] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [type, setType] = useState('all')
  const [loading, setLoading] = useState(true)
  const [toggling, setToggling] = useState(null)

  useEffect(() => {
    setLoading(true)
    api.get('/admin/pets', { params: { page, type: type === 'all' ? undefined : type } })
      .then((res) => {
        setPets(res.data?.pets || [])
        setTotal(res.data?.total || 0)
      })
      .finally(() => setLoading(false))
  }, [page, type])

  async function toggleActive(pet) {
    setToggling(pet._id)
    try {
      const res = await api.patch(`/admin/pets/${pet._id}/toggle`)
      const updated = res.data?.pet
      setPets((prev) =>
        prev.map((p) => (p._id === pet._id ? { ...p, isActive: updated.isActive } : p))
      )
    } catch (err) {
      alert(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setToggling(null)
    }
  }

  const columns = [
    { key: 'name', label: 'Hayvan' },
    { key: 'species', label: 'Tür' },
    { key: 'breed', label: 'Irk' },
    { key: 'gender', label: 'Cinsiyet' },
    { key: 'advertType', label: 'Tür', render: (p) => (
      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
        p.advertType === 'adoption' ? 'bg-green-100 text-green-700' : 'bg-pink-100 text-pink-700'
      }`}>{p.advertType === 'adoption' ? 'Sahiplendirme' : 'Eşleştirme'}</span>
    )},
    { key: 'isActive', label: 'Durum', render: (p) => (
      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
        p.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
      }`}>{p.isActive ? 'Aktif' : 'Pasif'}</span>
    )},
    { key: 'owner', label: 'Sahip', render: (p) => p.ownerId?.name || '—' },
    { key: 'createdAt', label: 'Tarih', render: (p) =>
      p.createdAt ? new Date(p.createdAt).toLocaleDateString('tr-TR') : '—'
    },
    { key: 'actions', label: '', render: (p) => (
      <button
        onClick={() => toggleActive(p)}
        disabled={toggling === p._id}
        className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
          p.isActive
            ? 'bg-red-100 text-red-700 hover:bg-red-200'
            : 'bg-green-100 text-green-700 hover:bg-green-200'
        }`}
      >
        {toggling === p._id ? '...' : p.isActive ? 'Devre Dışı' : 'Aktifleştir'}
      </button>
    )},
  ]

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">İlanlar</h1>
        <span className="text-sm text-gray-500">{total} ilan</span>
      </div>

      <div className="flex gap-2 mb-6">
        {[['all', 'Tümü'], ['adoption', 'Sahiplendirme'], ['mating', 'Eşleştirme']].map(([val, label]) => (
          <button
            key={val}
            onClick={() => { setType(val); setPage(1) }}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-colors ${
              type === val
                ? 'bg-indigo-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-2xl shadow-sm p-4">
        <Table columns={columns} rows={pets} loading={loading} emptyText="İlan bulunamadı" />
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
