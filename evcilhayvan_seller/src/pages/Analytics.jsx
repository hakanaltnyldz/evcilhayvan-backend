import { useEffect, useState } from 'react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from 'recharts';
import {
  CurrencyDollarIcon, ShoppingCartIcon, CheckCircleIcon,
  ArrowTrendingUpIcon,
} from '@heroicons/react/24/outline';
import api from '../api';

const STATUS_LABEL = { pending: 'Bekliyor', processing: 'İşleniyor', shipped: 'Kargoda', delivered: 'Teslim Edildi', cancelled: 'İptal' };
const PIE_COLORS   = ['#F59E0B', '#3B82F6', '#8B5CF6', '#10B981', '#EF4444'];

export default function Analytics() {
  const [chartData, setChartData]   = useState([]);
  const [orderStats, setOrderStats] = useState(null);
  const [topProducts, setTopProducts] = useState([]);
  const [loading, setLoading]       = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [oc, os] = await Promise.allSettled([
          api.get('/seller/orders/chart'),
          api.get('/seller/orders/stats'),
        ]);
        if (oc.status === 'fulfilled') setChartData(oc.value.data?.chart || oc.value.data?.data || []);
        if (os.status === 'fulfilled') {
          const d = os.value.data;
          setOrderStats(d);
          // Build top products from stats if available
          if (d?.topProducts) setTopProducts(d.topProducts);
        }
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const formatCurrency = (n) =>
    n != null ? `₺${Number(n).toLocaleString('tr-TR', { minimumFractionDigits: 0 })}` : '—';

  // Build pie data from order stats
  const pieData = orderStats
    ? Object.entries(STATUS_LABEL)
        .map(([key, label]) => ({ name: label, value: orderStats[key] || 0 }))
        .filter((d) => d.value > 0)
    : [];

  const totalOrders = pieData.reduce((s, d) => s + d.value, 0);

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-primary-800">Analitik</h1>
        <p className="text-gray-500 text-sm mt-0.5">Satış ve sipariş istatistiklerini görüntüle</p>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <SummaryCard
          loading={loading}
          title="Bu Ay Gelir"
          value={formatCurrency(orderStats?.revenueThisMonth)}
          sub={`Toplam: ${formatCurrency(orderStats?.totalRevenue)}`}
          icon={<CurrencyDollarIcon className="w-5 h-5" />}
          color="green"
        />
        <SummaryCard
          loading={loading}
          title="Toplam Sipariş"
          value={totalOrders || '—'}
          sub={`Bu ay: ${orderStats?.ordersThisMonth || 0}`}
          icon={<ShoppingCartIcon className="w-5 h-5" />}
          color="blue"
        />
        <SummaryCard
          loading={loading}
          title="Teslim Edilen"
          value={orderStats?.delivered || '—'}
          sub="Başarılı sipariş"
          icon={<CheckCircleIcon className="w-5 h-5" />}
          color="purple"
        />
        <SummaryCard
          loading={loading}
          title="Ort. Sipariş"
          value={formatCurrency(orderStats?.averageOrderValue)}
          sub="Ortalama tutar"
          icon={<ArrowTrendingUpIcon className="w-5 h-5" />}
          color="amber"
        />
      </div>

      {/* Charts row */}
      <div className="grid lg:grid-cols-5 gap-6 mb-6">
        {/* Revenue bar chart */}
        <div className="lg:col-span-3 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="font-bold text-gray-800 mb-4">Aylık Gelir (Son 6 Ay)</h2>
          {loading ? (
            <div className="h-56 bg-gray-50 rounded-xl animate-pulse" />
          ) : chartData.length === 0 ? (
            <EmptyChart label="Henüz veri yok" />
          ) : (
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={chartData} barSize={32}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#9ca3af' }} axisLine={false} tickLine={false}
                  tickFormatter={(v) => `₺${v >= 1000 ? (v / 1000).toFixed(0) + 'K' : v}`} />
                <Tooltip
                  formatter={(v) => [`₺${Number(v).toLocaleString('tr-TR')}`, 'Gelir']}
                  contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}
                />
                <Bar dataKey="revenue" fill="#2D6A4F" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Order status pie */}
        <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="font-bold text-gray-800 mb-4">Sipariş Dağılımı</h2>
          {loading ? (
            <div className="h-56 bg-gray-50 rounded-xl animate-pulse" />
          ) : pieData.length === 0 ? (
            <EmptyChart label="Henüz sipariş yok" />
          ) : (
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie
                  data={pieData} dataKey="value" nameKey="name"
                  cx="50%" cy="45%" outerRadius={75} innerRadius={45}
                  paddingAngle={3}
                >
                  {pieData.map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(v, name) => [v, name]}
                  contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}
                />
                <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* Order count chart */}
      {!loading && chartData.some((d) => d.orders != null) && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6">
          <h2 className="font-bold text-gray-800 mb-4">Aylık Sipariş Sayısı</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={chartData} barSize={28}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 12, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
              <Tooltip
                formatter={(v) => [v, 'Sipariş']}
                contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}
              />
              <Bar dataKey="orders" fill="#52B788" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Top products */}
      {topProducts.length > 0 && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="font-bold text-gray-800 mb-4">En Çok Satan Ürünler</h2>
          <div className="space-y-3">
            {topProducts.map((p, i) => (
              <div key={p._id || i} className="flex items-center gap-4">
                <span className={`text-sm font-bold w-6 text-center ${i === 0 ? 'text-amber-500' : i === 1 ? 'text-gray-400' : i === 2 ? 'text-orange-400' : 'text-gray-300'}`}>
                  #{i + 1}
                </span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-800 truncate">{p.title || p.name}</p>
                  <p className="text-xs text-gray-400">{p.totalSold || p.count || 0} satış</p>
                </div>
                <div className="text-right">
                  <p className="font-bold text-primary-700 text-sm">₺{Number(p.revenue || p.price * (p.totalSold || 1)).toLocaleString('tr-TR')}</p>
                </div>
                <div className="w-24">
                  <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-primary-500 rounded-full"
                      style={{ width: `${Math.min(100, ((p.totalSold || 1) / (topProducts[0]?.totalSold || 1)) * 100)}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function SummaryCard({ title, value, sub, icon, color, loading }) {
  const colorMap = {
    green:  { bg: 'bg-primary-50',  text: 'text-primary-700',  icon: 'bg-primary-100 text-primary-600' },
    blue:   { bg: 'bg-blue-50',     text: 'text-blue-700',     icon: 'bg-blue-100 text-blue-600' },
    purple: { bg: 'bg-purple-50',   text: 'text-purple-700',   icon: 'bg-purple-100 text-purple-600' },
    amber:  { bg: 'bg-amber-50',    text: 'text-amber-700',    icon: 'bg-amber-100 text-amber-600' },
  };
  const c = colorMap[color] || colorMap.green;
  return (
    <div className={`${c.bg} rounded-2xl p-5 border border-white shadow-sm`}>
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-gray-500 text-sm font-medium">{title}</p>
          {loading ? (
            <div className="mt-2 h-8 w-24 bg-gray-200 rounded-lg animate-pulse" />
          ) : (
            <p className={`mt-1 text-2xl font-bold ${c.text}`}>{value ?? '—'}</p>
          )}
          {sub && <p className="mt-0.5 text-xs text-gray-400">{sub}</p>}
        </div>
        {icon && (
          <div className={`${c.icon} w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0 ml-3`}>
            {icon}
          </div>
        )}
      </div>
    </div>
  );
}

function EmptyChart({ label }) {
  return (
    <div className="h-56 flex flex-col items-center justify-center text-gray-400">
      <svg className="w-12 h-12 mx-auto opacity-20 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
          d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
      </svg>
      <p className="text-sm">{label}</p>
    </div>
  );
}
