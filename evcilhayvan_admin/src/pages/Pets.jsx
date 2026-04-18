import { useEffect, useState, useRef } from 'react'
import api from '../api.js'
import Table from '../components/Table.jsx'
import toast from 'react-hot-toast'

export default function Pets() {
  const [pets, setPets] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [type, setType] = useState('all')
  const [search, setSearch] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const [loading, setLoading] = useState(true)
  const [toggling, setToggling] = useState(null)
  const [editPet, setEditPet] = useState(null)
  const [editForm, setEditForm] = useState({})
  const [saving, setSaving] = useState(false)
  const debounceRef = useRef(null)

  useEffect(() => {
    setLoading(true)
    const params = { page, type: type === 'all' ? undefined : type }
    if (search) params.q = search
    api.get('/admin/pets', { params })
      .then((res) => {
        setPets(res.data?.pets || [])
        setTotal(res.data?.total || 0)
      })
      .finally(() => setLoading(false))
  }, [page, type, search])

  function handleSearchChange(e) {
    const val = e.target.value
    setSearchInput(val)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => {
      setSearch(val)
      setPage(1)
    }, 400)
  }

  async function toggleActive(pet) {
    setToggling(pet._id)
    try {
      const res = await api.patch(`/admin/pets/${pet._id}/toggle`)
      const updated = res.data?.pet
      setPets((prev) =>
        prev.map((p) => (p._id === pet._id ? { ...p, isActive: updated.isActive } : p))
      )
      toast.success(updated.isActive ? 'İlan aktifleştirildi' : 'İlan devre dışı bırakıldı')
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setToggling(null)
    }
  }

  function openEdit(pet) {
    setEditPet(pet)
    setEditForm({
      name: pet.name || '',
      species: pet.species || '',
      breed: pet.breed || '',
      gender: pet.gender || '',
      ageMonths: pet.ageMonths ?? '',
      description: pet.description || '',
      isActive: pet.isActive,
    })
  }

  async function saveEdit(e) {
    e.preventDefault()
    setSaving(true)
    try {
      const res = await api.patch(`/admin/pets/${editPet._id}`, editForm)
      const updated = res.data?.pet
      setPets((prev) => prev.map((p) => (p._id === editPet._id ? { ...p, ...updated } : p)))
      toast.success('İlan güncellendi')
      setEditPet(null)
    } catch (err) {
      toast.error(err.response?.data?.message || 'Güncelleme başarısız')
    } finally {
      setSaving(false)
    }
  }

  const columns = [
    { key: 'name', label: 'Hayvan' },
    { key: 'species', label: 'Tür' },
    { key: 'breed', label: 'Irk' },
    { key: 'gender', label: 'Cinsiyet' },
    { key: 'advertType', label: 'İlan Türü', render: (p) => (
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
      <div className="flex gap-2">
        <button
          onClick={() => openEdit(p)}
          className="px-3 py-1 rounded-lg text-xs font-semibold bg-blue-100 text-blue-700 hover:bg-blue-200 transition-colors"
        >
          Düzenle
        </button>
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
      </div>
    )},
  ]

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">İlanlar</h1>
        <span className="text-sm text-gray-500">{total} ilan</span>
      </div>

      <div className="flex flex-wrap gap-3 mb-6 items-center">
        <div className="flex gap-2">
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
        <input
          type="text"
          value={searchInput}
          onChange={handleSearchChange}
          placeholder="İsim veya sahip ara..."
          className="ml-auto px-4 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 w-56"
        />
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

      {/* Edit Modal */}
      {editPet && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg">
            <div className="flex items-center justify-between p-6 border-b">
              <h2 className="text-lg font-bold text-gray-800">İlan Düzenle</h2>
              <button onClick={() => setEditPet(null)} className="text-gray-400 hover:text-gray-600 text-2xl leading-none">&times;</button>
            </div>
            <form onSubmit={saveEdit} className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Ad</label>
                  <input
                    className="w-full border rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    value={editForm.name}
                    onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                    placeholder="Hayvan adı"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Tür</label>
                  <select
                    className="w-full border rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    value={editForm.species}
                    onChange={(e) => setEditForm({ ...editForm, species: e.target.value })}
                  >
                    <option value="">Seç...</option>
                    {['kedi', 'köpek', 'kuş', 'balık', 'hamster', 'tavşan', 'diğer'].map((s) => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Irk</label>
                  <input
                    className="w-full border rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    value={editForm.breed}
                    onChange={(e) => setEditForm({ ...editForm, breed: e.target.value })}
                    placeholder="Irk"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Cinsiyet</label>
                  <select
                    className="w-full border rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    value={editForm.gender}
                    onChange={(e) => setEditForm({ ...editForm, gender: e.target.value })}
                  >
                    <option value="">Seç...</option>
                    <option value="erkek">Erkek</option>
                    <option value="dişi">Dişi</option>
                    <option value="bilinmiyor">Bilinmiyor</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Yaş (ay)</label>
                  <input
                    type="number"
                    min="0"
                    className="w-full border rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    value={editForm.ageMonths}
                    onChange={(e) => setEditForm({ ...editForm, ageMonths: e.target.value })}
                    placeholder="Ay cinsinden yaş"
                  />
                </div>
                <div className="flex items-center gap-3 pt-6">
                  <input
                    type="checkbox"
                    id="isActive"
                    checked={editForm.isActive}
                    onChange={(e) => setEditForm({ ...editForm, isActive: e.target.checked })}
                    className="w-4 h-4 rounded border-gray-300 text-indigo-600"
                  />
                  <label htmlFor="isActive" className="text-sm font-medium text-gray-700">Aktif</label>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Açıklama</label>
                <textarea
                  rows={3}
                  className="w-full border rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                  value={editForm.description}
                  onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
                  placeholder="Açıklama"
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setEditPet(null)}
                  className="px-4 py-2 rounded-xl border text-sm font-medium text-gray-600 hover:bg-gray-50"
                >
                  İptal
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 disabled:opacity-50"
                >
                  {saving ? 'Kaydediliyor...' : 'Kaydet'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
