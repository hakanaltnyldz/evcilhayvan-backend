import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  ArrowTrendingUpIcon,
  ChartBarIcon,
  CubeIcon,
  ExclamationTriangleIcon,
  ReceiptPercentIcon,
  ShoppingCartIcon,
} from '@heroicons/react/24/outline'
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import api from '../../api.js'
import StatCard from '../../components/StatCard.jsx'
import { getSessionUser } from '../../lib/session.js'

const quickLinks = [
  { to: '/seller/products', title: 'Urunleri yonet', icon: CubeIcon },
  { to: '/seller/orders', title: 'Siparis akisina git', icon: ShoppingCartIcon },
  { to: '/seller/coupons', title: 'Kupon panelini ac', icon: ReceiptPercentIcon },
]

export default function SellerDashboard() {
  const user = getSessionUser() || {}
  const [stats, setStats] = useState(null)
  const [orderStats, setOrderStats] = useState(null)
  const [chartData, setChartData] = useState([])
  const [recentOrders, setRecentOrders] = useState([])
  const [storeName, setStoreName] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let mounted = true

    async function load() {
      try {
        const [statsResponse, orderStatsResponse, chartResponse, ordersResponse, storeResponse] =
          await Promise.allSettled([
            api.get('/seller/stats'),
            api.get('/seller/orders/stats'),
            api.get('/seller/orders/chart'),
            api.get('/seller/orders', { params: { limit: 5 } }),
            api.get('/store/me'),
          ])

        if (!mounted) return

        if (statsResponse.status === 'fulfilled') {
          setStats(statsResponse.value.data?.stats || statsResponse.value.data || null)
        }

        if (orderStatsResponse.status === 'fulfilled') {
          setOrderStats(orderStatsResponse.value.data?.stats || orderStatsResponse.value.data || null)
        }

        if (chartResponse.status === 'fulfilled') {
          const rawChart = chartResponse.value.data?.chart || chartResponse.value.data?.data || []
          setChartData(rawChart.map((item) => ({
            ...item,
            shortMonth: formatMonth(item.month),
          })))
        }

        if (ordersResponse.status === 'fulfilled') {
          setRecentOrders(ordersResponse.value.data?.orders || [])
        }

        if (storeResponse.status === 'fulfilled') {
          setStoreName(storeResponse.value.data?.store?.name || '')
        }
      } finally {
        if (mounted) setLoading(false)
      }
    }

    load()
    return () => {
      mounted = false
    }
  }, [])

  return (
    <div className="space-y-6">
      <section className="grid gap-6 xl:grid-cols-[1.3fr_0.7fr]">
        <div className="rounded-[32px] bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 p-7 text-white shadow-panel">
          <span className="inline-flex rounded-full border border-white/10 bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-primary-100">
            Seller Workspace
          </span>
          <h2 className="mt-4 text-3xl font-black tracking-tight">
            {`Magaza paneline hos geldin${user.name ? `, ${user.name.split(' ')[0]}` : ''}.`}
          </h2>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-primary-100">
            Urunler, siparisler, kuponlar ve analitik artik ayni panelde. Ayrica seller
            tarafindaki kirik veri akislarini bu workspace ile birlikte duzelttim.
          </p>

          <div className="mt-8 grid gap-4 md:grid-cols-3">
            <HeroMetric label="Magaza" value={storeName || 'Hazir'} />
            <HeroMetric label="Bu Ay Gelir" value={formatCurrency(orderStats?.revenueThisMonth)} />
            <HeroMetric label="Bekleyen Siparis" value={(orderStats?.pendingOrders ?? orderStats?.pending ?? 0).toLocaleString('tr-TR')} />
          </div>
        </div>

        <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">
            Hizli Erisim
          </p>
          <div className="mt-4 space-y-3">
            {quickLinks.map(({ to, title, icon: Icon }) => (
              <Link
                key={to}
                to={to}
                className="flex items-center gap-4 rounded-3xl border border-slate-100 bg-slate-50 px-4 py-4 text-sm font-semibold text-slate-800 transition hover:border-primary-100 hover:bg-primary-50"
              >
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary-600 text-white">
                  <Icon className="h-5 w-5" />
                </div>
                <span>{title}</span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Toplam Urun"
          value={stats?.totalProducts}
          loading={loading}
          color="green"
          icon={<CubeIcon className="h-6 w-6" />}
          subtitle="Katalogtaki toplam urun sayisi"
        />
        <StatCard
          title="Aktif Urun"
          value={stats?.activeProducts}
          loading={loading}
          color="blue"
          icon={<ChartBarIcon className="h-6 w-6" />}
          subtitle="Vitrinde yayinda olan urunler"
        />
        <StatCard
          title="Stok Riski"
          value={stats?.lowStock || stats?.outOfStock}
          loading={loading}
          color="orange"
          icon={<ExclamationTriangleIcon className="h-6 w-6" />}
          subtitle="Dusuk veya bitmis stoklar"
        />
        <StatCard
          title="Toplam Ciro"
          value={formatCurrency(orderStats?.totalRevenue)}
          loading={loading}
          color="purple"
          icon={<ArrowTrendingUpIcon className="h-6 w-6" />}
          subtitle={`${(orderStats?.totalOrders || 0).toLocaleString('tr-TR')} siparis uzerinden`}
        />
      </section>

      <section className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
          <div className="mb-5 flex items-center justify-between gap-4">
            <div>
              <h3 className="text-lg font-bold text-slate-900">Son 6 Ay Geliri</h3>
              <p className="mt-1 text-sm text-slate-500">Aylik ciro trendini buradan izleyin.</p>
            </div>
            <Link to="/seller/analytics" className="text-sm font-semibold text-primary-700">
              Detayli analiz
            </Link>
          </div>

          {loading ? (
            <div className="h-72 animate-pulse rounded-3xl bg-slate-100" />
          ) : chartData.length === 0 ? (
            <EmptyPanel text="Grafik gosterilecek veri henuz olusmadi." />
          ) : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={chartData} barSize={28}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="shortMonth" tick={{ fill: '#64748b', fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis
                  tick={{ fill: '#64748b', fontSize: 12 }}
                  axisLine={false}
                  tickLine={false}
                  tickFormatter={(value) => `${Math.round(value / 1000)}K`}
                />
                <Tooltip
                  formatter={(value) => [formatCurrency(value), 'Gelir']}
                  contentStyle={{ borderRadius: 16, border: 'none', boxShadow: '0 20px 40px rgba(15, 23, 42, 0.12)' }}
                />
                <Bar dataKey="revenue" fill="#2D6A4F" radius={[10, 10, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
          <div className="mb-5 flex items-center justify-between gap-4">
            <div>
              <h3 className="text-lg font-bold text-slate-900">Son Siparisler</h3>
              <p className="mt-1 text-sm text-slate-500">Kritik siparisleri hizli izleyin.</p>
            </div>
            <Link to="/seller/orders" className="text-sm font-semibold text-primary-700">
              Tumunu gor
            </Link>
          </div>

          {loading ? (
            <div className="space-y-3">
              {Array.from({ length: 4 }).map((_, index) => (
                <div key={index} className="h-16 animate-pulse rounded-3xl bg-slate-100" />
              ))}
            </div>
          ) : recentOrders.length === 0 ? (
            <EmptyPanel text="Henuz siparis kaydi yok." />
          ) : (
            <div className="space-y-3">
              {recentOrders.map((order) => (
                <div key={order._id} className="rounded-3xl border border-slate-100 bg-slate-50 px-4 py-4">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold text-slate-900">
                        {order.user?.name || 'Musteri'}
                      </p>
                      <p className="mt-1 text-xs text-slate-500">
                        {new Date(order.createdAt).toLocaleDateString('tr-TR')}
                      </p>
                    </div>
                    <span className="rounded-full bg-primary-50 px-2.5 py-1 text-xs font-semibold text-primary-700">
                      {order.status}
                    </span>
                  </div>
                  <div className="mt-3 flex items-center justify-between text-sm">
                    <span className="text-slate-500">{order.items?.length || 0} urun</span>
                    <span className="font-bold text-primary-700">
                      {formatCurrency(order.sellerTotal ?? order.totalAmount)}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  )
}

function HeroMetric({ label, value }) {
  return (
    <div className="rounded-[26px] border border-white/10 bg-white/8 p-4">
      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary-100">{label}</p>
      <p className="mt-3 text-2xl font-black text-white">{value}</p>
    </div>
  )
}

function EmptyPanel({ text }) {
  return (
    <div className="flex h-72 items-center justify-center rounded-3xl border border-dashed border-slate-200 bg-slate-50 text-sm text-slate-400">
      {text}
    </div>
  )
}

function formatMonth(value) {
  if (!value) return '—'
  const [year, month] = String(value).split('-')
  const date = new Date(Number(year), Number(month) - 1, 1)
  return date.toLocaleDateString('tr-TR', { month: 'short' })
}

function formatCurrency(value) {
  if (value == null || Number.isNaN(Number(value))) return '—'
  return `₺${Number(value).toLocaleString('tr-TR', { maximumFractionDigits: 0 })}`
}
