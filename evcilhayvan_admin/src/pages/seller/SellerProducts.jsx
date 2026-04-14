import { useEffect, useRef, useState } from 'react'
import {
  EyeIcon,
  EyeSlashIcon,
  PencilSquareIcon,
  PhotoIcon,
  PlusIcon,
  TrashIcon,
} from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'
import api from '../../api.js'
import { resolveMediaUrl } from '../../lib/media.js'

const emptyForm = {
  name: '',
  description: '',
  price: '',
  stock: '',
  category: '',
}

export default function SellerProducts() {
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingProduct, setEditingProduct] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const [images, setImages] = useState([])
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const imageInputRef = useRef(null)

  useEffect(() => {
    loadProducts()
    loadCategories()
  }, [])

  async function loadProducts() {
    setLoading(true)
    try {
      const response = await api.get('/seller/products')
      setProducts(response.data?.products || [])
    } catch (error) {
      toast.error(error.response?.data?.message || 'Urunler yuklenemedi')
    } finally {
      setLoading(false)
    }
  }

  async function loadCategories() {
    try {
      const response = await api.get('/store/categories')
      setCategories(response.data?.categories || [])
    } catch {
      setCategories([])
    }
  }

  function openCreateModal() {
    setEditingProduct(null)
    setForm(emptyForm)
    setImages([])
    setShowForm(true)
  }

  function openEditModal(product) {
    setEditingProduct(product)
    setForm({
      name: product.name || product.title || '',
      description: product.description || '',
      price: String(product.price ?? ''),
      stock: String(product.stock ?? 0),
      category: product.category?._id || product.category || '',
    })
    setImages([])
    setShowForm(true)
  }

  function closeForm() {
    setEditingProduct(null)
    setForm(emptyForm)
    setImages([])
    setShowForm(false)
  }

  function handleImageSelection(event) {
    const files = Array.from(event.target.files || []).slice(0, 5)
    setImages(files)
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setSaving(true)

    try {
      if (!form.name.trim() || !form.price) {
        toast.error('Urun adi ve fiyat zorunlu')
        return
      }

      if (images.length > 0) {
        const payload = new FormData()
        payload.append('name', form.name.trim())
        payload.append('description', form.description.trim())
        payload.append('price', String(Number(form.price)))
        payload.append('stock', String(Number(form.stock || 0)))
        if (form.category) payload.append('category', form.category)
        images.forEach((file) => payload.append('images', file))

        if (editingProduct) {
          await api.patch(`/seller/products/${editingProduct._id}`, payload, {
            headers: { 'Content-Type': 'multipart/form-data' },
          })
        } else {
          await api.post('/seller/products/with-images', payload, {
            headers: { 'Content-Type': 'multipart/form-data' },
          })
        }
      } else {
        const payload = {
          name: form.name.trim(),
          description: form.description.trim(),
          price: Number(form.price),
          stock: Number(form.stock || 0),
          ...(form.category ? { category: form.category } : {}),
        }

        if (editingProduct) {
          await api.patch(`/seller/products/${editingProduct._id}`, payload)
        } else {
          await api.post('/seller/products', payload)
        }
      }

      toast.success(editingProduct ? 'Urun guncellendi' : 'Urun olusturuldu')
      closeForm()
      loadProducts()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Kaydetme islemi basarisiz')
    } finally {
      setSaving(false)
    }
  }

  async function toggleActive(product) {
    try {
      await api.patch(`/seller/products/${product._id}/toggle-active`)
      toast.success(product.isActive ? 'Urun pasife alindi' : 'Urun aktife alindi')
      loadProducts()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Islem basarisiz')
    }
  }

  async function deleteProduct() {
    if (!deleteTarget) return
    try {
      await api.delete(`/seller/products/${deleteTarget._id}`)
      toast.success('Urun silindi')
      setDeleteTarget(null)
      loadProducts()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Silme islemi basarisiz')
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 rounded-[32px] bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 p-6 text-white shadow-panel sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-primary-100">Katalog</p>
          <h2 className="mt-2 text-3xl font-black">Urun Yonetimi</h2>
          <p className="mt-2 max-w-2xl text-sm leading-7 text-primary-100">
            Urun ekleme, duzenleme, stok ve gorunurluk islemleri ayni ekranda toplandi.
          </p>
        </div>
        <button
          type="button"
          onClick={openCreateModal}
          className="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-5 py-3 text-sm font-semibold text-primary-800 transition hover:bg-primary-50"
        >
          <PlusIcon className="h-5 w-5" />
          Yeni Urun
        </button>
      </div>

      <div className="overflow-hidden rounded-[32px] border border-white bg-white shadow-panel">
        {loading ? (
          <div className="space-y-3 p-6">
            {Array.from({ length: 5 }).map((_, index) => (
              <div key={index} className="h-16 animate-pulse rounded-3xl bg-slate-100" />
            ))}
          </div>
        ) : products.length === 0 ? (
          <div className="flex flex-col items-center justify-center px-6 py-20 text-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-3xl bg-primary-50 text-primary-500">
              <PhotoIcon className="h-8 w-8" />
            </div>
            <h3 className="mt-5 text-xl font-bold text-slate-900">Katalog henuz bos</h3>
            <p className="mt-2 max-w-md text-sm leading-6 text-slate-500">
              Yeni urun ekleyerek seller workspace icinden katalog, stok ve gorsel akisini yonetebilirsiniz.
            </p>
            <button
              type="button"
              onClick={openCreateModal}
              className="mt-5 rounded-2xl bg-primary-600 px-5 py-3 text-sm font-semibold text-white"
            >
              Ilk urunu ekle
            </button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-slate-50 text-left text-xs uppercase tracking-[0.18em] text-slate-500">
                <tr>
                  <th className="px-5 py-4 font-semibold">Urun</th>
                  <th className="px-5 py-4 font-semibold">Kategori</th>
                  <th className="px-5 py-4 font-semibold">Fiyat</th>
                  <th className="px-5 py-4 font-semibold">Stok</th>
                  <th className="px-5 py-4 font-semibold">Durum</th>
                  <th className="px-5 py-4 font-semibold text-right">Islemler</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {products.map((product) => (
                  <tr key={product._id} className="hover:bg-slate-50/80">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-4">
                        <div className="flex h-14 w-14 items-center justify-center overflow-hidden rounded-2xl bg-slate-100">
                          {resolveMediaUrl(product.images?.[0] || product.photos?.[0]) ? (
                            <img
                              src={resolveMediaUrl(product.images?.[0] || product.photos?.[0])}
                              alt={product.name || product.title}
                              className="h-full w-full object-cover"
                            />
                          ) : (
                            <PhotoIcon className="h-6 w-6 text-slate-300" />
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="truncate font-semibold text-slate-900">
                            {product.name || product.title}
                          </p>
                          <p className="mt-1 truncate text-xs text-slate-500">
                            {product.description || 'Aciklama girilmemis'}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-slate-600">
                      {product.category?.name || 'Kategori yok'}
                    </td>
                    <td className="px-5 py-4 font-semibold text-primary-700">
                      ₺{Number(product.price || 0).toLocaleString('tr-TR')}
                    </td>
                    <td className="px-5 py-4">
                      <span className={`font-semibold ${product.stock <= 5 ? 'text-orange-600' : 'text-slate-700'}`}>
                        {product.stock ?? 0}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${
                        product.isActive ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-600'
                      }`}>
                        {product.isActive ? 'Aktif' : 'Pasif'}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex justify-end gap-2">
                        <ActionButton onClick={() => openEditModal(product)} title="Duzenle">
                          <PencilSquareIcon className="h-4 w-4" />
                        </ActionButton>
                        <ActionButton onClick={() => toggleActive(product)} title="Durum">
                          {product.isActive ? <EyeSlashIcon className="h-4 w-4" /> : <EyeIcon className="h-4 w-4" />}
                        </ActionButton>
                        <ActionButton onClick={() => setDeleteTarget(product)} title="Sil" danger>
                          <TrashIcon className="h-4 w-4" />
                        </ActionButton>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showForm && (
        <Modal title={editingProduct ? 'Urunu duzenle' : 'Yeni urun olustur'} onClose={closeForm}>
          <form onSubmit={handleSubmit} className="space-y-4">
            <Field label="Urun adi" value={form.name} onChange={(value) => setForm((current) => ({ ...current, name: value }))} required />

            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Fiyat" type="number" value={form.price} onChange={(value) => setForm((current) => ({ ...current, price: value }))} required />
              <Field label="Stok" type="number" value={form.stock} onChange={(value) => setForm((current) => ({ ...current, stock: value }))} />
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700">Kategori</label>
              <select
                value={form.category}
                onChange={(event) => setForm((current) => ({ ...current, category: event.target.value }))}
                className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
              >
                <option value="">Kategori secilmedi</option>
                {categories.map((category) => (
                  <option key={category._id} value={category._id}>
                    {category.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700">Aciklama</label>
              <textarea
                rows={4}
                value={form.description}
                onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))}
                className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
              />
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700">Fotograflar</label>
              <button
                type="button"
                onClick={() => imageInputRef.current?.click()}
                className="flex w-full items-center justify-center gap-2 rounded-2xl border border-dashed border-primary-200 bg-primary-50 px-4 py-4 text-sm font-semibold text-primary-700 transition hover:border-primary-300 hover:bg-primary-100"
              >
                <PhotoIcon className="h-5 w-5" />
                En fazla 5 gorsel sec
              </button>
              <input ref={imageInputRef} type="file" multiple accept="image/*" className="hidden" onChange={handleImageSelection} />

              {(images.length > 0 || editingProduct?.images?.length > 0 || editingProduct?.photos?.length > 0) && (
                <div className="mt-3 flex flex-wrap gap-3">
                  {images.length > 0
                    ? images.map((file) => (
                        <img key={`${file.name}-${file.size}`} src={URL.createObjectURL(file)} alt={file.name} className="h-16 w-16 rounded-2xl object-cover" />
                      ))
                    : (editingProduct?.images || editingProduct?.photos || []).slice(0, 5).map((image, index) => (
                        <img key={`${image}-${index}`} src={resolveMediaUrl(image)} alt="urun" className="h-16 w-16 rounded-2xl object-cover" />
                      ))}
                </div>
              )}
            </div>

            <div className="flex gap-3 pt-2">
              <button type="button" onClick={closeForm} className="flex-1 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50">
                Iptal
              </button>
              <button type="submit" disabled={saving} className="flex-1 rounded-2xl bg-primary-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-primary-700 disabled:cursor-not-allowed disabled:opacity-60">
                {saving ? 'Kaydediliyor...' : editingProduct ? 'Degisiklikleri kaydet' : 'Urunu kaydet'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {deleteTarget && (
        <Modal title="Urunu sil" onClose={() => setDeleteTarget(null)} size="sm">
          <p className="text-sm leading-6 text-slate-500">
            <span className="font-semibold text-slate-900">{deleteTarget.name || deleteTarget.title}</span> urununu silmek istediginizden emin misiniz?
          </p>
          <div className="mt-5 flex gap-3">
            <button type="button" onClick={() => setDeleteTarget(null)} className="flex-1 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-600">
              Vazgec
            </button>
            <button type="button" onClick={deleteProduct} className="flex-1 rounded-2xl bg-rose-600 px-4 py-3 text-sm font-semibold text-white">
              Evet, sil
            </button>
          </div>
        </Modal>
      )}
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

function Field({ label, type = 'text', value, onChange, required = false }) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-semibold text-slate-700">{label}</label>
      <input
        type={type}
        required={required}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-primary-400 focus:ring-4 focus:ring-primary-100"
      />
    </div>
  )
}

function Modal({ children, title, onClose, size = 'lg' }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-slate-950/50 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative max-h-[90vh] w-full overflow-y-auto rounded-[32px] bg-white shadow-2xl ${size === 'sm' ? 'max-w-md' : 'max-w-2xl'}`}>
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
