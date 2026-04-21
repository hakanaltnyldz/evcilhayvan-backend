import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  ArrowTrendingUpIcon,
  ClipboardDocumentListIcon,
  CurrencyDollarIcon,
  LifebuoyIcon,
  PresentationChartBarIcon,
  ReceiptPercentIcon,
  ShieldCheckIcon,
  ShoppingCartIcon,
  UserGroupIcon,
} from '@heroicons/react/24/outline'
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import api from '../api.js'
import StatCard from '../components/StatCard.jsx'

const quickLinks = [
  {
    to: '/support',
    title: 'Destek Akisi',
    text: 'Acil destek taleplerini gor, not ekle ve durumu guncelle.',
    icon: LifebuoyIcon,
  },
  {
    to: '/seller-applications',
    title: 'Satici Basvurulari',
    text: 'Bekleyen satici taleplerini ayni gun icinde sonuclandir.',
    icon: ClipboardDocumentListIcon,
  },
  {
    to: '/orders',
    title: 'Siparis ve Iadeler',
    text: 'Kargo akislarini ve iade taleplerini tek panelden izle.',
    icon: PresentationChartBarIcon,
  },
]

const PRESETS = [
  { label: 'Tum Zamanlar', from: '', to: '' },
  {
    label: 'Bu Ay',
    from: new Date(
      new Date().getFullYear(),
      new Date().getMonth(),
      1
    )
      .toISOString()
      .slice(0, 10),
    to: new Date().toISOString().slice(0, 10),
  },
  {
    label: 'Son 7 Gun',
    from: new Date(Date.now() - 6 * 86400000).toISOString().slice(0, 10),
    to: new Date().toISOString().slice(0, 10),
  },
  {
    label: 'Son 30 Gun',
    from: new Date(Date.now() - 29 * 86400000).toISOString().slice(0, 10),
    to: new Date().toISOString().slice(0, 10),
  },
]

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [preset, setPreset] = useState(0)
  const [customFrom, setCustomFrom] = useState('')
  const [customTo, setCustomTo] = useState('')

  useEffect(() => {
    setLoading(true)
    setError('')
    const { from, to } =
      preset === -1 ? { from: customFrom, to: customTo } : PRESETS[preset]
    const params = {}
    if (from) params.from = from
    if (to) params.to = to

    api
      .get('/admin/stats', { params })
      .then((response) => setStats(response.data?.stats || null))
      .catch((requestError) => {
        setError(
          requestError.response?.data?.message || 'Istatistikler alinamadi'
        )
      })
      .finally(() => setLoading(false))
  }, [preset, customFrom, customTo])

  if (error) {
    return (
      <div className="rounded-[28px] border border-rose-200 bg-rose-50 p-6 text-rose-700">
        {error}
      </div>
    )
  }

  const scopeLabel = stats?.dateFilter
    ? `${stats.dateFilter.from} - ${stats.dateFilter.to}`
    : 'Tum zamanlar'

  return (
    <div className="space-y-6">
      <section className="grid gap-6 xl:grid-cols-[1.35fr_0.65fr]">
        <div className="rounded-[32px] bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 p-7 text-white shadow-panel">
          <div className="max-w-2xl">
            <span className="inline-flex rounded-full border border-white/10 bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-slate-200">
              Admin Analytics
            </span>
            <h2 className="mt-4 text-3xl font-black tracking-tight">
              Ticari akis, kullanici buyumesi ve operasyon yuku ayni tabloda.
            </h2>
            <p className="mt-4 max-w-xl text-sm leading-7 text-slate-300">
              Bu ekran artik yalnizca count gostermiyor. Gelir trendi, en cok
              satan urunler, user growth ve iade yogunlugu secilen donemle
              birlikte okunabiliyor.
            </p>
          </div>

          <div className="mt-8 grid gap-4 md:grid-cols-4">
            <MiniMetric
              label="Donem Geliri"
              value={formatCurrency(stats?.grossRevenue)}
              icon={CurrencyDollarIcon}
            />
            <MiniMetric
              label="Bekleyen Iade"
              value={stats?.pendingReturns}
              icon={ReceiptPercentIcon}
            />
            <MiniMetric
              label="Acik Destek"
              value={stats?.openSupportTickets}
              icon={LifebuoyIcon}
            />
            <MiniMetric
              label="Bekleyen Seller"
              value={stats?.pendingSellerApplications}
              icon={ClipboardDocumentListIcon}
            />
          </div>
        </div>

        <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">
            Hizli Erisim
          </p>
          <div className="mt-4 space-y-3">
            {quickLinks.map(({ to, title, text, icon: Icon }) => (
              <Link
                key={to}
                to={to}
                className="group flex items-start gap-4 rounded-3xl border border-slate-100 bg-slate-50/80 p-4 transition hover:border-slate-200 hover:bg-white"
              >
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-slate-900 text-white">
                  <Icon className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-slate-900 group-hover:text-indigo-700">
                    {title}
                  </p>
                  <p className="mt-1 text-sm leading-6 text-slate-500">{text}</p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <div className="flex flex-wrap items-center gap-3 rounded-2xl bg-white p-4 shadow-sm">
        <span className="mr-2 text-sm font-semibold text-gray-600">Donem:</span>
        {PRESETS.map((item, index) => (
          <button
            key={item.label}
            onClick={() => setPreset(index)}
            className={`rounded-xl px-4 py-1.5 text-sm font-semibold transition-colors ${
              preset === index
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {item.label}
          </button>
        ))}
        <button
          onClick={() => setPreset(-1)}
          className={`rounded-xl px-4 py-1.5 text-sm font-semibold transition-colors ${
            preset === -1
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Ozel Aralik
        </button>
        {preset === -1 ? (
          <div className="ml-2 flex items-center gap-2">
            <input
              type="date"
              value={customFrom}
              onChange={(event) => setCustomFrom(event.target.value)}
              className="rounded-xl border px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
            <span className="text-gray-400">to</span>
            <input
              type="date"
              value={customTo}
              onChange={(event) => setCustomTo(event.target.value)}
              className="rounded-xl border px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
        ) : null}
        <span className="ml-auto text-xs font-medium text-gray-400">
          {scopeLabel}
        </span>
      </div>

      <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Toplam Kullanici"
          value={stats?.allTimeUsers ?? stats?.totalUsers}
          loading={loading}
          color="indigo"
          icon={<UserGroupIcon className="h-6 w-6" />}
          subtitle={
            stats?.newUsersInRange != null
              ? `Secilen donemde ${stats.newUsersInRange} yeni kayit`
              : `${(stats?.newUsersThisMonth ?? 0).toLocaleString(
                  'tr-TR'
                )} bu ay yeni uye`
          }
        />
        <StatCard
          title="Toplam Siparis"
          value={stats?.allTimeOrders ?? stats?.totalOrders}
          loading={loading}
          color="orange"
          icon={<ShoppingCartIcon className="h-6 w-6" />}
          subtitle={
            stats?.ordersInRange != null
              ? `Secilen donemde ${stats.ordersInRange} siparis`
              : `${(stats?.deliveredOrders ?? 0).toLocaleString(
                  'tr-TR'
                )} teslim edilen siparis`
          }
        />
        <StatCard
          title="Donem Geliri"
          value={formatCurrency(stats?.grossRevenue)}
          loading={loading}
          color="green"
          icon={<CurrencyDollarIcon className="h-6 w-6" />}
          subtitle={`Ortalama sepet ${formatCurrency(stats?.averageOrderValue)}`}
        />
        <StatCard
          title="Bekleyen Iadeler"
          value={stats?.pendingReturns}
          loading={loading}
          color="red"
          icon={<ReceiptPercentIcon className="h-6 w-6" />}
          subtitle={`Onayli ${stats?.approvedReturns ?? 0} • Reddedilen ${stats?.rejectedReturns ?? 0}`}
        />
      </section>

      <section className="grid gap-5 lg:grid-cols-4">
        <StatCard
          title="Aktif Ilan"
          value={stats?.activePets}
          loading={loading}
          color="blue"
          icon={<ShieldCheckIcon className="h-6 w-6" />}
          subtitle={`${stats?.totalPets || 0} toplam ilandan yayinda olanlar`}
        />
        <StatCard
          title="Acik Destek"
          value={stats?.openSupportTickets}
          loading={loading}
          color="slate"
          icon={<LifebuoyIcon className="h-6 w-6" />}
          subtitle="Panelden hizli aksiyon alinabilir ticket sayisi"
        />
        <StatCard
          title="Bekleyen Seller"
          value={stats?.pendingSellerApplications}
          loading={loading}
          color="purple"
          icon={<ClipboardDocumentListIcon className="h-6 w-6" />}
          subtitle="Yeni partner onay sirasi"
        />
        <StatCard
          title="Aktif Kupon"
          value={stats?.totalActiveCoupons}
          loading={loading}
          color="green"
          icon={<ReceiptPercentIcon className="h-6 w-6" />}
          subtitle="Yayinda kalan kampanyalar"
        />
      </section>

      <section className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <ChartCard
          title="Gelir Trendi"
          subtitle="Siparis adedi ile birlikte secilen bucket araliginda gelir akisi."
        >
          {loading ? (
            <LoadingChart />
          ) : !stats?.revenueTrend?.length ? (
            <EmptyChart text="Gelir trendi icin veri bulunamadi." />
          ) : (
            <ResponsiveContainer width="100%" height={320}>
              <AreaChart data={stats.revenueTrend}>
                <defs>
                  <linearGradient id="revenueFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#4F46E5" stopOpacity={0.28} />
                    <stop offset="95%" stopColor="#4F46E5" stopOpacity={0.03} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis
                  dataKey="label"
                  tick={{ fill: '#64748b', fontSize: 12 }}
                  axisLine={false}
                  tickLine={false}
                />
                <YAxis
                  tick={{ fill: '#64748b', fontSize: 12 }}
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip
                  contentStyle={{
                    borderRadius: 16,
                    border: 'none',
                    boxShadow: '0 20px 40px rgba(15, 23, 42, 0.12)',
                  }}
                  formatter={(value, name) => [
                    name === 'revenue'
                      ? formatCurrency(value)
                      : Number(value).toLocaleString('tr-TR'),
                    name === 'revenue' ? 'Gelir' : 'Siparis',
                  ]}
                />
                <Area
                  type="monotone"
                  dataKey="revenue"
                  stroke="#4F46E5"
                  strokeWidth={3}
                  fill="url(#revenueFill)"
                />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        <ChartCard
          title="User Growth"
          subtitle="Yeni kullanici kayitlarinin bucket bazli dagilimi."
        >
          {loading ? (
            <LoadingChart />
          ) : !stats?.userGrowthTrend?.length ? (
            <EmptyChart text="Kayit trendi icin veri bulunamadi." />
          ) : (
            <ResponsiveContainer width="100%" height={320}>
              <BarChart data={stats.userGrowthTrend} barSize={28}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis
                  dataKey="label"
                  tick={{ fill: '#64748b', fontSize: 12 }}
                  axisLine={false}
                  tickLine={false}
                />
                <YAxis
                  tick={{ fill: '#64748b', fontSize: 12 }}
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip
                  contentStyle={{
                    borderRadius: 16,
                    border: 'none',
                    boxShadow: '0 20px 40px rgba(15, 23, 42, 0.12)',
                  }}
                  formatter={(value) => [
                    Number(value).toLocaleString('tr-TR'),
                    'Yeni kullanici',
                  ]}
                />
                <Bar dataKey="users" fill="#0F766E" radius={[10, 10, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>
      </section>

      <section className="grid gap-6 xl:grid-cols-[1fr_0.85fr]">
        <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h3 className="text-lg font-bold text-slate-900">
                Bestseller Urunler
              </h3>
              <p className="mt-1 text-sm text-slate-500">
                {(stats?.dateFilter ? 'Secilen donem' : 'Tum zamanlar')} icin en
                cok satan urunler.
              </p>
            </div>
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary-50 text-primary-700">
              <ArrowTrendingUpIcon className="h-5 w-5" />
            </div>
          </div>

          {loading ? (
            <div className="mt-5 space-y-3">
              {Array.from({ length: 5 }).map((_, index) => (
                <div
                  key={index}
                  className="h-16 animate-pulse rounded-3xl bg-slate-100"
                />
              ))}
            </div>
          ) : !stats?.topProducts?.length ? (
            <EmptyChart text="Bestseller verisi bulunamadi." compact />
          ) : (
            <div className="mt-5 space-y-3">
              {stats.topProducts.map((product, index) => (
                <div
                  key={product._id || `${product.name}-${index}`}
                  className="flex items-center gap-4 rounded-3xl bg-slate-50 px-4 py-4"
                >
                  <span className="w-7 text-center text-sm font-black text-primary-700">
                    #{index + 1}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-semibold text-slate-900">
                      {product.name}
                    </p>
                    <p className="mt-1 text-xs text-slate-500">
                      {Number(product.totalSold || 0).toLocaleString('tr-TR')} adet
                      satis
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-primary-700">
                      {formatCurrency(product.revenue)}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h3 className="text-lg font-bold text-slate-900">
                Operasyon Dengesi
              </h3>
              <p className="mt-1 text-sm text-slate-500">
                Iade, destek ve partner yogunlugunun hizli okuma paneli.
              </p>
            </div>
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-slate-900 text-white">
              <ShieldCheckIcon className="h-5 w-5" />
            </div>
          </div>

          <div className="mt-6 space-y-4">
            <ProgressRow
              label="Bekleyen Iadeler"
              value={stats?.pendingReturns}
              max={Math.max(
                stats?.pendingReturns || 0,
                stats?.approvedReturns || 0,
                stats?.rejectedReturns || 0,
                1
              )}
              tone="bg-amber-500"
            />
            <ProgressRow
              label="Onayli Iadeler"
              value={stats?.approvedReturns}
              max={Math.max(
                stats?.pendingReturns || 0,
                stats?.approvedReturns || 0,
                stats?.rejectedReturns || 0,
                1
              )}
              tone="bg-emerald-500"
            />
            <ProgressRow
              label="Reddedilen Iadeler"
              value={stats?.rejectedReturns}
              max={Math.max(
                stats?.pendingReturns || 0,
                stats?.approvedReturns || 0,
                stats?.rejectedReturns || 0,
                1
              )}
              tone="bg-rose-500"
            />
            <ProgressRow
              label="Acik Destek Ticket"
              value={stats?.openSupportTickets}
              max={Math.max(
                stats?.openSupportTickets || 0,
                stats?.pendingSellerApplications || 0,
                stats?.pendingReports || 0,
                1
              )}
              tone="bg-sky-500"
            />
            <ProgressRow
              label="Bekleyen Seller Basvurusu"
              value={stats?.pendingSellerApplications}
              max={Math.max(
                stats?.openSupportTickets || 0,
                stats?.pendingSellerApplications || 0,
                stats?.pendingReports || 0,
                1
              )}
              tone="bg-violet-500"
            />
            <ProgressRow
              label="Bekleyen Sikayet"
              value={stats?.pendingReports}
              max={Math.max(
                stats?.openSupportTickets || 0,
                stats?.pendingSellerApplications || 0,
                stats?.pendingReports || 0,
                1
              )}
              tone="bg-slate-700"
            />
          </div>
        </div>
      </section>
    </div>
  )
}

function MiniMetric({ label, value, icon: Icon }) {
  return (
    <div className="rounded-[26px] border border-white/10 bg-white/8 p-4 backdrop-blur-sm">
      <div className="flex items-center justify-between gap-3">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-300">
          {label}
        </p>
        <Icon className="h-5 w-5 text-slate-200" />
      </div>
      <p className="mt-3 text-3xl font-black">{formatMetricValue(value)}</p>
    </div>
  )
}

function ChartCard({ title, subtitle, children }) {
  return (
    <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
      <h3 className="text-lg font-bold text-slate-900">{title}</h3>
      <p className="mt-1 text-sm text-slate-500">{subtitle}</p>
      <div className="mt-5">{children}</div>
    </div>
  )
}

function ProgressRow({ label, value = 0, max = 1, tone }) {
  const ratio = Math.max(0, Math.min(1, Number(value || 0) / Math.max(max, 1)))
  return (
    <div>
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm font-medium text-slate-600">{label}</p>
        <p className="text-sm font-semibold text-slate-900">
          {Number(value || 0).toLocaleString('tr-TR')}
        </p>
      </div>
      <div className="mt-2 h-2.5 overflow-hidden rounded-full bg-slate-100">
        <div
          className={`h-full rounded-full ${tone}`}
          style={{ width: `${Math.max(ratio * 100, value ? 10 : 0)}%` }}
        />
      </div>
    </div>
  )
}

function LoadingChart() {
  return <div className="h-80 animate-pulse rounded-3xl bg-slate-100" />
}

function EmptyChart({ text, compact = false }) {
  return (
    <div
      className={`flex items-center justify-center rounded-3xl border border-dashed border-slate-200 bg-slate-50 text-sm text-slate-400 ${
        compact ? 'h-40' : 'h-80'
      }`}
    >
      {text}
    </div>
  )
}

function formatCurrency(value) {
  if (value == null || Number.isNaN(Number(value))) return '—'
  return `₺${Number(value).toLocaleString('tr-TR', {
    maximumFractionDigits: 0,
  })}`
}

function formatMetricValue(value) {
  if (typeof value === 'number') {
    return value.toLocaleString('tr-TR')
  }
  return value || '—'
}
