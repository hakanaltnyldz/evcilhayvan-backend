import { useEffect, useState } from 'react'
import api from '../api.js'
import Table from '../components/Table.jsx'

export default function Posts() {
  const [posts, setPosts] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [toggling, setToggling] = useState(null)

  useEffect(() => {
    setLoading(true)
    api.get('/admin/posts', { params: { page } })
      .then((res) => {
        setPosts(res.data?.data?.posts || [])
        setTotal(res.data?.data?.total || 0)
      })
      .finally(() => setLoading(false))
  }, [page])

  async function toggleVisibility(post) {
    setToggling(post._id)
    try {
      const res = await api.patch(`/admin/posts/${post._id}/hide`)
      const updated = res.data?.data?.post
      setPosts((prev) =>
        prev.map((p) => (p._id === post._id ? { ...p, isActive: updated.isActive } : p))
      )
    } catch (err) {
      alert(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setToggling(null)
    }
  }

  const columns = [
    {
      key: 'user',
      label: 'Kullanıcı',
      render: (r) => r.userId?.name || r.userName || '—',
    },
    {
      key: 'content',
      label: 'İçerik',
      render: (r) =>
        r.content ? (
          <span className="text-gray-700">{r.content.slice(0, 80)}{r.content.length > 80 ? '…' : ''}</span>
        ) : (
          <span className="text-gray-400 italic">Sadece fotoğraf</span>
        ),
    },
    {
      key: 'photos',
      label: 'Foto',
      render: (r) => Array.isArray(r.photos) ? r.photos.length : 0,
    },
    {
      key: 'likes',
      label: '❤️',
      render: (r) => Array.isArray(r.likes) ? r.likes.length : 0,
    },
    {
      key: 'comments',
      label: '💬',
      render: (r) => Array.isArray(r.comments) ? r.comments.length : 0,
    },
    {
      key: 'isActive',
      label: 'Durum',
      render: (r) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${r.isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'}`}>
          {r.isActive ? 'Yayında' : 'Gizli'}
        </span>
      ),
    },
    {
      key: 'createdAt',
      label: 'Tarih',
      render: (r) =>
        r.createdAt ? new Date(r.createdAt).toLocaleDateString('tr-TR') : '—',
    },
    {
      key: 'actions',
      label: '',
      render: (r) => (
        <button
          onClick={() => toggleVisibility(r)}
          disabled={toggling === r._id}
          className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
            r.isActive
              ? 'bg-red-100 text-red-600 hover:bg-red-200'
              : 'bg-green-100 text-green-700 hover:bg-green-200'
          }`}
        >
          {toggling === r._id ? '...' : r.isActive ? 'Gizle' : 'Göster'}
        </button>
      ),
    },
  ]

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Gönderiler</h1>
        <span className="text-sm text-gray-500">{total} gönderi</span>
      </div>

      <div className="bg-white rounded-2xl shadow-sm p-4">
        <Table columns={columns} rows={posts} loading={loading} emptyText="Gönderi bulunamadı" />
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
