import { useEffect, useState, useRef } from 'react';
import toast from 'react-hot-toast';
import {
  BuildingStorefrontIcon, CameraIcon, GlobeAltIcon,
  PhoneIcon, LinkIcon,
} from '@heroicons/react/24/outline';
import api from '../api';

const DAYS = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
const EMPTY_HOURS = DAYS.reduce((acc, d) => {
  acc[d] = { open: false, start: '09:00', end: '18:00' };
  return acc;
}, {});

export default function StoreProfile() {
  const [store, setStore]     = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving]   = useState(false);
  const [form, setForm]       = useState({
    name: '', description: '', phone: '', website: '',
    instagram: '', twitter: '', facebook: '',
  });
  const [workingHours, setWorkingHours] = useState(EMPTY_HOURS);
  const [logoFile, setLogoFile]         = useState(null);
  const [bannerFile, setBannerFile]     = useState(null);
  const [logoPreview, setLogoPreview]   = useState(null);
  const [bannerPreview, setBannerPreview] = useState(null);
  const logoRef   = useRef();
  const bannerRef = useRef();

  const API_BASE  = import.meta.env.VITE_API_URL || 'http://localhost:3000';
  const resolveImg = (url) => !url ? null : url.startsWith('http') ? url : `${API_BASE}${url}`;

  const load = async () => {
    setLoading(true);
    try {
      const res = await api.get('/store/me');
      const s   = res.data?.store || res.data;
      setStore(s);
      setForm({
        name: s.name || '',
        description: s.description || '',
        phone: s.phone || '',
        website: s.website || '',
        instagram: s.instagram || '',
        twitter: s.twitter || '',
        facebook: s.facebook || '',
      });
      if (s.workingHours && typeof s.workingHours === 'object') {
        setWorkingHours({ ...EMPTY_HOURS, ...s.workingHours });
      }
    } catch { toast.error('Mağaza bilgileri yüklenemedi'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const handleImageChange = (e, type) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const preview = URL.createObjectURL(file);
    if (type === 'logo') { setLogoFile(file); setLogoPreview(preview); }
    else { setBannerFile(file); setBannerPreview(preview); }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const fd = new FormData();
      Object.entries(form).forEach(([k, v]) => v !== '' && fd.append(k, v));
      fd.append('workingHours', JSON.stringify(workingHours));
      if (logoFile)   fd.append('logo',   logoFile);
      if (bannerFile) fd.append('banner', bannerFile);

      await api.patch('/store/me/profile', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      toast.success('Mağaza profili güncellendi');
      setLogoFile(null);
      setBannerFile(null);
      load();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Güncelleme başarısız');
    } finally { setSaving(false); }
  };

  const toggleDay = (day) =>
    setWorkingHours((h) => ({ ...h, [day]: { ...h[day], open: !h[day].open } }));

  const updateHour = (day, field, value) =>
    setWorkingHours((h) => ({ ...h, [day]: { ...h[day], [field]: value } }));

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="h-48 bg-white rounded-2xl animate-pulse border border-gray-100" />
        <div className="h-64 bg-white rounded-2xl animate-pulse border border-gray-100" />
      </div>
    );
  }

  const currentLogo   = logoPreview   || resolveImg(store?.logoUrl);
  const currentBanner = bannerPreview || resolveImg(store?.bannerUrl);

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-primary-800">Mağaza Profili</h1>
        <p className="text-gray-500 text-sm mt-0.5">Mağazanın görünümünü ve bilgilerini düzenle</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">

        {/* Banner + Logo */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          {/* Banner */}
          <div
            className="relative h-40 bg-gradient-to-r from-primary-700 to-primary-400 cursor-pointer group"
            onClick={() => bannerRef.current?.click()}
          >
            {currentBanner ? (
              <img src={currentBanner} className="w-full h-full object-cover" alt="Banner" />
            ) : (
              <div className="flex flex-col items-center justify-center h-full text-white/60">
                <CameraIcon className="w-8 h-8 mb-1" />
                <p className="text-sm">Banner ekle</p>
              </div>
            )}
            <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 flex items-center justify-center transition">
              <CameraIcon className="w-8 h-8 text-white opacity-0 group-hover:opacity-100 transition" />
            </div>
            <input ref={bannerRef} type="file" accept="image/*" className="hidden" onChange={(e) => handleImageChange(e, 'banner')} />
          </div>

          {/* Logo */}
          <div className="px-6 pb-5">
            <div className="flex items-end gap-4 -mt-8 mb-4">
              <div
                className="relative w-20 h-20 rounded-2xl border-4 border-white shadow-lg cursor-pointer group bg-primary-50 flex-shrink-0"
                onClick={() => logoRef.current?.click()}
              >
                {currentLogo ? (
                  <img src={currentLogo} className="w-full h-full rounded-xl object-cover" alt="Logo" />
                ) : (
                  <BuildingStorefrontIcon className="w-10 h-10 text-primary-300 m-auto mt-4" />
                )}
                <div className="absolute inset-0 rounded-xl bg-black/0 group-hover:bg-black/20 flex items-center justify-center transition">
                  <CameraIcon className="w-5 h-5 text-white opacity-0 group-hover:opacity-100 transition" />
                </div>
                <input ref={logoRef} type="file" accept="image/*" className="hidden" onChange={(e) => handleImageChange(e, 'logo')} />
              </div>
              <div>
                <p className="font-bold text-gray-800">{form.name || 'Mağaza Adı'}</p>
                <p className="text-sm text-gray-400">Logo ve banner'a tıklayarak değiştir</p>
              </div>
            </div>
          </div>
        </div>

        {/* Basic Info */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
          <h2 className="font-bold text-gray-800 mb-4">Temel Bilgiler</h2>
          <div className="space-y-4">
            <Field label="Mağaza Adı *" required value={form.name}
              onChange={(v) => setForm({ ...form, name: v })} placeholder="Örn: PatiShop" />
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Açıklama</label>
              <textarea
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                rows={3} placeholder="Mağazanı kısaca tanıt..."
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none"
              />
            </div>
          </div>
        </div>

        {/* Contact */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
          <h2 className="font-bold text-gray-800 mb-4 flex items-center gap-2">
            <PhoneIcon className="w-5 h-5 text-primary-500" /> İletişim
          </h2>
          <div className="grid sm:grid-cols-2 gap-4">
            <Field label="Telefon" value={form.phone} onChange={(v) => setForm({ ...form, phone: v })}
              placeholder="+90 5xx xxx xx xx" />
            <Field label="Website" value={form.website} onChange={(v) => setForm({ ...form, website: v })}
              placeholder="https://example.com" />
          </div>
        </div>

        {/* Social */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
          <h2 className="font-bold text-gray-800 mb-4 flex items-center gap-2">
            <GlobeAltIcon className="w-5 h-5 text-primary-500" /> Sosyal Medya
          </h2>
          <div className="space-y-4">
            <SocialField icon="📸" label="Instagram" value={form.instagram}
              onChange={(v) => setForm({ ...form, instagram: v })} placeholder="@kullanici_adi" />
            <SocialField icon="𝕏" label="Twitter / X" value={form.twitter}
              onChange={(v) => setForm({ ...form, twitter: v })} placeholder="@kullanici_adi" />
            <SocialField icon="👍" label="Facebook" value={form.facebook}
              onChange={(v) => setForm({ ...form, facebook: v })} placeholder="facebook.com/sayfan" />
          </div>
        </div>

        {/* Working Hours */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
          <h2 className="font-bold text-gray-800 mb-4">Çalışma Saatleri</h2>
          <div className="space-y-2">
            {DAYS.map((day) => {
              const h = workingHours[day] || { open: false, start: '09:00', end: '18:00' };
              return (
                <div key={day} className="flex items-center gap-4 py-2 border-b border-gray-50 last:border-0">
                  <button
                    type="button"
                    onClick={() => toggleDay(day)}
                    className={`w-10 h-5 rounded-full transition-colors flex-shrink-0 relative ${h.open ? 'bg-primary-500' : 'bg-gray-200'}`}
                  >
                    <span className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform ${h.open ? 'translate-x-5' : 'translate-x-0.5'}`} />
                  </button>
                  <span className={`text-sm font-medium w-24 ${h.open ? 'text-gray-800' : 'text-gray-400'}`}>{day}</span>
                  {h.open ? (
                    <div className="flex items-center gap-2 text-sm">
                      <input type="time" value={h.start}
                        onChange={(e) => updateHour(day, 'start', e.target.value)}
                        className="border border-gray-200 rounded-lg px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-primary-500" />
                      <span className="text-gray-400">—</span>
                      <input type="time" value={h.end}
                        onChange={(e) => updateHour(day, 'end', e.target.value)}
                        className="border border-gray-200 rounded-lg px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-primary-500" />
                    </div>
                  ) : (
                    <span className="text-xs text-gray-400">Kapalı</span>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Save */}
        <div className="flex justify-end">
          <button
            type="submit" disabled={saving}
            className="px-8 py-3 bg-gradient-to-r from-primary-700 to-primary-500 text-white rounded-xl font-bold text-sm shadow-lg shadow-primary-500/25 hover:shadow-primary-500/40 disabled:opacity-60 transition-all"
          >
            {saving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet'}
          </button>
        </div>
      </form>
    </div>
  );
}

function Field({ label, required, value, onChange, placeholder, type = 'text' }) {
  return (
    <div>
      <label className="block text-sm font-semibold text-gray-700 mb-1.5">{label}</label>
      <input
        type={type} required={required} value={value} placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 transition"
      />
    </div>
  );
}

function SocialField({ icon, label, value, onChange, placeholder }) {
  return (
    <div className="flex items-center gap-3">
      <span className="text-xl w-8 text-center">{icon}</span>
      <div className="flex-1">
        <label className="block text-xs text-gray-500 mb-0.5">{label}</label>
        <input
          value={value} placeholder={placeholder}
          onChange={(e) => onChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 transition"
        />
      </div>
    </div>
  );
}
