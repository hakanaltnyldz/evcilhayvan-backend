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
    </div>
  )
}
