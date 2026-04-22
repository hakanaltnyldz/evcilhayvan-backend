import { useEffect, useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import api from '../api.js'

const defaultConfig = {
  fees: {
    storeCommissionRate: 12,
    sitterCommissionRate: 10,
    vetCommissionRate: 8,
    payoutReserveDays: 7,
    returnWindowDays: 14,
    freeShippingThreshold: 750,
  },
  features: {
    storeEnabled: true,
    sitterMatchingEnabled: true,
    vetAppointmentsEnabled: true,
    socialFeedEnabled: true,
    maintenanceMode: false,
  },
  moderation: {
    autoHideReportThreshold: 3,
    reviewSlaHours: 24,
    careReportReviewWindowHours: 48,
    escalateUserComplaintThreshold: 5,
  },
  contact: {
    supportEmail: '',
    supportPhone: '',
    supportWhatsapp: '',
  },
  announcement: {
    enabled: false,
    tone: 'info',
    message: '',
  },
}

function NumberField({ label, hint, value, onChange, suffix, min = 0, max, step = 1 }) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-semibold text-slate-700">{label}</span>
      <div className="rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-sm">
        <div className="flex items-center gap-3">
          <input
            type="number"
            value={value}
            min={min}
            max={max}
            step={step}
            onChange={(e) => onChange(Number(e.target.value))}
            className="w-full border-0 bg-transparent p-0 text-base font-semibold text-slate-900 focus:outline-none focus:ring-0"
          />
          {suffix ? <span className="text-sm font-medium text-slate-500">{suffix}</span> : null}
        </div>
        {hint ? <p className="mt-2 text-xs text-slate-500">{hint}</p> : null}
      </div>
    </label>
  )
}

function TextField({ label, hint, value, onChange, placeholder }) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-semibold text-slate-700">{label}</span>
      <div className="rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-sm">
        <input
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className="w-full border-0 bg-transparent p-0 text-base text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-0"
        />
        {hint ? <p className="mt-2 text-xs text-slate-500">{hint}</p> : null}
      </div>
    </label>
  )
}

function ToggleRow({ title, description, checked, onChange }) {
  return (
    <div className="flex items-start justify-between gap-4 rounded-2xl border border-slate-200 bg-white px-4 py-4 shadow-sm">
      <div>
        <p className="font-semibold text-slate-900">{title}</p>
        <p className="mt-1 text-sm text-slate-500">{description}</p>
      </div>
      <button
        type="button"
        onClick={() => onChange(!checked)}
        className={`relative mt-1 h-7 w-12 rounded-full transition ${
          checked ? 'bg-emerald-500' : 'bg-slate-300'
        }`}
      >
        <span
          className={`absolute top-1 h-5 w-5 rounded-full bg-white shadow transition ${
            checked ? 'left-6' : 'left-1'
          }`}
        />
      </button>
    </div>
  )
}

function Section({ title, subtitle, children }) {
  return (
    <section className="rounded-3xl border border-slate-200 bg-white/90 p-6 shadow-sm">
      <div className="mb-5">
        <h2 className="text-lg font-bold text-slate-900">{title}</h2>
        <p className="mt-1 text-sm text-slate-500">{subtitle}</p>
      </div>
      {children}
    </section>
  )
}

export default function PlatformSettings() {
  const [config, setConfig] = useState(defaultConfig)
  const [runtime, setRuntime] = useState(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [updatedAt, setUpdatedAt] = useState(null)
  const [updatedBy, setUpdatedBy] = useState(null)

  async function loadConfig() {
    setLoading(true)
    try {
      const res = await api.get('/admin/platform-config')
      const data = res.data || {}
      const nextConfig = data.config || defaultConfig
      setConfig({
        ...defaultConfig,
        ...nextConfig,
        fees: { ...defaultConfig.fees, ...(nextConfig.fees || {}) },
        features: { ...defaultConfig.features, ...(nextConfig.features || {}) },
        moderation: { ...defaultConfig.moderation, ...(nextConfig.moderation || {}) },
        contact: { ...defaultConfig.contact, ...(nextConfig.contact || {}) },
        announcement: { ...defaultConfig.announcement, ...(nextConfig.announcement || {}) },
      })
      setRuntime(data.runtime || null)
      setUpdatedAt(data.config?.updatedAt || null)
      setUpdatedBy(data.config?.updatedBy || null)
    } catch (err) {
      toast.error(err.response?.data?.message || 'Platform ayarlari alinamadi')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadConfig()
  }, [])

  function updateSection(section, key, value) {
    setConfig((prev) => ({
      ...prev,
      [section]: {
        ...prev[section],
        [key]: value,
      },
    }))
  }

  async function saveConfig() {
    setSaving(true)
    try {
      const res = await api.patch('/admin/platform-config', config)
      const nextConfig = res.data?.config || config
      setConfig({
        ...defaultConfig,
        ...nextConfig,
        fees: { ...defaultConfig.fees, ...(nextConfig.fees || {}) },
        features: { ...defaultConfig.features, ...(nextConfig.features || {}) },
        moderation: { ...defaultConfig.moderation, ...(nextConfig.moderation || {}) },
        contact: { ...defaultConfig.contact, ...(nextConfig.contact || {}) },
        announcement: { ...defaultConfig.announcement, ...(nextConfig.announcement || {}) },
      })
      setUpdatedAt(nextConfig.updatedAt || null)
      setUpdatedBy(nextConfig.updatedBy || null)
      toast.success('Platform ayarlari kaydedildi')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Kaydetme basarisiz')
    } finally {
      setSaving(false)
    }
  }

  const runtimeCards = useMemo(() => {
    if (!runtime) return []
    return [
      {
        label: 'Google Places',
        value: runtime.hasGooglePlacesApiKey ? 'Hazir' : 'Eksik',
        tone: runtime.hasGooglePlacesApiKey ? 'emerald' : 'amber',
      },
      {
        label: 'Mailer',
        value: runtime.hasMailerConfig ? 'Hazir' : 'Eksik',
        tone: runtime.hasMailerConfig ? 'emerald' : 'amber',
      },
      {
        label: 'Anthropic',
        value: runtime.hasAnthropicKey ? 'Hazir' : 'Eksik',
        tone: runtime.hasAnthropicKey ? 'emerald' : 'amber',
      },
      {
        label: 'Ortam',
        value: runtime.env || 'unknown',
        tone: 'slate',
      },
    ]
  }, [runtime])

  return (
    <div className="space-y-6">
      <div className="rounded-3xl bg-gradient-to-r from-slate-950 via-slate-900 to-indigo-950 p-6 text-white shadow-xl">
        <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-indigo-200">Platform Config</p>
            <h1 className="mt-2 text-3xl font-black">Platform Ayarlari</h1>
            <p className="mt-2 max-w-2xl text-sm text-slate-300">
              Komisyon oranlari, duyuru bari, feature toggle’lar ve moderasyon SLA’larini tek ekrandan yonetin.
            </p>
          </div>
          <div className="rounded-2xl bg-white/10 px-4 py-3 text-sm text-slate-200">
            <p>Son guncelleme</p>
            <p className="mt-1 font-semibold text-white">
              {updatedAt ? new Date(updatedAt).toLocaleString('tr-TR') : 'Kayit yok'}
            </p>
            <p className="mt-1 text-xs text-slate-300">
              {updatedBy?.name || updatedBy?.email || 'Sistem varsayilani'}
            </p>
          </div>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {runtimeCards.map((card) => (
          <div key={card.label} className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <p className="text-sm text-slate-500">{card.label}</p>
            <p
              className={`mt-3 text-2xl font-black ${
                card.tone === 'emerald'
                  ? 'text-emerald-600'
                  : card.tone === 'amber'
                    ? 'text-amber-600'
                    : 'text-slate-900'
              }`}
            >
              {card.value}
            </p>
          </div>
        ))}
      </div>

      {loading ? (
        <div className="rounded-3xl border border-slate-200 bg-white p-12 text-center text-slate-400 shadow-sm">
          Yukleniyor...
        </div>
      ) : (
        <>
          <div className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
            <Section title="Gelir ve Operasyon" subtitle="Komisyon, iade ve payout ayarlarini canli ortam icin burada tutun.">
              <div className="grid gap-4 md:grid-cols-2">
                <NumberField
                  label="Store komisyonu"
                  suffix="%"
                  value={config.fees.storeCommissionRate}
                  onChange={(value) => updateSection('fees', 'storeCommissionRate', value)}
                />
                <NumberField
                  label="Bakici komisyonu"
                  suffix="%"
                  value={config.fees.sitterCommissionRate}
                  onChange={(value) => updateSection('fees', 'sitterCommissionRate', value)}
                />
                <NumberField
                  label="Veteriner komisyonu"
                  suffix="%"
                  value={config.fees.vetCommissionRate}
                  onChange={(value) => updateSection('fees', 'vetCommissionRate', value)}
                />
                <NumberField
                  label="Payout bekleme gunu"
                  suffix="gun"
                  value={config.fees.payoutReserveDays}
                  onChange={(value) => updateSection('fees', 'payoutReserveDays', value)}
                />
                <NumberField
                  label="Iade suresi"
                  suffix="gun"
                  value={config.fees.returnWindowDays}
                  onChange={(value) => updateSection('fees', 'returnWindowDays', value)}
                />
                <NumberField
                  label="Ucretsiz kargo esigi"
                  suffix="TL"
                  value={config.fees.freeShippingThreshold}
                  onChange={(value) => updateSection('fees', 'freeShippingThreshold', value)}
                />
              </div>
            </Section>

            <Section title="Canli Ozellikler" subtitle="Rol bazli ana urun akislarini kapatip acabilirsiniz.">
              <div className="space-y-3">
                <ToggleRow
                  title="Magaza modulu"
                  description="Store ana sayfasi, urun listeleme ve siparis akislarini ac/kapat."
                  checked={config.features.storeEnabled}
                  onChange={(value) => updateSection('features', 'storeEnabled', value)}
                />
                <ToggleRow
                  title="Bakici eslestirme"
                  description="Bakici bulma ve rezervasyon akislarinin gorunurlugunu yonet."
                  checked={config.features.sitterMatchingEnabled}
                  onChange={(value) => updateSection('features', 'sitterMatchingEnabled', value)}
                />
                <ToggleRow
                  title="Veteriner randevulari"
                  description="Klinik ve randevu tarafini sistem genelinde aktif tut."
                  checked={config.features.vetAppointmentsEnabled}
                  onChange={(value) => updateSection('features', 'vetAppointmentsEnabled', value)}
                />
                <ToggleRow
                  title="Sosyal akis"
                  description="Post, yorum ve topluluk akislarini kapatmadan once burayi kullan."
                  checked={config.features.socialFeedEnabled}
                  onChange={(value) => updateSection('features', 'socialFeedEnabled', value)}
                />
                <ToggleRow
                  title="Bakim modu"
                  description="Kritik operasyon disinda tum urun akislarini sinirlandirmak icin kullan."
                  checked={config.features.maintenanceMode}
                  onChange={(value) => updateSection('features', 'maintenanceMode', value)}
                />
              </div>
            </Section>
          </div>

          <div className="grid gap-6 xl:grid-cols-[0.95fr_1.05fr]">
            <Section title="Moderasyon ve SLA" subtitle="Operasyon ekibinin ne kadar hizli reaksiyon vermesi gerektigini ve otomatik esikleri belirleyin.">
              <div className="grid gap-4 md:grid-cols-2">
                <NumberField
                  label="Auto-hide esigi"
                  suffix="sikayet"
                  value={config.moderation.autoHideReportThreshold}
                  onChange={(value) => updateSection('moderation', 'autoHideReportThreshold', value)}
                />
                <NumberField
                  label="Moderasyon SLA"
                  suffix="saat"
                  value={config.moderation.reviewSlaHours}
                  onChange={(value) => updateSection('moderation', 'reviewSlaHours', value)}
                />
                <NumberField
                  label="Bakim raporu pencere"
                  suffix="saat"
                  value={config.moderation.careReportReviewWindowHours}
                  onChange={(value) => updateSection('moderation', 'careReportReviewWindowHours', value)}
                />
                <NumberField
                  label="Escalation esigi"
                  suffix="adet"
                  value={config.moderation.escalateUserComplaintThreshold}
                  onChange={(value) => updateSection('moderation', 'escalateUserComplaintThreshold', value)}
                />
              </div>
            </Section>

            <Section title="Destek ve Duyuru" subtitle="Operasyon ekibinin kullandigi iletisim bilgileri ve kullaniciya giden sistem banner'i.">
              <div className="grid gap-4">
                <div className="grid gap-4 md:grid-cols-2">
                  <TextField
                    label="Destek email"
                    value={config.contact.supportEmail}
                    placeholder="destek@alanadi.com"
                    onChange={(value) => updateSection('contact', 'supportEmail', value)}
                  />
                  <TextField
                    label="Destek telefonu"
                    value={config.contact.supportPhone}
                    placeholder="+90 5xx xxx xx xx"
                    onChange={(value) => updateSection('contact', 'supportPhone', value)}
                  />
                </div>
                <TextField
                  label="WhatsApp hatti"
                  value={config.contact.supportWhatsapp}
                  placeholder="+90 5xx xxx xx xx"
                  onChange={(value) => updateSection('contact', 'supportWhatsapp', value)}
                />
                <div className="grid gap-4 md:grid-cols-[0.35fr_0.65fr]">
                  <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                    <p className="text-sm font-semibold text-slate-700">Duyuru durumu</p>
                    <div className="mt-3">
                      <ToggleRow
                        title={config.announcement.enabled ? 'Aktif' : 'Pasif'}
                        description="Kullanici tarafinda ust banner gorunsun."
                        checked={config.announcement.enabled}
                        onChange={(value) => updateSection('announcement', 'enabled', value)}
                      />
                    </div>
                  </div>
                  <div className="space-y-4">
                    <label className="block">
                      <span className="mb-2 block text-sm font-semibold text-slate-700">Duyuru tonu</span>
                      <select
                        value={config.announcement.tone}
                        onChange={(e) => updateSection('announcement', 'tone', e.target.value)}
                        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-900 shadow-sm focus:border-indigo-300 focus:outline-none"
                      >
                        <option value="info">Bilgi</option>
                        <option value="warning">Uyari</option>
                        <option value="success">Basari</option>
                      </select>
                    </label>
                    <label className="block">
                      <span className="mb-2 block text-sm font-semibold text-slate-700">Banner mesaji</span>
                      <textarea
                        rows={4}
                        value={config.announcement.message}
                        onChange={(e) => updateSection('announcement', 'message', e.target.value)}
                        placeholder="Kullanicilarin gorecegi kisa sistem duyurusu"
                        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm focus:border-indigo-300 focus:outline-none"
                      />
                    </label>
                  </div>
                </div>
              </div>
            </Section>
          </div>

          <div className="flex flex-wrap items-center justify-end gap-3">
            <button
              type="button"
              onClick={loadConfig}
              className="rounded-2xl border border-slate-200 bg-white px-5 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
            >
              Sunucudan Yenile
            </button>
            <button
              type="button"
              onClick={saveConfig}
              disabled={saving}
              className="rounded-2xl bg-indigo-600 px-5 py-3 text-sm font-semibold text-white shadow-lg shadow-indigo-200 transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {saving ? 'Kaydediliyor...' : 'Degisiklikleri Kaydet'}
            </button>
          </div>
        </>
      )}
    </div>
  )
}
