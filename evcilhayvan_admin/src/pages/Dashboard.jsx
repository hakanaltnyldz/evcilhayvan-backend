import { useEffect, useState } from 'react'
import api from '../api.js'
import StatCard from '../components/StatCard.jsx'

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    api.get('/admin/stats')
      .then((res) => setStats(res.data?.stats))
      .catch((err) => setError(err.response?.data?.message || 'İstatistikler alınamadı'))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return (
    <div className="flex justify-center items-center h-64 text-gray-400">
      <span className="animate-spin text-3xl">⏳</span>
    </div>
  )

  if (error) return (
    <div className="bg-red-50 text-red-600 rounded-2xl p-6">{error}</div>
  )

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        <StatCard title="Toplam Kullanıcı" value={stats?.totalUsers} icon="👥" color="indigo" />
        <StatCard title="Bu Ay Yeni Üye" value={stats?.newUsersThisMonth} icon="🆕" color="green" />
        <StatCard title="Toplam İlan" value={stats?.totalPets} icon="🐾" color="purple" />
        <StatCard title="Aktif İlan" value={stats?.activePets} icon="✅" color="blue" />
        <StatCard title="Toplam Sipariş" value={stats?.totalOrders} icon="🛒" color="orange" />
        <StatCard title="Bekleyen Şikayet" value={stats?.pendingReports} icon="⚠️" color="red" />
        <StatCard title="Aktif Kupon" value={stats?.totalActiveCoupons} icon="🎟️" color="purple" />
        <StatCard title="Açık Destek" value={stats?.openSupportTickets} icon="🎫" color="yellow" />
      </div>
    </div>
  )
}
