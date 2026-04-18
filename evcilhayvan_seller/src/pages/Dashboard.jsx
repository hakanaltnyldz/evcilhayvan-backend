import { useEffect, useState } from 'react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';
import {
  CubeIcon, ShoppingCartIcon, CurrencyDollarIcon,
  ExclamationTriangleIcon, ArchiveBoxIcon, ClockIcon,
} from '@heroicons/react/24/outline';
import StatCard from '../components/StatCard';
import api from '../api';

const STATUS_LABEL = { pending: 'Bekliyor', processing: 'İşleniyor', shipped: 'Kargoda', delivered: 'Teslim Edildi', cancelled: 'İptal' };
const STATUS_COLOR = { pending: 'bg-amber-100 text-amber-700', processing: 'bg-blue-100 text-blue-700', shipped: 'bg-purple-100 text-purple-700', delivered: 'bg-green-100 text-green-700', cancelled: 'bg-red-100 text-red-700' };

function PageHeader() {
  const user = (() => { try { return JSON.parse(localStorage.getItem('seller_user') || '{}'); } catch { return {}; } })();
  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Günaydın' : hour < 18 ? 'İyi günler' : 'İyi akşamlar';
  return (
    <div className="mb-6">
      <h1 className="text-2xl font-bold text-primary-800">{greeting}, {user.name?.split(' ')[0] || 'Satıcı'}! 👋</h1>
      <p className="text-gray-500 text-sm mt-0.5">Mağazanın durumuna genel bakış</p>
    </div>
  );
}

export default function Dashboard() {
  const [stats, setStats]         = useState(null);
  const [orderStats, setOrderStats] = useState(null);
  const [chartData, setChartData] = useState([]);
  const [recentOrders, setRecentOrders] = useState([]);
  const [loading, setLoading]     = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [s, os, oc, ord] = await Promise.allSettled([
          api.get('/seller/stats'),
          api.get('/seller/orders/stats'),
          api.get('/seller/orders/chart'),
          api.get('/seller/orders?limit=5'),
        ]);
        if (s.status === 'fulfilled')   setStats(s.value.data);
        if (os.status === 'fulfilled')  setOrderStats(os.value.data);
        if (oc.status === 'fulfilled')  setChartData(oc.value.data?.chart || oc.value.data?.data || []);
        if (ord.status === 'fulfilled') setRecentOrders(ord.value.data?.orders || []);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const formatCurrency = (n) =>
    n != null ? `₺${Number(n).toLocaleString('tr-TR', { minimumFractionDigits: 0 })}` : '—';

  return (
    <div>
      <PageHeader />

      {/* Stat grid */}
      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
        <StatCard loading={loading} title="Toplam Ürün"     value={stats?.totalProducts}   color="green"  icon={<CubeIcon className="w-5 h-5" />} />
        <StatCard loading={loading} title="Aktif Ürün"      value={stats?.activeProducts}  color="green"  icon={<ArchiveBoxIcon className="w-5 h-5" />} />
        <StatCard loading={loading} title="Stok Tükenen"    value={stats?.outOfStock}       color="red"    icon={<ExclamationTriangleIcon className="w-5 h-5" />} />
        <StatCard loading={loading} title="Bekleyen Sipariş" value={orderStats?.pending}   color="amber"  icon={<ClockIcon className="w-5 h-5" />} />
        <StatCard loading={loading} title="Bu Ay Gelir"      value={formatCurrency(orderStats?.revenueThisMonth)} color="blue" icon={<CurrencyDollarIcon className="w-5 h-5" />} />
        <StatCard loading={loading} title="Stok Değeri"      value={formatCurrency(stats?.totalValue)}   color="purple" icon={<ShoppingCartIcon className="w-5 h-5" />} />
      </div>

      {/* Chart + Recent orders */}
      <div className="grid lg:grid-cols-5 gap-6">
        {/* Revenue chart */}
        <div className="lg:col-span-3 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="font-bold text-gray-800 mb-4">Son 6 Ay Geliri</h2>
          {loading ? (
            <div className="h-56 bg-gray-50 rounded-xl animate-pulse" />
          ) : chartData.length === 0 ? (
            <div className="h-56 flex flex-col items-center justify-center text-gray-400">
              <ChartBarIconOutline />
              <p className="mt-2 text-sm">Henüz veri yok</p>
            </div>
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

        {/* Recent orders */}
        <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="font-bold text-gray-800 mb-4">Son Siparişler</h2>
          {loading ? (
            <div className="space-y-3">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="h-12 bg-gray-50 rounded-xl animate-pulse" />
              ))}
            </div>
          ) : recentOrders.length === 0 ? (
            <div className="text-center py-8 text-gray-400 text-sm">
              <ShoppingCartIcon className="w-10 h-10 mx-auto mb-2 opacity-30" />
              Henüz sipariş yok
            </div>
          ) : (
            <div className="space-y-3">
              {recentOrders.map((order) => (
                <div key={order._id} className="flex items-center justify-between p-3 rounded-xl bg-gray-50 hover:bg-primary-50 transition">
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-gray-800 truncate">
                      {order.user?.name || 'Müşteri'}
                    </p>
                    <p className="text-xs text-gray-400">{new Date(order.createdAt).toLocaleDateString('tr-TR')}</p>
                  </div>
                  <div className="flex flex-col items-end gap-1 ml-2">
                    <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${STATUS_COLOR[order.status] || 'bg-gray-100 text-gray-600'}`}>
                      {STATUS_LABEL[order.status] || order.status}
                    </span>
                    <span className="text-xs font-bold text-primary-700">₺{Number(order.totalAmount).toLocaleString('tr-TR')}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function ChartBarIconOutline() {
  return (
    <svg className="w-12 h-12 mx-auto opacity-20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
    </svg>
  );
}
