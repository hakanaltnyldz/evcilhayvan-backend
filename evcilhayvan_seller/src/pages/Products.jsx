import { useEffect, useState, useRef } from 'react';
import toast from 'react-hot-toast';
import {
  PlusIcon, PencilIcon, TrashIcon, PhotoIcon,
  EyeIcon, EyeSlashIcon, ArrowUpTrayIcon,
} from '@heroicons/react/24/outline';
import api from '../api';

const EMPTY_FORM = { name: '', description: '', price: '', stock: '', category: '' };

export default function Products() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading]   = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing]   = useState(null);
  const [form, setForm]         = useState(EMPTY_FORM);
  const [saving, setSaving]     = useState(false);
  const [deleteId, setDeleteId] = useState(null);
  const [images, setImages]     = useState([]);
  const fileRef = useRef();

  const load = async () => {
    setLoading(true);
    try {
      const res = await api.get('/seller/products');
      setProducts(res.data?.products || res.data?.data || []);
    } catch { toast.error('Ürünler yüklenemedi'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const openCreate = () => { setEditing(null); setForm(EMPTY_FORM); setImages([]); setShowForm(true); };
  const openEdit   = (p)  => {
    setEditing(p);
    setForm({ name: p.name || p.title || '', description: p.description || '', price: p.price ?? '', stock: p.stock ?? '', category: p.category?.name || p.category || '' });
    setImages([]);
    setShowForm(true);
  };
  const closeForm = () => { setShowForm(false); setEditing(null); setImages([]); };

  const handleImageChange = (e) => {
    const files = Array.from(e.target.files).slice(0, 5);
    setImages(files);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.name.trim() || !form.price) return toast.error('Ürün adı ve fiyat zorunlu');
    setSaving(true);
    try {
      if (images.length > 0) {
        // Use multipart endpoint
        const fd = new FormData();
        Object.entries(form).forEach(([k, v]) => v !== '' && fd.append(k, v));
        images.forEach((f) => fd.append('images', f));
        if (editing) {
          await api.patch(`/seller/products/${editing._id}`, fd, { headers: { 'Content-Type': 'multipart/form-data' } });
        } else {
          await api.post('/seller/products/with-images', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
        }
      } else {
        const body = { ...form, price: Number(form.price), stock: Number(form.stock) };
        if (editing) { await api.patch(`/seller/products/${editing._id}`, body); }
        else          { await api.post('/seller/products', body); }
      }
      toast.success(editing ? 'Ürün güncellendi' : 'Ürün oluşturuldu');
      closeForm();
      load();
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız');
    } finally {
      setSaving(false);
    }
  };

  const toggleActive = async (p) => {
    try {
      await api.patch(`/seller/products/${p._id}/toggle-active`);
      toast.success(p.isActive ? 'Ürün pasife alındı' : 'Ürün aktife alındı');
      load();
    } catch { toast.error('İşlem başarısız'); }
  };

  const confirmDelete = async () => {
    if (!deleteId) return;
    try {
      await api.delete(`/seller/products/${deleteId}`);
      toast.success('Ürün silindi');
      setDeleteId(null);
      load();
    } catch { toast.error('Silinemedi'); }
  };

  const API_BASE = (import.meta.env.VITE_API_URL || 'http://localhost:3000');
  const resolveImg = (url) => !url ? null : url.startsWith('http') ? url : `${API_BASE}${url}`;

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-primary-800">Ürünler</h1>
          <p className="text-gray-500 text-sm mt-0.5">{products.length} ürün listelendi</p>
        </div>
        <button onClick={openCreate}
          className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-primary-700 to-primary-500 text-white rounded-xl text-sm font-semibold shadow-lg shadow-primary-500/30 hover:shadow-primary-500/50 transition-all">
          <PlusIcon className="w-5 h-5" /> Yeni Ürün
        </button>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 space-y-4">
            {[...Array(5)].map((_, i) => <div key={i} className="h-14 bg-gray-50 rounded-xl animate-pulse" />)}
          </div>
        ) : products.length === 0 ? (
          <div className="py-16 text-center text-gray-400">
            <CubeIconOutline />
            <p className="mt-3 font-medium">Henüz ürün yok</p>
            <p className="text-sm mt-1">İlk ürününü eklemek için "Yeni Ürün" butonuna tıkla</p>
            <button onClick={openCreate} className="mt-4 px-5 py-2 bg-primary-600 text-white rounded-xl text-sm font-semibold">
              Ürün Ekle
            </button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50/50">
                  {['Ürün', 'Fiyat', 'Stok', 'Durum', 'İşlemler'].map((h) => (
                    <th key={h} className="px-5 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {products.map((p) => {
                  const img = resolveImg(p.photos?.[0] || p.images?.[0]);
                  return (
                    <tr key={p._id} className="hover:bg-primary-50/30 transition-colors">
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          {img ? (
                            <img src={img} alt={p.title} className="w-11 h-11 rounded-xl object-cover bg-gray-100" />
                          ) : (
                            <div className="w-11 h-11 rounded-xl bg-primary-50 flex items-center justify-center">
                              <PhotoIcon className="w-5 h-5 text-primary-300" />
                            </div>
                          )}
                          <div>
                            <p className="font-semibold text-gray-800 text-sm max-w-[200px] truncate">{p.title || p.name}</p>
                            {p.category && <p className="text-xs text-gray-400">{typeof p.category === 'object' ? p.category.name : p.category}</p>}
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4">
                        <span className="font-bold text-primary-700">₺{Number(p.price).toLocaleString('tr-TR')}</span>
                      </td>
                      <td className="px-5 py-4">
                        <span className={`text-sm font-semibold ${p.stock <= 0 ? 'text-red-600' : p.stock <= 5 ? 'text-amber-600' : 'text-gray-700'}`}>
                          {p.stock}
                        </span>
                      </td>
                      <td className="px-5 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${p.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                          {p.isActive ? 'Aktif' : 'Pasif'}
                        </span>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-1">
                          <button onClick={() => openEdit(p)} className="p-2 rounded-lg hover:bg-primary-100 text-primary-600 transition" title="Düzenle">
                            <PencilIcon className="w-4 h-4" />
                          </button>
                          <button onClick={() => toggleActive(p)} className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 transition" title={p.isActive ? 'Pasife Al' : 'Aktife Al'}>
                            {p.isActive ? <EyeSlashIcon className="w-4 h-4" /> : <EyeIcon className="w-4 h-4" />}
                          </button>
                          <button onClick={() => setDeleteId(p._id)} className="p-2 rounded-lg hover:bg-red-100 text-red-500 transition" title="Sil">
                            <TrashIcon className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Create/Edit Modal */}
      {showForm && (
        <Modal title={editing ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle'} onClose={closeForm}>
          <form onSubmit={handleSubmit} className="space-y-4">
            <Field label="Ürün Adı *" required value={form.name} onChange={(v) => setForm({ ...form, name: v })} placeholder="Örn: Köpek Maması 3kg" />
            <div className="grid grid-cols-2 gap-4">
              <Field label="Fiyat (₺) *" type="number" required value={form.price} onChange={(v) => setForm({ ...form, price: v })} placeholder="0.00" min="0" step="0.01" />
              <Field label="Stok" type="number" value={form.stock} onChange={(v) => setForm({ ...form, stock: v })} placeholder="0" min="0" />
            </div>
            <Field label="Kategori" value={form.category} onChange={(v) => setForm({ ...form, category: v })} placeholder="Örn: Mama & Atıştırmalık" />
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Açıklama</label>
              <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })}
                rows={3} placeholder="Ürün hakkında kısa açıklama..."
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent resize-none" />
            </div>
            {/* Image upload */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Fotoğraflar (max 5)</label>
              <div
                onClick={() => fileRef.current?.click()}
                className="border-2 border-dashed border-primary-200 rounded-xl p-4 text-center cursor-pointer hover:border-primary-400 hover:bg-primary-50/50 transition"
              >
                <ArrowUpTrayIcon className="w-8 h-8 mx-auto text-primary-300 mb-1" />
                <p className="text-sm text-gray-500">Fotoğraf seç veya sürükle bırak</p>
                <p className="text-xs text-gray-400">JPG, PNG, WEBP — Max 10MB</p>
                <input ref={fileRef} type="file" multiple accept="image/*" className="hidden" onChange={handleImageChange} />
              </div>
              {images.length > 0 && (
                <div className="flex gap-2 mt-2 flex-wrap">
                  {images.map((f, i) => (
                    <div key={i} className="relative w-16 h-16">
                      <img src={URL.createObjectURL(f)} className="w-full h-full object-cover rounded-lg" alt="" />
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="flex gap-3 pt-2">
              <button type="button" onClick={closeForm}
                className="flex-1 py-2.5 border border-gray-200 text-gray-600 rounded-xl text-sm font-semibold hover:bg-gray-50 transition">
                İptal
              </button>
              <button type="submit" disabled={saving}
                className="flex-1 py-2.5 bg-gradient-to-r from-primary-700 to-primary-500 text-white rounded-xl text-sm font-bold
                           disabled:opacity-60 shadow-lg shadow-primary-500/25 hover:shadow-primary-500/40 transition-all">
                {saving ? 'Kaydediliyor...' : editing ? 'Güncelle' : 'Oluştur'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* Delete confirm */}
      {deleteId && (
        <Modal title="Ürünü Sil" onClose={() => setDeleteId(null)} size="sm">
          <p className="text-gray-600 text-sm mb-5">Bu ürünü silmek istediğinden emin misin? Bu işlem geri alınamaz.</p>
          <div className="flex gap-3">
            <button onClick={() => setDeleteId(null)}
              className="flex-1 py-2.5 border border-gray-200 text-gray-600 rounded-xl text-sm font-semibold hover:bg-gray-50 transition">
              Vazgeç
            </button>
            <button onClick={confirmDelete}
              className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-bold hover:bg-red-600 transition">
              Evet, Sil
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function Field({ label, type = 'text', value, onChange, required, placeholder, min, step }) {
  return (
    <div>
      <label className="block text-sm font-semibold text-gray-700 mb-1.5">{label}</label>
      <input
        type={type} value={value} required={required} placeholder={placeholder} min={min} step={step}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition"
      />
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
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-100 text-gray-400 transition">
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

function CubeIconOutline() {
  return (
    <svg className="w-14 h-14 mx-auto text-gray-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
    </svg>
  );
}
