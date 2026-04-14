import { useEffect, useState } from 'react'
import {
  ArrowTrendingUpIcon,
  CheckCircleIcon,
  CurrencyDollarIcon,
  ShoppingCartIcon,
} from '@heroicons/react/24/outline'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import api from '../../api.js'

const statusLabels = {
  pending: 'Bekliyor',
  processing: 'Hazirlaniyor',
  shipped: 'Kargoda',
  delivered: 'Teslim',
  cancelled: 'Iptal',
}

const pieColors = ['#F59E0B', '#3B82F6', '#8B5CF6', '#10B981', '#EF4444']

export default function SellerAnalytics() {
  const [orderStats, setOrderStats] = useState(null)
  const [chartData, setChartData] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let mounted = true

    async function load() {
      try {
        const [chartResponse, statsResponse] = await Promise.allSettled([
          api.get('/seller/orders/chart'),
          api.get('/seller/orders/stats'),
        ])

        if (!mounted) return

        if (chartResponse.status === 'fulfilled') {
          const rawChart = chartResponse.value.data?.chart || chartResponse.value.data?.data || []
          setChartData(rawChart.map((item) => ({
            ...item,
            shortMonth: formatMonth(item.month),
          })))
        }

        if (statsResponse.status === 'fulfilled') {
          setOrderStats(statsResponse.value.data?.stats || statsResponse.value.data || null)
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

  const pieData = Object.entries(statusLabels)
    .map(([key, label]) => ({
      name: label,
      value: orderStats?.[key] ?? orderStats?.[`${key}Orders`] ?? 0,
    }))
    .filter((item) => item.value > 0)

  return (
    <div className="space-y-6">
      <div className="rounded-[32px] bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 p-6 text-white shadow-panel">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-primary-100">Analitik</p>
        <h2 className="mt-2 text-3xl font-black">Satis ve siparis performansi</h2>
        <p className="mt-2 max-w-3xl text-sm leading-7 text-primary-100">
          Seller panelinde onceden eksik kalan grafik ve metrikleri backend ile hizaladik.
          Bu ekran aylik gelir, siparis dagilimi ve en cok satan urunleri tek yerde gosterir.
        </p>
      </div>

      <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        <SummaryCard title="Bu Ay Gelir" value={formatCurrency(orderStats?.revenueThisMonth)} icon={<CurrencyDollarIcon className="h-5 w-5" />} loading={loading} />
        <SummaryCard title="Toplam Siparis" value={(orderStats?.totalOrders ?? 0).toLocaleString('tr-TR')} icon={<ShoppingCartIcon className="h-5 w-5" />} loading={loading} />
        <SummaryCard title="Teslim Edilen" value={(orderStats?.deliveredOrders ?? orderStats?.delivered ?? 0).toLocaleString('tr-TR')} icon={<CheckCircleIcon className="h-5 w-5" />} loading={loading} />
        <SummaryCard title="Ortalama Sepet" value={formatCurrency(orderStats?.averageOrderValue)} icon={<ArrowTrendingUpIcon className="h-5 w-5" />} loading={loading} />
      </section>

      <section className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <ChartCard title="Aylik Gelir">
          {loading ? (
            <LoadingChart />
          ) : chartData.length === 0 ? (
            <EmptyChart text="Grafik verisi henuz olusmadi." />
          ) : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={chartData} barSize={28}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="shortMonth" tick={{ fill: '#64748b', fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: '#64748b', fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip
                  formatter={(value) => [formatCurrency(value), 'Gelir']}
                  contentStyle={{ borderRadius: 16, border: 'none', boxShadow: '0 20px 40px rgba(15, 23, 42, 0.12)' }}
                />
                <Bar dataKey="revenue" fill="#2D6A4F" radius={[10, 10, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        <ChartCard title="Siparis Dagilimi">
          {loading ? (
            <LoadingChart />
          ) : pieData.length === 0 ? (
            <EmptyChart text="Dagilim grafigi icin veri yok." />
          ) : (
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie data={pieData} dataKey="value" nameKey="name" innerRadius={55} outerRadius={95} paddingAngle={4}>
                  {pieData.map((entry, index) => (
                    <Cell key={entry.name} fill={pieColors[index % pieColors.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ borderRadius: 16, border: 'none', boxShadow: '0 20px 40px rgba(15, 23, 42, 0.12)' }} />
                <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          )}
        </ChartCard>
      </section>

      <section className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
        <div className="mb-5">
          <h3 className="text-lg font-bold text-slate-900">En cok satan urunler</h3>
          <p className="mt-1 text-sm text-slate-500">Toplam satis adedi ve tahmini ciroya gore listelenir.</p>
        </div>

        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 5 }).map((_, index) => (
              <div key={index} className="h-16 animate-pulse rounded-3xl bg-slate-100" />
            ))}
          </div>
        ) : !orderStats?.topProducts?.length ? (
          <EmptyChart text="En cok satan urun verisi bulunamadi." compact />
        ) : (
          <div className="space-y-3">
            {orderStats.topProducts.map((product, index) => (
              <div key={product._id || `${product.name}-${index}`} className="flex items-center gap-4 rounded-3xl bg-slate-50 px-4 py-4">
                <span className="w-7 text-center text-sm font-black text-primary-700">#{index + 1}</span>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-semibold text-slate-900">{product.name || product.title}</p>
                  <p className="mt-1 text-xs text-slate-500">{product.totalSold || 0} adet satis</p>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-primary-700">{formatCurrency(product.revenue)}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}

function SummaryCard({ title, value, icon, loading }) {
  return (
    <div className="rounded-[28px] border border-white bg-white p-5 shadow-panel">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-sm font-medium text-slate-500">{title}</p>
          {loading ? (
            <div className="mt-3 h-8 w-20 animate-pulse rounded-xl bg-slate-100" />
          ) : (
            <p className="mt-3 text-3xl font-black text-slate-900">{value}</p>
          )}
        </div>
        <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary-50 text-primary-700">
          {icon}
        </div>
      </div>
    </div>
  )
}

function ChartCard({ title, children }) {
  return (
    <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
      <h3 className="text-lg font-bold text-slate-900">{title}</h3>
      <div className="mt-5">{children}</div>
    </div>
  )
}

function LoadingChart() {
  return <div className="h-72 animate-pulse rounded-3xl bg-slate-100" />
}

function EmptyChart({ text, compact = false }) {
  return (
    <div className={`flex items-center justify-center rounded-3xl border border-dashed border-slate-200 bg-slate-50 text-sm text-slate-400 ${compact ? 'h-40' : 'h-72'}`}>
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
