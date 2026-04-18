import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import {
  PlusIcon, PencilIcon, TrashIcon,
  EyeIcon, EyeSlashIcon, TagIcon,
} from '@heroicons/react/24/outline';
import api from '../api';

const EMPTY_FORM = {
  code: '', discountType: 'percentage', discountValue: '',
  minPurchaseAmount: '', usageLimit: '',
  validFrom: '', validUntil: '', description: '',
};

export default function Coupons() {
  const [coupons, setCoupons]   = useState([]);
  const [loading, setLoading]   = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing]   = useState(null);
  const [form, setForm]         = useState(EMPTY_FORM);
  const [saving, setSaving]     = useState(false);
  const [deleteId, setDeleteId] = useState(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api.get('/seller/coupons');
      setCoupons(res.data?.coupons || res.data?.data || []);
    } catch { toast.error('Kuponlar yüklenemedi'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const openCreate = () => { setEditing(null); setForm(EMPTY_FORM); setShowForm(true); };
  const openEdit   = (c) => {
    setEditing(c);
    setForm({
      code: c.code || '',
      discountType: c.discountType || 'percentage',
      discountValue: c.discountValue ?? '',
      minPurchaseAmount: c.minPurchaseAmount ?? '',
      usageLimit: c.usageLimit ?? '',
      validFrom: c.validFrom ? c.validFrom.slice(0, 10) : '',
      validUntil: c.validUntil ? c.validUntil.slice(0, 10) : '',
      description: c.description || '',
    });
    setShowForm(true);
  };
  const closeForm = () => { setShowForm(false); setEditing(null); };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.code.trim() || !form.discountValue) return toast.error('Kupon kodu ve indirim zorunlu');
    setSaving(true);
    try {
      const body = {
        ...form,
        discountValue: Number(form.discountValue),
        minPurchaseAmount: form.minPurchaseAmount ? Number(form.minPurchaseAmount) : 0,
        usageLimit: form.usageLimit ? Number(form.usageLimit) : undefined,
      };
      if (editing) {
        await api.put(`/seller/coupons/${editing._id}`, body);
      } else {
        await api.post('/seller/coupons', body);
      }
      toast.success(editing ? 'Kupon güncellendi' : 'Kupon oluşturuldu');
      closeForm();
      load();
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız');
    } finally { setSaving(false); }
  };

  const toggleActive = async (c) => {
    try {
      await api.patch(`/seller/coupons/${c._id}/toggle`);
      toast.success(c.isActive ? 'Kupon pasife alındı' : 'Kupon aktife alındı');
      load();
    } catch { toast.error('İşlem başarısız'); }
  };

  const confirmDelete = async () => {
    if (!deleteId) return;
    try {
      await api.delete(`/seller/coupons/${deleteId}`);
      toast.success('Kupon silindi');
      setDeleteId(null);
      load();
    } catch { toast.error('Silinemedi'); }
  };

  const formatDiscount = (c) =>
    c.discountType === 'percentage' ? `%${c.discountValue}` : `₺${Number(c.discountValue).toLocaleString('tr-TR')}`;

  const isExpired = (c) => c.validUntil && new Date(c.validUntil) < new Date();

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-primary-800">Kuponlar</h1>
          <p className="text-gray-500 text-sm mt-0.5">{coupons.length} kupon</p>
        </div>
        <button onClick={openCreate}
          className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-primary-700 to-primary-500 text-white rounded-xl text-sm font-semibold shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all">
          <PlusIcon className="w-5 h-5" /> Yeni Kupon
        </button>
      </div>

      {/* Grid */}
      {loading ? (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {[...Array(6)].map((_, i) => <div key={i} className="h-36 bg-white rounded-2xl animate-pulse border border-gray-100" />)}
        </div>
      ) : coupons.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 py-16 text-center text-gray-400">
          <TagIcon className="w-14 h-14 mx-auto text-gray-200 mb-3" />
          <p className="font-medium">Henüz kupon yok</p>
          <p className="text-sm mt-1">İlk kuponu oluşturmak için butona tıkla</p>
          <button onClick={openCreate} className="mt-4 px-5 py-2 bg-primary-600 text-white rounded-xl text-sm font-semibold">
            Kupon Ekle
          </button>
        </div>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {coupons.map((c) => {
            const expired = isExpired(c);
            return (
              <div key={c._id}
                className={`bg-white rounded-2xl border p-5 shadow-sm transition ${expired ? 'border-gray-200 opacity-70' : c.isActive ? 'border-primary-100' : 'border-gray-200'}`}>
                {/* Top row */}
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-mono font-bold text-primary-700 bg-primary-50 px-2.5 py-0.5 rounded-lg text-sm tracking-wider">
                        {c.code}
                      </span>
                      {expired && <span className="text-xs text-red-500 font-semibold">Süresi Doldu</span>}
                    </div>
                    {c.description && <p className="text-xs text-gray-400">{c.description}</p>}
                  </div>
                  <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${c.isActive && !expired ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                    {c.isActive && !expired ? 'Aktif' : 'Pasif'}
                  </span>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-2 gap-2 mb-4">
                  <div className="bg-primary-50 rounded-xl p-2.5 text-center">
                    <p className="text-lg font-bold text-primary-700">{formatDiscount(c)}</p>
                    <p className="text-xs text-gray-400">İndirim</p>
                  </div>
                  <div className="bg-gray-50 rounded-xl p-2.5 text-center">
                    <p className="text-lg font-bold text-gray-700">{c.usedCount || 0}/{c.usageLimit || '∞'}</p>
                    <p className="text-xs text-gray-400">Kullanım</p>
                  </div>
                </div>

                {/* Details */}
                <div className="space-y-1 mb-4 text-xs text-gray-500">
                  {c.minPurchaseAmount > 0 && <p>Min. sipariş: <span className="font-semibold">₺{Number(c.minPurchaseAmount).toLocaleString('tr-TR')}</span></p>}
                  {c.validUntil && <p>Son geçerlilik: <span className="font-semibold">{new Date(c.validUntil).toLocaleDateString('tr-TR')}</span></p>}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 pt-3 border-t border-gray-50">
                  <button onClick={() => openEdit(c)} className="p-2 rounded-lg hover:bg-primary-100 text-primary-600 transition" title="Düzenle">
                    <PencilIcon className="w-4 h-4" />
                  </button>
                  <button onClick={() => toggleActive(c)} className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 transition"
                    title={c.isActive ? 'Pasife Al' : 'Aktife Al'}>
                    {c.isActive ? <EyeSlashIcon className="w-4 h-4" /> : <EyeIcon className="w-4 h-4" />}
                  </button>
                  <button onClick={() => setDeleteId(c._id)} className="p-2 rounded-lg hover:bg-red-100 text-red-500 transition" title="Sil">
                    <TrashIcon className="w-4 h-4" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Create/Edit Modal */}
      {showForm && (
        <Modal title={editing ? 'Kuponu Düzenle' : 'Yeni Kupon'} onClose={closeForm}>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Kupon Kodu *</label>
              <input
                value={form.code} required
                onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })}
                placeholder="Örn: YAZA20"
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm font-mono tracking-widest uppercase focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">İndirim Türü</label>
                <select
                  value={form.discountType}
                  onChange={(e) => setForm({ ...form, discountType: e.target.value })}
                  className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 bg-white"
                >
                  <option value="percentage">Yüzde (%)</option>
                  <option value="fixed">Sabit Tutar (₺)</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                  İndirim {form.discountType === 'percentage' ? '(%)' : '(₺)'} *
                </label>
                <input
                  type="number" required value={form.discountValue}
                  onChange={(e) => setForm({ ...form, discountValue: e.target.value })}
                  placeholder={form.discountType === 'percentage' ? '20' : '50'}
                  min="0" max={form.discountType === 'percentage' ? '100' : undefined}
                  className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Başlangıç Tarihi *</label>
                <input
                  type="date" required value={form.validFrom}
                  onChange={(e) => setForm({ ...form, validFrom: e.target.value })}
                  min={new Date().toISOString().slice(0, 10)}
                  className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Bitiş Tarihi *</label>
                <input
                  type="date" required value={form.validUntil}
                  onChange={(e) => setForm({ ...form, validUntil: e.target.value })}
                  min={form.validFrom || new Date().toISOString().slice(0, 10)}
                  className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Min. Sipariş (₺)</label>
                <input
                  type="number" value={form.minPurchaseAmount}
                  onChange={(e) => setForm({ ...form, minPurchaseAmount: e.target.value })}
                  placeholder="0" min="0"
                  className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Max Kullanım</label>
                <input
                  type="number" value={form.usageLimit}
                  onChange={(e) => setForm({ ...form, usageLimit: e.target.value })}
                  placeholder="Sınırsız" min="1"
                  className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Açıklama</label>
              <input
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                placeholder="İç not (isteğe bağlı)"
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>

            <div className="flex gap-3 pt-2">
              <button type="button" onClick={closeForm}
                className="flex-1 py-2.5 border border-gray-200 text-gray-600 rounded-xl text-sm font-semibold hover:bg-gray-50">
                İptal
              </button>
              <button type="submit" disabled={saving}
                className="flex-1 py-2.5 bg-gradient-to-r from-primary-700 to-primary-500 text-white rounded-xl text-sm font-bold disabled:opacity-60 shadow-lg shadow-primary-500/25 transition">
                {saving ? 'Kaydediliyor...' : editing ? 'Güncelle' : 'Oluştur'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* Delete confirm */}
      {deleteId && (
        <Modal title="Kuponu Sil" onClose={() => setDeleteId(null)} size="sm">
          <p className="text-gray-600 text-sm mb-5">Bu kuponu silmek istediğinden emin misin?</p>
          <div className="flex gap-3">
            <button onClick={() => setDeleteId(null)}
              className="flex-1 py-2.5 border border-gray-200 text-gray-600 rounded-xl text-sm font-semibold">
              Vazgeç
            </button>
            <button onClick={confirmDelete}
              className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-bold hover:bg-red-600">
              Evet, Sil
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}

function Modal({ title, children, onClose, size = 'md' }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative bg-white rounded-2xl shadow-2xl w-full ${size === 'sm' ? 'max-w-sm' : 'max-w-lg'} max-h-[90vh] overflow-y-auto`}>
        <div className="sticky top-0 bg-white px-6 py-4 border-b border-gray-100 flex items-center justify-between rounded-t-2xl">
          <h2 className="font-bold text-gray-800">{title}</h2>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-100 text-gray-400">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div className="p-6">{children}</div>
      </div>
    </div>
  );
}
