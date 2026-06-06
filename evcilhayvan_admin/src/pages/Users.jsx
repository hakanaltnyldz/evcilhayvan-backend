import { useEffect, useState } from 'react'
import api from '../api.js'
import Table from '../components/Table.jsx'
import toast from 'react-hot-toast'

export default function Users() {
  const [users, setUsers] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [q, setQ] = useState('')
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [banning, setBanning] = useState(null)
  const [changingRole, setChangingRole] = useState(null)
  const [deleting, setDeleting] = useState(null)
  const [sensitiveModal, setSensitiveModal] = useState(null)

  useEffect(() => {
    setLoading(true)
    api.get('/admin/users', { params: { page, q: search } })
      .then((res) => {
        setUsers(res.data?.users || [])
        setTotal(res.data?.total || 0)
      })
      .finally(() => setLoading(false))
  }, [page, search])

  async function toggleBan(user) {
    const uid = user.id || user._id
    const nextAction = user.role === 'banned' ? 'banini kaldirmak' : 'banlamak'
    if (!window.confirm(`"${user.name}" kullanicisini ${nextAction} istiyor musunuz?`)) return
    setBanning(uid)
    try {
      const res = await api.patch(`/admin/users/${uid}/ban`)
      const updated = res.data?.user
      setUsers((prev) =>
        prev.map((u) => ((u.id || u._id) === uid ? { ...u, role: updated.role } : u))
      )
      toast.success(updated.role === 'banned' ? 'Kullanıcı banlandı' : 'Ban kaldırıldı')
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setBanning(null)
    }
  }

  async function changeRole(user, role) {
    const uid = user.id || user._id
    if (role === (user.role === 'banned' ? 'user' : user.role)) return
    if (!window.confirm(`"${user.name}" kullanicisinin rolunu "${role}" yapmak istiyor musunuz?`)) return
    setChangingRole(uid)
    try {
      const res = await api.patch(`/admin/users/${uid}/role`, { role })
      const updated = res.data?.user
      setUsers((prev) => prev.map((u) => (u.id || u._id) === uid ? { ...u, role: updated.role } : u))
      toast.success(`Rol güncellendi: ${updated.role}`)
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setChangingRole(null)
    }
  }

  async function deleteUser(user) {
    const uid = user.id || user._id
    if (!window.confirm(`"${user.name}" kullanıcısını kalıcı olarak silmek istiyor musunuz?`)) return
    setDeleting(uid)
    try {
      await api.delete(`/admin/users/${uid}`)
      setUsers((prev) => prev.filter((u) => (u.id || u._id) !== uid))
      setTotal((t) => t - 1)
      toast.success('Kullanıcı silindi')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Silme başarısız')
    } finally {
      setDeleting(null)
    }
  }

  function handleSearch(e) {
    e.preventDefault()
    setSearch(q)
    setPage(1)
  }

  function openSensitiveModal(user) {
    setSensitiveModal({
      user,
      password: '',
      data: null,
      loading: false,
      error: '',
    })
  }

  async function fetchSensitiveData(event) {
    event.preventDefault()
    if (!sensitiveModal?.user || !sensitiveModal.password.trim()) {
      setSensitiveModal((current) => current ? { ...current, error: 'Ek veri sifresi gerekli' } : current)
      return
    }

    const uid = sensitiveModal.user.id || sensitiveModal.user._id
    setSensitiveModal((current) => current ? { ...current, loading: true, error: '' } : current)
    try {
      const response = await api.get(`/admin/users/${uid}/sensitive`, {
        headers: { 'x-admin-data-password': sensitiveModal.password },
      })
      setSensitiveModal((current) =>
        current ? { ...current, data: response.data || {}, loading: false, password: '' } : current
      )
    } catch (error) {
      setSensitiveModal((current) =>
        current
          ? {
              ...current,
              loading: false,
              error: error.response?.data?.message || 'Hassas veri acilamadi',
            }
          : current
      )
    }
  }

  const columns = [
    { key: 'name', label: 'Ad' },
    { key: 'email', label: 'E-posta' },
    { key: 'role', label: 'Rol', render: (u) => (
      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
        u.role === 'banned' ? 'bg-red-100 text-red-700'
          : u.role === 'admin' ? 'bg-purple-100 text-purple-700'
          : u.role === 'seller' ? 'bg-blue-100 text-blue-700'
          : 'bg-gray-100 text-gray-700'
      }`}>{u.role}</span>
    )},
    { key: 'city', label: 'Şehir' },
    { key: 'createdAt', label: 'Kayıt', render: (u) =>
      u.createdAt ? new Date(u.createdAt).toLocaleDateString('tr-TR') : '—'
    },
    { key: 'actions', label: '', render: (u) => {
      const uid = u.id || u._id
      return (
      <div className="flex items-center gap-2">
        {u.role !== 'admin' && (
          <button
            onClick={() => toggleBan(u)}
            disabled={banning === uid}
            className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
              u.role === 'banned'
                ? 'bg-green-100 text-green-700 hover:bg-green-200'
                : 'bg-red-100 text-red-700 hover:bg-red-200'
            }`}
          >
            {banning === uid ? '...' : u.role === 'banned' ? 'Ban Kaldır' : 'Banla'}
          </button>
        )}
        <select
          value={u.role === 'banned' ? 'user' : u.role}
          disabled={changingRole === uid}
          onChange={(e) => changeRole(u, e.target.value)}
          className="text-xs border border-gray-200 rounded-lg px-2 py-1 bg-white focus:outline-none focus:ring-1 focus:ring-indigo-300 disabled:opacity-50"
        >
          <option value="user">user</option>
          <option value="seller">seller</option>
          <option value="vet">vet</option>
          <option value="admin">admin</option>
        </select>
        <button
          type="button"
          onClick={() => openSensitiveModal(u)}
          className="px-2 py-1 rounded-lg text-xs font-semibold bg-amber-50 text-amber-700 hover:bg-amber-100 transition-colors"
        >
          Hassas
        </button>
        {u.role !== 'admin' && (
          <button
            onClick={() => deleteUser(u)}
            disabled={deleting === uid}
            className="px-2 py-1 rounded-lg text-xs font-semibold bg-gray-100 text-gray-500 hover:bg-red-100 hover:text-red-600 transition-colors disabled:opacity-50"
            title="Kalıcı sil"
          >
            {deleting === uid ? '...' : '🗑️'}
          </button>
        )}
      </div>
      )
    }},
  ]

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Kullanıcılar</h1>
        <span className="text-sm text-gray-500">{total} kullanıcı</span>
      </div>

      <form onSubmit={handleSearch} className="flex gap-2 mb-6">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="İsim veya e-posta ara..."
          className="flex-1 px-4 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
        />
        <button type="submit" className="bg-indigo-600 text-white px-5 py-2 rounded-xl text-sm font-semibold hover:bg-indigo-700 transition-colors">
          Ara
        </button>
      </form>

      <div className="bg-white rounded-2xl shadow-sm p-4">
        <Table columns={columns} rows={users} loading={loading} emptyText="Kullanıcı bulunamadı" />
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

      {sensitiveModal ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4">
              <h2 className="text-lg font-bold text-slate-900">Hassas Kullanici Verisi</h2>
              <p className="mt-1 text-xs text-slate-500">
                {sensitiveModal.user?.name || sensitiveModal.user?.email || 'Kullanici'}
              </p>
            </div>

            {sensitiveModal.data ? (
              <div className="space-y-3">
                <SensitiveRow label="Telefon" value={sensitiveModal.data.phone} />
                <SensitiveRow label="TC Kimlik" value={sensitiveModal.data.nationalId} />
              </div>
            ) : (
              <form onSubmit={fetchSensitiveData} className="space-y-3">
                <div>
                  <label className="mb-1 block text-xs font-medium text-slate-600">
                    Ek veri sifresi
                  </label>
                  <input
                    type="password"
                    value={sensitiveModal.password}
                    onChange={(event) =>
                      setSensitiveModal((current) =>
                        current ? { ...current, password: event.target.value, error: '' } : current
                      )
                    }
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-200"
                    autoFocus
                  />
                </div>
                {sensitiveModal.error ? (
                  <p className="rounded-xl bg-red-50 px-3 py-2 text-xs font-semibold text-red-700">
                    {sensitiveModal.error}
                  </p>
                ) : null}
                <button
                  type="submit"
                  disabled={sensitiveModal.loading}
                  className="w-full rounded-xl bg-amber-600 py-2 text-sm font-semibold text-white hover:bg-amber-700 disabled:opacity-50"
                >
                  {sensitiveModal.loading ? 'Aciluyor...' : 'Veriyi Ac'}
                </button>
              </form>
            )}

            <button
              type="button"
              onClick={() => setSensitiveModal(null)}
              className="mt-4 w-full rounded-xl border border-slate-200 py-2 text-sm text-slate-600 hover:bg-slate-50"
            >
              Kapat
            </button>
          </div>
        </div>
      ) : null}
    </div>
  )
}

function SensitiveRow({ label, value }) {
  return (
    <div className="rounded-2xl bg-slate-50 px-4 py-3">
      <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">{label}</p>
      <p className="mt-1 font-mono text-sm font-semibold text-slate-900">{value || '-'}</p>
    </div>
  )
}
