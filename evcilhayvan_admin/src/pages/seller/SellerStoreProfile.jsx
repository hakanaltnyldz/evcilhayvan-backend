import { useEffect, useRef, useState } from 'react'
import {
  BuildingStorefrontIcon,
  CameraIcon,
  GlobeAltIcon,
  PhoneIcon,
} from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'
import api from '../../api.js'
import { resolveMediaUrl } from '../../lib/media.js'

const days = ['Pazartesi', 'Sali', 'Carsamba', 'Persembe', 'Cuma', 'Cumartesi', 'Pazar']

const createEmptyHours = () =>
  days.reduce((accumulator, day) => {
    accumulator[day] = { open: false, start: '09:00', end: '18:00' }
    return accumulator
  }, {})

export default function SellerStoreProfile() {
  const [store, setStore] = useState(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({
    name: '',
    description: '',
    phone: '',
    website: '',
    instagram: '',
    twitter: '',
    facebook: '',
  })
  const [workingHours, setWorkingHours] = useState(createEmptyHours())
  const [logoFile, setLogoFile] = useState(null)
  const [bannerFile, setBannerFile] = useState(null)
  const [logoPreview, setLogoPreview] = useState(null)
  const [bannerPreview, setBannerPreview] = useState(null)
  const logoInputRef = useRef(null)
  const bannerInputRef = useRef(null)

  useEffect(() => {
    loadStore()
  }, [])

  async function loadStore() {
    setLoading(true)
    try {
      const response = await api.get('/store/me')
      const storeData = response.data?.store || null
      setStore(storeData)
      setForm({
        name: storeData?.name || '',
        description: storeData?.description || '',
        phone: storeData?.phone || '',
        website: storeData?.website || '',
        instagram: storeData?.instagram || '',
        twitter: storeData?.twitter || '',
        facebook: storeData?.facebook || '',
      })
      setWorkingHours(parseWorkingHours(storeData?.workingHours))
    } catch (error) {
      toast.error(error.response?.data?.message || 'Magaza bilgileri yuklenemedi')
    } finally {
      setLoading(false)
    }
  }

  function handleImageChange(event, type) {
    const file = event.target.files?.[0]
    if (!file) return

    const preview = URL.createObjectURL(file)
    if (type === 'logo') {
      setLogoFile(file)
      setLogoPreview(preview)
      return
    }

    setBannerFile(file)
    setBannerPreview(preview)
  }

  function toggleDay(day) {
    setWorkingHours((current) => ({
      ...current,
      [day]: {
        ...current[day],
        open: !current[day].open,
      },
    }))
  }

  function updateHour(day, field, value) {
    setWorkingHours((current) => ({
      ...current,
      [day]: {
        ...current[day],
        [field]: value,
      },
    }))
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setSaving(true)

    try {
      const payload = new FormData()
      Object.entries(form).forEach(([key, value]) => {
        payload.append(key, value)
      })
      payload.append('workingHours', JSON.stringify(workingHours))

      if (logoFile) payload.append('logo', logoFile)
      if (bannerFile) payload.append('banner', bannerFile)

      await api.patch('/store/me/profile', payload, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })

      toast.success('Magaza profili guncellendi')
      setLogoFile(null)
      setBannerFile(null)
      loadStore()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Profil guncellenemedi')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="h-48 animate-pulse rounded-[32px] bg-slate-100" />
        <div className="h-80 animate-pulse rounded-[32px] bg-slate-100" />
      </div>
    )
  }

  const currentLogo = logoPreview || resolveMediaUrl(store?.logoUrl)
  const currentBanner = bannerPreview || resolveMediaUrl(store?.bannerUrl)

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="rounded-[32px] bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 p-6 text-white shadow-panel">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-primary-100">Magaza Vitrini</p>
        <h2 className="mt-2 text-3xl font-black">Magaza Profilini Duzenle</h2>
        <p className="mt-2 max-w-3xl text-sm leading-7 text-primary-100">
          Logo, banner, iletisim, sosyal linkler ve calisma saatleri seller workspace icinde ayni yerde.
        </p>
      </div>

      <section className="overflow-hidden rounded-[32px] border border-white bg-white shadow-panel">
        <div
          className="relative h-52 cursor-pointer bg-gradient-to-r from-primary-700 to-primary-400"
          onClick={() => bannerInputRef.current?.click()}
        >
          {currentBanner ? (
            <img src={currentBanner} alt="banner" className="h-full w-full object-cover" />
          ) : (
            <div className="flex h-full flex-col items-center justify-center text-primary-50/80">
              <CameraIcon className="h-9 w-9" />
              <p className="mt-2 text-sm font-semibold">Banner eklemek icin tikla</p>
            </div>
          )}
          <div className="absolute inset-0 bg-slate-950/0 transition hover:bg-slate-950/15" />
          <input ref={bannerInputRef} type="file" accept="image/*" className="hidden" onChange={(event) => handleImageChange(event, 'banner')} />
        </div>

        <div className="px-6 pb-6">
          <div className="-mt-10 flex flex-col gap-4 sm:flex-row sm:items-end">
            <button
              type="button"
              onClick={() => logoInputRef.current?.click()}
              className="relative flex h-24 w-24 items-center justify-center overflow-hidden rounded-[28px] border-4 border-white bg-primary-50 shadow-lg"
            >
              {currentLogo ? (
                <img src={currentLogo} alt="logo" className="h-full w-full object-cover" />
              ) : (
                <BuildingStorefrontIcon className="h-10 w-10 text-primary-300" />
              )}
              <div className="absolute inset-0 flex items-center justify-center bg-slate-950/0 text-white transition hover:bg-slate-950/25">
                <CameraIcon className="h-6 w-6 opacity-0 transition hover:opacity-100" />
              </div>
            </button>
            <div>
              <p className="text-lg font-bold text-slate-900">{form.name || 'Magaza adi'}</p>
              <p className="mt-1 text-sm text-slate-500">Logo ve banner alanlari artik dogrudan bu panelden guncellenir.</p>
            </div>
          </div>
          <input ref={logoInputRef} type="file" accept="image/*" className="hidden" onChange={(event) => handleImageChange(event, 'logo')} />
        </div>
      </section>

      <section className="grid gap-6 xl:grid-cols-[1fr_0.95fr]">
        <div className="space-y-6">
          <Card title="Temel Bilgiler" icon={<BuildingStorefrontIcon className="h-5 w-5" />}>
            <Field label="Magaza adi" value={form.name} onChange={(value) => setForm((current) => ({ ...current, name: value }))} required />
            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700">Aciklama</label>
              <textarea
                rows={4}
                value={form.description}
                onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))}
                className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
              />
            </div>
          </Card>

          <Card title="Iletisim" icon={<PhoneIcon className="h-5 w-5" />}>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Telefon" value={form.phone} onChange={(value) => setForm((current) => ({ ...current, phone: value }))} />
              <Field label="Website" value={form.website} onChange={(value) => setForm((current) => ({ ...current, website: value }))} />
            </div>
          </Card>

          <Card title="Sosyal Linkler" icon={<GlobeAltIcon className="h-5 w-5" />}>
            <Field label="Instagram" value={form.instagram} onChange={(value) => setForm((current) => ({ ...current, instagram: value }))} />
            <Field label="Twitter / X" value={form.twitter} onChange={(value) => setForm((current) => ({ ...current, twitter: value }))} />
            <Field label="Facebook" value={form.facebook} onChange={(value) => setForm((current) => ({ ...current, facebook: value }))} />
          </Card>
        </div>

        <Card title="Calisma Saatleri" icon={<PhoneIcon className="h-5 w-5" />}>
          <div className="space-y-3">
            {days.map((day) => {
              const currentDay = workingHours[day]
              return (
                <div key={day} className="rounded-3xl border border-slate-100 bg-slate-50 px-4 py-4">
                  <div className="flex items-center justify-between gap-4">
                    <div>
                      <p className="font-semibold text-slate-900">{day}</p>
                      <p className="mt-1 text-xs text-slate-500">
                        {currentDay.open ? `${currentDay.start} - ${currentDay.end}` : 'Kapali'}
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={() => toggleDay(day)}
                      className={`relative h-6 w-12 rounded-full transition ${
                        currentDay.open ? 'bg-primary-500' : 'bg-slate-200'
                      }`}
                    >
                      <span className={`absolute top-1 h-4 w-4 rounded-full bg-white shadow transition ${
                        currentDay.open ? 'left-7' : 'left-1'
                      }`} />
                    </button>
                  </div>

                  {currentDay.open ? (
                    <div className="mt-4 grid gap-3 sm:grid-cols-2">
                      <TimeField label="Baslangic" value={currentDay.start} onChange={(value) => updateHour(day, 'start', value)} />
                      <TimeField label="Bitis" value={currentDay.end} onChange={(value) => updateHour(day, 'end', value)} />
                    </div>
                  ) : null}
                </div>
              )
            })}
          </div>
        </Card>
      </section>

      <div className="flex justify-end">
        <button
          type="submit"
          disabled={saving}
          className="rounded-2xl bg-primary-600 px-6 py-3 text-sm font-semibold text-white shadow-panel transition hover:bg-primary-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {saving ? 'Kaydediliyor...' : 'Degisiklikleri kaydet'}
        </button>
      </div>
    </form>
  )
}

function Card({ children, title, icon }) {
  return (
    <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
      <div className="mb-5 flex items-center gap-3">
        <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary-50 text-primary-700">
          {icon}
        </div>
        <h3 className="text-lg font-bold text-slate-900">{title}</h3>
      </div>
      <div className="space-y-4">{children}</div>
    </div>
  )
}

function Field({ label, value, onChange, required = false }) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-semibold text-slate-700">{label}</label>
      <input
        value={value}
        required={required}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
      />
    </div>
  )
}

function TimeField({ label, value, onChange }) {
  return (
    <div>
      <label className="mb-1.5 block text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{label}</label>
      <input
        type="time"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
      />
    </div>
  )
}

function parseWorkingHours(rawValue) {
  if (!rawValue) return createEmptyHours()
  if (typeof rawValue === 'object') return { ...createEmptyHours(), ...rawValue }

  try {
    return { ...createEmptyHours(), ...(JSON.parse(rawValue) || {}) }
  } catch {
    return createEmptyHours()
  }
}
