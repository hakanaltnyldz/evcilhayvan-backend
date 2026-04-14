import { useEffect, useState } from 'react'
import {
  EyeIcon,
  EyeSlashIcon,
  PencilSquareIcon,
  PlusIcon,
  TicketIcon,
  TrashIcon,
} from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'
import api from '../../api.js'

const emptyForm = {
  code: '',
  discountType: 'percentage',
  discountValue: '',
  minPurchaseAmount: '',
  usageLimit: '',
  validFrom: '',
  validUntil: '',
  description: '',
}

export default function SellerCoupons() {
  const [coupons, setCoupons] = useState([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingCoupon, setEditingCoupon] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)

  useEffect(() => {
    loadCoupons()
  }, [])

  async function loadCoupons() {
    setLoading(true)
    try {
      const response = await api.get('/seller/coupons')
      setCoupons(response.data?.coupons || [])
    } catch (error) {
      toast.error(error.response?.data?.message || 'Kuponlar yuklenemedi')
    } finally {
      setLoading(false)
    }
  }

  function openCreateModal() {
    setEditingCoupon(null)
    setForm(emptyForm)
    setShowForm(true)
  }

  function openEditModal(coupon) {
    setEditingCoupon(coupon)
    setForm({
      code: coupon.code || '',
      discountType: coupon.discountType || 'percentage',
      discountValue: String(coupon.discountValue ?? ''),
      minPurchaseAmount: String(coupon.minPurchaseAmount ?? ''),
      usageLimit: String(coupon.usageLimit ?? ''),
      validFrom: coupon.validFrom ? String(coupon.validFrom).slice(0, 10) : '',
      validUntil: coupon.validUntil ? String(coupon.validUntil).slice(0, 10) : '',
      description: coupon.description || '',
    })
    setShowForm(true)
  }

  function closeForm() {
    setEditingCoupon(null)
    setForm(emptyForm)
    setShowForm(false)
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setSaving(true)
    try {
      const payload = {
        code: form.code.trim().toUpperCase(),
        discountType: form.discountType,
        discountValue: Number(form.discountValue),
        minPurchaseAmount: form.minPurchaseAmount ? Number(form.minPurchaseAmount) : 0,
        usageLimit: form.usageLimit ? Number(form.usageLimit) : undefined,
        validFrom: form.validFrom,
        validUntil: form.validUntil,
        description: form.description.trim(),
      }

      if (editingCoupon) {
        await api.put(`/seller/coupons/${editingCoupon._id}`, payload)
      } else {
        await api.post('/seller/coupons', payload)
      }

      toast.success(editingCoupon ? 'Kupon guncellendi' : 'Kupon olusturuldu')
      closeForm()
      loadCoupons()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Kaydetme islemi basarisiz')
    } finally {
      setSaving(false)
    }
  }

  async function toggleCoupon(coupon) {
    try {
      await api.patch(`/seller/coupons/${coupon._id}/toggle`)
      toast.success(coupon.isActive ? 'Kupon pasife alindi' : 'Kupon aktife alindi')
      loadCoupons()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Durum guncellenemedi')
    }
  }

  async function deleteCoupon() {
    if (!deleteTarget) return
    try {
      await api.delete(`/seller/coupons/${deleteTarget._id}`)
      toast.success('Kupon silindi')
      setDeleteTarget(null)
      loadCoupons()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Kupon silinemedi')
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 rounded-[32px] bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 p-6 text-white shadow-panel sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-primary-100">Promosyon</p>
          <h2 className="mt-2 text-3xl font-black">Kupon Yonetimi</h2>
          <p className="mt-2 max-w-2xl text-sm leading-7 text-primary-100">
            Kampanya kodlarini, kullanim limitlerini ve aktiflik durumunu bu ekrandan yonetin.
          </p>
        </div>
        <button
          type="button"
          onClick={openCreateModal}
          className="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-5 py-3 text-sm font-semibold text-primary-800 transition hover:bg-primary-50"
        >
          <PlusIcon className="h-5 w-5" />
          Yeni Kupon
        </button>
      </div>

      {loading ? (
        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 6 }).map((_, index) => (
            <div key={index} className="h-44 animate-pulse rounded-[32px] bg-slate-100" />
          ))}
        </div>
      ) : coupons.length === 0 ? (
        <div className="rounded-[32px] border border-white bg-white px-6 py-20 text-center shadow-panel">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-3xl bg-primary-50 text-primary-600">
            <TicketIcon className="h-8 w-8" />
          </div>
          <h3 className="mt-5 text-xl font-bold text-slate-900">Heniz kupon yok</h3>
          <p className="mt-2 text-sm leading-6 text-slate-500">
            Ilk kampanyanizi ayni panelden olusturup seller siparislerinize hizli etki edin.
          </p>
          <button
            type="button"
            onClick={openCreateModal}
            className="mt-5 rounded-2xl bg-primary-600 px-5 py-3 text-sm font-semibold text-white"
          >
            Kupon olustur
          </button>
        </div>
      ) : (
        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {coupons.map((coupon) => {
            const expired = Boolean(coupon.validUntil && new Date(coupon.validUntil) < new Date())
            return (
              <div key={coupon._id} className="rounded-[32px] border border-white bg-white p-5 shadow-panel">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <span className="inline-flex rounded-full bg-primary-50 px-3 py-1 font-mono text-sm font-bold tracking-[0.2em] text-primary-700">
                      {coupon.code}
                    </span>
                    {coupon.description ? (
                      <p className="mt-3 text-sm leading-6 text-slate-500">{coupon.description}</p>
                    ) : null}
                  </div>
                  <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${
                    coupon.isActive && !expired ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-600'
                  }`}>
                    {coupon.isActive && !expired ? 'Aktif' : expired ? 'Suresi doldu' : 'Pasif'}
                  </span>
                </div>

                <div className="mt-5 grid grid-cols-2 gap-3">
                  <InfoPill
                    label="Indirim"
                    value={coupon.discountType === 'percentage'
                      ? `%${coupon.discountValue}`
                      : `₺${Number(coupon.discountValue || 0).toLocaleString('tr-TR')}`}
                  />
                  <InfoPill label="Kullanim" value={`${coupon.usageCount || 0}/${coupon.usageLimit || '∞'}`} />
                  <InfoPill label="Min. Sepet" value={coupon.minPurchaseAmount ? `₺${coupon.minPurchaseAmount}` : 'Sinirsiz'} />
                  <InfoPill label="Bitis" value={coupon.validUntil ? new Date(coupon.validUntil).toLocaleDateString('tr-TR') : '—'} />
                </div>

                <div className="mt-5 flex gap-2 border-t border-slate-100 pt-4">
                  <ActionButton onClick={() => openEditModal(coupon)}>
                    <PencilSquareIcon className="h-4 w-4" />
                  </ActionButton>
                  <ActionButton onClick={() => toggleCoupon(coupon)}>
                    {coupon.isActive ? <EyeSlashIcon className="h-4 w-4" /> : <EyeIcon className="h-4 w-4" />}
                  </ActionButton>
                  <ActionButton onClick={() => setDeleteTarget(coupon)} danger>
                    <TrashIcon className="h-4 w-4" />
                  </ActionButton>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {showForm && (
        <Modal title={editingCoupon ? 'Kuponu duzenle' : 'Yeni kupon olustur'} onClose={closeForm}>
          <form onSubmit={handleSubmit} className="space-y-4">
            <Field label="Kupon kodu" value={form.code} onChange={(value) => setForm((current) => ({ ...current, code: value }))} required />

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="mb-1.5 block text-sm font-semibold text-slate-700">Indirim tipi</label>
                <select
                  value={form.discountType}
                  onChange={(event) => setForm((current) => ({ ...current, discountType: event.target.value }))}
                  className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
                >
                  <option value="percentage">Yuzde</option>
                  <option value="fixed">Sabit tutar</option>
                </select>
              </div>
              <Field label={form.discountType === 'percentage' ? 'Indirim orani (%)' : 'Indirim tutari'} type="number" value={form.discountValue} onChange={(value) => setForm((current) => ({ ...current, discountValue: value }))} required />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Min. alisveris" type="number" value={form.minPurchaseAmount} onChange={(value) => setForm((current) => ({ ...current, minPurchaseAmount: value }))} />
              <Field label="Toplam kullanim limiti" type="number" value={form.usageLimit} onChange={(value) => setForm((current) => ({ ...current, usageLimit: value }))} />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Baslangic tarihi" type="date" value={form.validFrom} onChange={(value) => setForm((current) => ({ ...current, validFrom: value }))} required />
              <Field label="Bitis tarihi" type="date" value={form.validUntil} onChange={(value) => setForm((current) => ({ ...current, validUntil: value }))} required />
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700">Aciklama</label>
              <textarea
                rows={3}
                value={form.description}
                onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))}
                className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
              />
            </div>

            <div className="flex gap-3 pt-2">
              <button type="button" onClick={closeForm} className="flex-1 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-600">
                Iptal
              </button>
              <button type="submit" disabled={saving} className="flex-1 rounded-2xl bg-primary-600 px-4 py-3 text-sm font-semibold text-white disabled:cursor-not-allowed disabled:opacity-60">
                {saving ? 'Kaydediliyor...' : editingCoupon ? 'Guncelle' : 'Olustur'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {deleteTarget && (
        <Modal title="Kuponu sil" onClose={() => setDeleteTarget(null)} size="sm">
          <p className="text-sm leading-6 text-slate-500">
            <span className="font-semibold text-slate-900">{deleteTarget.code}</span> kodunu silmek istediginizden emin misiniz?
          </p>
          <div className="mt-5 flex gap-3">
            <button type="button" onClick={() => setDeleteTarget(null)} className="flex-1 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-600">
              Vazgec
            </button>
            <button type="button" onClick={deleteCoupon} className="flex-1 rounded-2xl bg-rose-600 px-4 py-3 text-sm font-semibold text-white">
              Evet, sil
            </button>
          </div>
        </Modal>
      )}
    </div>
  )
}

function Field({ label, type = 'text', value, onChange, required = false }) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-semibold text-slate-700">{label}</label>
      <input
        type={type}
        value={value}
        required={required}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
      />
    </div>
  )
}

function InfoPill({ label, value }) {
  return (
    <div className="rounded-3xl bg-slate-50 px-4 py-3">
      <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400">{label}</p>
      <p className="mt-2 text-sm font-semibold text-slate-900">{value}</p>
    </div>
  )
}

function ActionButton({ children, danger = false, ...props }) {
  return (
    <button
      type="button"
      className={`inline-flex h-10 w-10 items-center justify-center rounded-2xl border transition ${
        danger ? 'border-rose-100 bg-rose-50 text-rose-600 hover:bg-rose-100' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-100'
      }`}
      {...props}
    >
      {children}
    </button>
  )
}

function Modal({ children, title, onClose, size = 'lg' }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-slate-950/50 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative max-h-[90vh] w-full overflow-y-auto rounded-[32px] bg-white shadow-2xl ${size === 'sm' ? 'max-w-md' : 'max-w-xl'}`}>
        <div className="sticky top-0 flex items-center justify-between border-b border-slate-100 bg-white px-6 py-5">
          <h3 className="text-lg font-bold text-slate-900">{title}</h3>
          <button type="button" onClick={onClose} className="rounded-xl p-2 text-slate-400 hover:bg-slate-100">
            ×
          </button>
        </div>
        <div className="p-6">{children}</div>
      </div>
    </div>
  )
}
