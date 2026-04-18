import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import {
  MagnifyingGlassIcon, ChevronDownIcon, TruckIcon,
  EyeIcon, XMarkIcon,
} from '@heroicons/react/24/outline';
import api from '../api';

const STATUS_FLOW  = ['pending', 'processing', 'shipped', 'delivered'];
const STATUS_LABEL = { pending: 'Bekliyor', processing: 'İşleniyor', shipped: 'Kargoda', delivered: 'Teslim Edildi', cancelled: 'İptal' };
const STATUS_COLOR = {
  pending:   'bg-amber-100 text-amber-700',
  processing:'bg-blue-100 text-blue-700',
  shipped:   'bg-purple-100 text-purple-700',
  delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-700',
};

export default function Orders() {
  const [orders, setOrders]         = useState([]);
  const [loading, setLoading]       = useState(true);
  const [search, setSearch]         = useState('');
  const [filter, setFilter]         = useState('all');
  const [detail, setDetail]         = useState(null);
  const [tracking, setTracking]     = useState({ orderId: null, value: '' });
  const [updating, setUpdating]     = useState(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api.get('/seller/orders?limit=100');
      setOrders(res.data?.orders || res.data?.data || []);
    } catch { toast.error('Siparişler yüklenemedi'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const updateStatus = async (orderId, newStatus) => {
    setUpdating(orderId);
    try {
      await api.patch(`/seller/orders/${orderId}/status`, { status: newStatus });
      toast.success(`Durum güncellendi: ${STATUS_LABEL[newStatus]}`);
      load();
      if (detail?._id === orderId) setDetail((d) => ({ ...d, status: newStatus }));
    } catch (err) {
      toast.error(err.response?.data?.message || 'Güncelleme başarısız');
    } finally { setUpdating(null); }
  };

  const submitTracking = async (orderId) => {
    if (!tracking.value.trim()) return;
    setUpdating(orderId);
    try {
      await api.patch(`/seller/orders/${orderId}/status`, { status: 'shipped', trackingNumber: tracking.value.trim() });
      toast.success('Kargo bilgisi kaydedildi');
      setTracking({ orderId: null, value: '' });
      load();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Güncelleme başarısız');
    } finally { setUpdating(null); }
  };

  const filtered = orders.filter((o) => {
    const matchStatus = filter === 'all' || o.status === filter;
    const q = search.toLowerCase();
    const matchSearch = !q || o.user?.name?.toLowerCase().includes(q) || o._id?.toLowerCase().includes(q);
    return matchStatus && matchSearch;
  });

  const nextStatus = (current) => {
    const idx = STATUS_FLOW.indexOf(current);
    return idx >= 0 && idx < STATUS_FLOW.length - 1 ? STATUS_FLOW[idx + 1] : null;
  };

  const API_BASE  = import.meta.env.VITE_API_URL || 'http://localhost:3000';
  const resolveImg = (url) => !url ? null : url.startsWith('http') ? url : `${API_BASE}${url}`;

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-primary-800">Siparişler</h1>
          <p className="text-gray-500 text-sm mt-0.5">{orders.length} sipariş</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-4">
        <div className="relative flex-1">
          <MagnifyingGlassIcon className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            value={search} onChange={(e) => setSearch(e.target.value)}
            placeholder="Müşteri adı veya sipariş ID..."
            className="w-full pl-9 pr-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 bg-white"
          />
        </div>
        <div className="relative">
          <select
            value={filter} onChange={(e) => setFilter(e.target.value)}
            className="appearance-none pl-4 pr-10 py-2.5 border border-gray-200 rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-primary-500 text-gray-700"
          >
            <option value="all">Tüm Durumlar</option>
            {Object.entries(STATUS_LABEL).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
          <ChevronDownIcon className="w-4 h-4 absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 space-y-4">
            {[...Array(5)].map((_, i) => <div key={i} className="h-16 bg-gray-50 rounded-xl animate-pulse" />)}
          </div>
        ) : filtered.length === 0 ? (
          <div className="py-16 text-center text-gray-400">
            <EmptyIcon />
            <p className="mt-3 font-medium">Sipariş bulunamadı</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50/50">
                  {['Sipariş', 'Müşteri', 'Tutar', 'Durum', 'Tarih', 'İşlemler'].map((h) => (
                    <th key={h} className="px-5 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map((o) => {
                  const next = nextStatus(o.status);
                  return (
                    <tr key={o._id} className="hover:bg-primary-50/30 transition-colors">
                      <td className="px-5 py-4">
                        <p className="text-xs font-mono text-gray-500">#{o._id?.slice(-8).toUpperCase()}</p>
                        <p className="text-xs text-gray-400">{o.items?.length || 0} ürün</p>
                      </td>
                      <td className="px-5 py-4">
                        <p className="text-sm font-semibold text-gray-800">{o.user?.name || 'Müşteri'}</p>
                        <p className="text-xs text-gray-400">{o.user?.email || ''}</p>
                      </td>
                      <td className="px-5 py-4">
                        <span className="font-bold text-primary-700">₺{Number(o.totalAmount).toLocaleString('tr-TR')}</span>
                      </td>
                      <td className="px-5 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${STATUS_COLOR[o.status] || 'bg-gray-100 text-gray-600'}`}>
                          {STATUS_LABEL[o.status] || o.status}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-xs text-gray-400">
                        {new Date(o.createdAt).toLocaleDateString('tr-TR')}
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => setDetail(o)}
                            className="p-2 rounded-lg hover:bg-primary-100 text-primary-600 transition" title="Detay"
                          >
                            <EyeIcon className="w-4 h-4" />
                          </button>
                          {next && (
                            <button
                              onClick={() => next === 'shipped'
                                ? setTracking({ orderId: o._id, value: '' })
                                : updateStatus(o._id, next)
                              }
                              disabled={updating === o._id}
                              className="flex items-center gap-1 px-2.5 py-1.5 bg-primary-600 text-white rounded-lg text-xs font-semibold hover:bg-primary-700 transition disabled:opacity-50"
                            >
                              {updating === o._id ? '...' : STATUS_LABEL[next]}
                            </button>
                          )}
                        </div>
                        {/* Tracking input */}
                        {tracking.orderId === o._id && (
                          <div className="mt-2 flex gap-1">
                            <input
                              value={tracking.value}
                              onChange={(e) => setTracking({ ...tracking, value: e.target.value })}
                              placeholder="Kargo takip no"
                              className="flex-1 px-2 py-1.5 border border-gray-200 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-primary-500"
                              onKeyDown={(e) => e.key === 'Enter' && submitTracking(o._id)}
                            />
                            <button
                              onClick={() => submitTracking(o._id)}
                              disabled={updating === o._id}
                              className="px-2 py-1.5 bg-purple-600 text-white rounded-lg text-xs font-semibold hover:bg-purple-700 transition"
                            >
                              <TruckIcon className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => setTracking({ orderId: null, value: '' })}
                              className="px-2 py-1.5 border border-gray-200 text-gray-500 rounded-lg text-xs hover:bg-gray-50 transition"
                            >
                              <XMarkIcon className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Detail Modal */}
      {detail && (
        <OrderDetailModal
          order={detail}
          onClose={() => setDetail(null)}
          onStatusUpdate={updateStatus}
          updating={updating}
          resolveImg={resolveImg}
        />
      )}
    </div>
  );
}

function OrderDetailModal({ order, onClose, onStatusUpdate, updating, resolveImg }) {
  const next = (() => {
    const idx = STATUS_FLOW.indexOf(order.status);
    return idx >= 0 && idx < STATUS_FLOW.length - 1 ? STATUS_FLOW[idx + 1] : null;
  })();

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white px-6 py-4 border-b border-gray-100 flex items-center justify-between rounded-t-2xl">
          <div>
            <h2 className="font-bold text-gray-800">Sipariş Detayı</h2>
            <p className="text-xs text-gray-400">#{order._id?.slice(-8).toUpperCase()}</p>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-100 text-gray-400">
            <XMarkIcon className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 space-y-5">
          {/* Status timeline */}
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase mb-3">Durum</p>
            <div className="flex items-center gap-1">
              {STATUS_FLOW.map((s, i) => {
                const idx    = STATUS_FLOW.indexOf(order.status);
                const active = i <= idx;
                return (
                  <div key={s} className="flex items-center gap-1 flex-1">
                    <div className={`flex-1 h-1.5 rounded-full ${active ? 'bg-primary-500' : 'bg-gray-200'}`} />
                    {i === STATUS_FLOW.length - 1 && (
                      <div className={`w-2.5 h-2.5 rounded-full ${active ? 'bg-primary-500' : 'bg-gray-200'}`} />
                    )}
                  </div>
                );
              })}
            </div>
            <div className="flex justify-between mt-1">
              {STATUS_FLOW.map((s) => (
                <span key={s} className={`text-xs ${order.status === s ? 'text-primary-600 font-semibold' : 'text-gray-400'}`}>
                  {STATUS_LABEL[s]}
                </span>
              ))}
            </div>
          </div>

          {/* Customer */}
          <div className="bg-gray-50 rounded-xl p-4">
            <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Müşteri</p>
            <p className="font-semibold text-gray-800">{order.user?.name || 'Müşteri'}</p>
            <p className="text-sm text-gray-500">{order.user?.email || ''}</p>
          </div>

          {/* Items */}
          {order.items?.length > 0 && (
            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase mb-3">Ürünler</p>
              <div className="space-y-2">
                {order.items.map((item, i) => {
                  const img = resolveImg(item.product?.photos?.[0] || item.product?.images?.[0]);
                  return (
                    <div key={i} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                      {img ? (
                        <img src={img} className="w-12 h-12 rounded-lg object-cover" alt="" />
                      ) : (
                        <div className="w-12 h-12 rounded-lg bg-primary-50 flex items-center justify-center text-primary-300 text-lg">📦</div>
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-gray-800 truncate">{item.product?.title || item.product?.name || 'Ürün'}</p>
                        <p className="text-xs text-gray-400">x{item.quantity}</p>
                      </div>
                      <span className="font-bold text-primary-700 text-sm">₺{Number(item.price * item.quantity).toLocaleString('tr-TR')}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Total */}
          <div className="flex items-center justify-between pt-2 border-t border-gray-100">
            <span className="font-semibold text-gray-700">Toplam</span>
            <span className="text-xl font-bold text-primary-700">₺{Number(order.totalAmount).toLocaleString('tr-TR')}</span>
          </div>

          {/* Address */}
          {order.shippingAddress && (
            <div className="bg-gray-50 rounded-xl p-4 text-sm text-gray-600">
              <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Teslimat Adresi</p>
              <p>{order.shippingAddress.fullName || order.shippingAddress.title}</p>
              <p>{order.shippingAddress.addressLine || order.shippingAddress.address}</p>
              <p>{[order.shippingAddress.district, order.shippingAddress.city].filter(Boolean).join(', ')}</p>
            </div>
          )}

          {/* Tracking */}
          {order.trackingNumber && (
            <div className="flex items-center gap-2 px-4 py-3 bg-purple-50 rounded-xl">
              <TruckIcon className="w-5 h-5 text-purple-500" />
              <div>
                <p className="text-xs text-purple-500 font-semibold">Kargo Takip No</p>
                <p className="font-mono text-purple-800 font-bold">{order.trackingNumber}</p>
              </div>
            </div>
          )}

          {/* Action */}
          {next && (
            <button
              onClick={() => onStatusUpdate(order._id, next)}
              disabled={updating === order._id}
              className="w-full py-3 bg-gradient-to-r from-primary-700 to-primary-500 text-white rounded-xl font-bold text-sm shadow-lg shadow-primary-500/25 disabled:opacity-60 transition"
            >
              {updating === order._id ? 'Güncelleniyor...' : `${STATUS_LABEL[next]} Olarak İşaretle`}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function EmptyIcon() {
  return (
    <svg className="w-14 h-14 mx-auto text-gray-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
    </svg>
  );
}
