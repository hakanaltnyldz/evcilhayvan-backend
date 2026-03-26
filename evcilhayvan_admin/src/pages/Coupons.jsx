import { useEffect, useState } from 'react'
import api from '../api.js'
import toast from 'react-hot-toast'

const emptyForm = {
  code: '',
  description: '',
  discountType: 'percentage',
  discountValue: '',
  minPurchaseAmount: '',
  maxDiscountAmount: '',
  validFrom: '',
  validUntil: '',
  usageLimit: '',
  perUserLimit: '1',
  firstOrderOnly: false,
}

// İstemci tarafında rastgele kupon kodu üret — sıfır sunucu yükü
function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  const prefix = ['YAZ', 'KIS', 'HOŞGELDİN', 'FIRSATI', 'KAMPANYA'][Math.floor(Math.random() * 5)]
  const suffix = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('')
  return `${prefix}${suffix}`
}

export default function Coupons() {
  const [coupons, setCoupons] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState('all')
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [toggling, setToggling] = useState(null)
  const [deleting, setDeleting] = useState(null)
  const [usageModal, setUsageModal] = useState(null) // { coupon, usages, total, totalDiscountGiven }
  const [usageLoading, setUsageLoading] = useState(false)

  useEffect(() => {
    setLoading(true)
    const params = { page }
    if (statusFilter !== 'all') params.status = statusFilter
    api.get('/admin/coupons', { params })
      .then((res) => {
        setCoupons(res.data?.coupons || [])
        setTotal(res.data?.total || 0)
      })
      .finally(() => setLoading(false))
  }, [page, statusFilter])

  async function toggleCoupon(coupon) {
    setToggling(coupon._id)
    try {
      const res = await api.patch(`/admin/coupons/${coupon._id}/toggle`)
      setCoupons((prev) => prev.map((c) => c._id === coupon._id ? res.data.coupon : c))
    } catch (err) {
      toast.error(err.response?.data?.message || 'İşlem başarısız')
    } finally {
      setToggling(null)
    }
  }

  async function deleteCoupon(coupon) {
    if (!window.confirm(`"${coupon.code}" kuponu silinecek. Emin misiniz?`)) return
    setDeleting(coupon._id)
    try {
      await api.delete(`/admin/coupons/${coupon._id}`)
      setCoupons((prev) => prev.filter((c) => c._id !== coupon._id))
      setTotal((t) => t - 1)
    } catch (err) {
      toast.error(err.response?.data?.message || 'Silinemedi')
    } finally {
      setDeleting(null)
    }
  }

  const [editCoupon, setEditCoupon] = useState(null) // düzenleme modali için

  function openCreate() {
    setForm(emptyForm)
    setEditCoupon(null)
    setShowModal(true)
  }

  function openEdit(coupon) {
    setForm({
      code: coupon.code || '',
      description: coupon.description || '',
      discountType: coupon.discountType || 'percentage',
      discountValue: String(coupon.discountValue ?? ''),
      minPurchaseAmount: String(coupon.minPurchaseAmount ?? ''),
      maxDiscountAmount: String(coupon.maxDiscountAmount ?? ''),
      validFrom: coupon.validFrom ? coupon.validFrom.substring(0, 10) : '',
      validUntil: coupon.validUntil ? coupon.validUntil.substring(0, 10) : '',
      usageLimit: String(coupon.usageLimit ?? ''),
      perUserLimit: String(coupon.perUserLimit ?? '1'),
      firstOrderOnly: coupon.firstOrderOnly || false,
    })
    setEditCoupon(coupon)
    setShowModal(true)
  }

  async function openUsageModal(coupon) {
    setUsageLoading(true)
    setUsageModal({ coupon, usages: [], total: 0, totalDiscountGiven: 0 })
    try {
      const res = await api.get(`/admin/coupons/${coupon._id}/usage`)
      setUsageModal({
        coupon: res.data.coupon || coupon,
        usages: res.data.usages || [],
        total: res.data.total || 0,
        totalDiscountGiven: res.data.totalDiscountGiven || 0,
      })
    } catch {
      setUsageModal(null)
    } finally {
      setUsageLoading(false)
    }
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setSaving(true)
    const payload = {
      ...form,
      discountValue: Number(form.discountValue),
      minPurchaseAmount: form.minPurchaseAmount ? Number(form.minPurchaseAmount) : 0,
      maxDiscountAmount: form.maxDiscountAmount ? Number(form.maxDiscountAmount) : undefined,
      usageLimit: form.usageLimit ? Number(form.usageLimit) : undefined,
      perUserLimit: Number(form.perUserLimit) || 1,
      firstOrderOnly: form.firstOrderOnly,
    }
    try {
      if (editCoupon) {
        // Güncelleme
        const res = await api.patch(`/admin/coupons/${editCoupon._id}`, payload)
        setCoupons((prev) => prev.map((c) => c._id === editCoupon._id ? res.data.coupon : c))
        toast.success('Kupon güncellendi')
      } else {
        // Yeni oluşturma
        const res = await api.post('/admin/coupons', payload)
        setCoupons((prev) => [res.data.coupon, ...prev])
        setTotal((t) => t + 1)
        toast.success('Kupon oluşturuldu')
      }
      setShowModal(false)
    } catch (err) {
      toast.error(err.response?.data?.message || (editCoupon ? 'Kupon güncellenemedi' : 'Kupon oluşturulamadı'))
    } finally {
      setSaving(false)
    }
  }

  function couponStatus(c) {
    const now = new Date()
    if (!c.isActive) return { label: 'Pasif', cls: 'bg-gray-100 text-gray-600' }
    if (new Date(c.validUntil) < now) return { label: 'Süresi Dolmuş', cls: 'bg-red-100 text-red-700' }
    return { label: 'Aktif', cls: 'bg-green-100 text-green-700' }
  }

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Kuponlar</h1>
          <p className="text-sm text-gray-500 mt-0.5">{total} kupon</p>
        </div>
        <button
          onClick={openCreate}
          className="bg-indigo-600 text-white px-5 py-2 rounded-xl text-sm font-semibold hover:bg-indigo-700 transition-colors"
        >
          + Yeni Kupon
        </button>
      </div>

      {/* Status filter tabs */}
      <div className="flex gap-2 mb-6">
        {[['all', 'Tümü'], ['active', 'Aktif'], ['expired', 'Süresi Dolmuş']].map(([val, label]) => (
          <button
            key={val}
            onClick={() => { setStatusFilter(val); setPage(1) }}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-colors ${
              statusFilter === val
                ? 'bg-indigo-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="flex justify-center items-center h-40 text-gray-400">Yükleniyor...</div>
        ) : coupons.length === 0 ? (
          <div className="flex justify-center items-center h-40 text-gray-400 text-sm">Kupon bulunamadı</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 text-left">
                <th className="px-4 py-3 font-semibold text-gray-600">Kod</th>
                <th className="px-4 py-3 font-semibold text-gray-600">İndirim</th>
                <th className="px-4 py-3 font-semibold text-gray-600">Min. Tutar</th>
                <th className="px-4 py-3 font-semibold text-gray-600">Geçerlilik</th>
                <th className="px-4 py-3 font-semibold text-gray-600">Kullanım</th>
                <th className="px-4 py-3 font-semibold text-gray-600">Durum</th>
                <th className="px-4 py-3 font-semibold text-gray-600">Satıcı</th>
                <th className="px-4 py-3 font-semibold text-gray-600"></th>
              </tr>
            </thead>
            <tbody>
              {coupons.map((c) => {
                const st = couponStatus(c)
                return (
                  <tr key={c._id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div>
                        <span className="font-mono font-bold text-indigo-700 text-sm">{c.code}</span>
                        {c.description && (
                          <div className="text-xs text-gray-400 mt-0.5 max-w-[140px] truncate">{c.description}</div>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                        c.discountType === 'percentage' ? 'bg-purple-100 text-purple-700' : 'bg-orange-100 text-orange-700'
                      }`}>
                        {c.discountType === 'percentage'
                          ? `%${c.discountValue}`
                          : `₺${c.discountValue}`}
                      </span>
                      {c.maxDiscountAmount && c.discountType === 'percentage' && (
                        <div className="text-xs text-gray-400 mt-0.5">Maks. ₺{c.maxDiscountAmount}</div>
                      )}
                    </td>
                    <td className="px-4 py-3 text-gray-600">
                      {c.minPurchaseAmount > 0 ? `₺${c.minPurchaseAmount}` : '—'}
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-500">
                      <div>{new Date(c.validFrom).toLocaleDateString('tr-TR')}</div>
                      <div>— {new Date(c.validUntil).toLocaleDateString('tr-TR')}</div>
                    </td>
                    <td className="px-4 py-3 text-gray-600 text-xs">
                      {c.usageCount}/{c.usageLimit ?? '∞'}
                      <div className="text-gray-400">Kişi başı: {c.perUserLimit}</div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${st.cls}`}>
                        {st.label}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-500">
                      {c.seller ? (
                        <div>
                          <div className="font-medium">{c.seller.name}</div>
                          <div className="text-gray-400">{c.seller.email}</div>
                        </div>
                      ) : (
                        <span className="text-indigo-500 font-medium">Platform</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => toggleCoupon(c)}
                          disabled={toggling === c._id}
                          className={`px-2 py-1 rounded-lg text-xs font-semibold transition-colors ${
                            c.isActive
                              ? 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                              : 'bg-green-100 text-green-700 hover:bg-green-200'
                          }`}
                        >
                          {toggling === c._id ? '...' : c.isActive ? 'Pasif Yap' : 'Aktif Et'}
                        </button>
                        <button
                          onClick={() => openEdit(c)}
                          className="px-2 py-1 rounded-lg text-xs font-semibold bg-yellow-50 text-yellow-700 hover:bg-yellow-100 transition-colors"
                        >
                          Düzenle
                        </button>
                        <button
                          onClick={() => openUsageModal(c)}
                          className="px-2 py-1 rounded-lg text-xs font-semibold bg-indigo-50 text-indigo-700 hover:bg-indigo-100 transition-colors"
                        >
                          Kullanım
                        </button>
                        <button
                          onClick={() => deleteCoupon(c)}
                          disabled={deleting === c._id}
                          className="px-2 py-1 rounded-lg text-xs font-semibold bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
                        >
                          {deleting === c._id ? '...' : 'Sil'}
                        </button>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-6">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-4 py-2 rounded-xl border text-sm disabled:opacity-40 hover:bg-gray-50"
          >
            ← Önceki
          </button>
          <span className="px-4 py-2 text-sm text-gray-500">{page} / {totalPages}</span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page === totalPages}
            className="px-4 py-2 rounded-xl border text-sm disabled:opacity-40 hover:bg-gray-50"
          >
            Sonraki →
          </button>
        </div>
      )}

      {/* Usage History Modal */}
      {usageModal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 w-full max-w-2xl shadow-xl max-h-[85vh] flex flex-col">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="font-bold text-lg">Kupon Kullanım Geçmişi</h2>
                <div className="flex items-center gap-3 mt-1">
                  <span className="font-mono font-bold text-indigo-700">{usageModal.coupon?.code}</span>
                  <span className="text-sm text-gray-500">{usageModal.total} kullanım</span>
                  <span className="text-sm font-semibold text-green-700">
                    Toplam ₺{Number(usageModal.totalDiscountGiven).toLocaleString('tr-TR', { minimumFractionDigits: 2 })} indirim
                  </span>
                </div>
              </div>
              <button onClick={() => setUsageModal(null)} className="text-gray-400 hover:text-gray-600 text-xl leading-none">✕</button>
            </div>
            <div className="overflow-y-auto flex-1">
              {usageLoading ? (
                <div className="flex justify-center items-center h-32 text-gray-400">Yükleniyor...</div>
              ) : usageModal.usages.length === 0 ? (
                <div className="flex justify-center items-center h-32 text-gray-400 text-sm">Henüz kullanılmamış</div>
              ) : (
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-100 text-left">
                      <th className="pb-2 font-semibold text-gray-600">Kullanıcı</th>
                      <th className="pb-2 font-semibold text-gray-600">İndirim</th>
                      <th className="pb-2 font-semibold text-gray-600">Sipariş Tutarı</th>
                      <th className="pb-2 font-semibold text-gray-600">Sipariş Durumu</th>
                      <th className="pb-2 font-semibold text-gray-600">Tarih</th>
                    </tr>
                  </thead>
                  <tbody>
                    {usageModal.usages.map((u) => (
                      <tr key={u._id} className="border-b border-gray-50">
                        <td className="py-2.5">
                          <div className="font-medium text-gray-800">{u.userId?.name || '—'}</div>
                          <div className="text-xs text-gray-400">{u.userId?.email}</div>
                        </td>
                        <td className="py-2.5 text-green-700 font-semibold">
                          -₺{Number(u.discountAmount).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                        </td>
                        <td className="py-2.5 text-gray-600">
                          <span className="line-through text-gray-400 text-xs mr-1">
                            ₺{Number(u.originalAmount).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                          </span>
                          ₺{Number(u.finalAmount).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                        </td>
                        <td className="py-2.5">
                          <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-gray-100 text-gray-600">
                            {u.orderId?.status || '—'}
                          </span>
                        </td>
                        <td className="py-2.5 text-xs text-gray-400">
                          {u.createdAt ? new Date(u.createdAt).toLocaleDateString('tr-TR') : '—'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Create Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto">
            <h2 className="font-bold text-lg mb-5">{editCoupon ? 'Kuponu Düzenle' : 'Yeni Kupon Oluştur'}</h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div className="col-span-2">
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Kupon Kodu *</label>
                  <div className="flex gap-2">
                    <input
                      required
                      value={form.code}
                      onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })}
                      placeholder="Örn: YAZA25"
                      className="flex-1 border border-gray-200 rounded-xl px-3 py-2 text-sm font-mono uppercase focus:outline-none focus:ring-2 focus:ring-indigo-300"
                    />
                    <button
                      type="button"
                      onClick={() => setForm({ ...form, code: generateCode() })}
                      className="px-3 py-2 rounded-xl border border-indigo-200 bg-indigo-50 text-indigo-700 text-xs font-semibold hover:bg-indigo-100 transition-colors whitespace-nowrap"
                    >
                      Rastgele
                    </button>
                  </div>
                </div>
                <div className="col-span-2">
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Açıklama</label>
                  <input
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                    placeholder="Yaz indirimi kuponu"
                    className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">İndirim Tipi *</label>
                  <select
                    value={form.discountType}
                    onChange={(e) => setForm({ ...form, discountType: e.target.value })}
                    className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  >
                    <option value="percentage">Yüzde (%)</option>
                    <option value="fixed">Sabit (TL)</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">
                    {form.discountType === 'percentage' ? 'İndirim Oranı (%) *' : 'İndirim Tutarı (TL) *'}
                  </label>
                  <input
                    required
                    type="number"
                    min="1"
                    max={form.discountType === 'percentage' ? '100' : undefined}
                    value={form.discountValue}
                    onChange={(e) => setForm({ ...form, discountValue: e.target.value })}
                    placeholder={form.discountType === 'percentage' ? '25' : '50'}
                    className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Min. Alışveriş (TL)</label>
                  <input
                    type="number"
                    min="0"
                    value={form.minPurchaseAmount}
                    onChange={(e) => setForm({ ...form, minPurchaseAmount: e.target.value })}
                    placeholder="100"
                    className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
                {form.discountType === 'percentage' && (
                  <div>
                    <label className="text-xs font-medium text-gray-600 mb-1 block">Maks. İndirim (TL)</label>
                    <input
                      type="number"
                      min="0"
                      value={form.maxDiscountAmount}
                      onChange={(e) => setForm({ ...form, maxDiscountAmount: e.target.value })}
                      placeholder="200"
                      className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                    />
                  </div>
                )}
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Başlangıç Tarihi *</label>
                  <input
                    required
                    type="date"
                    value={form.validFrom}
                    onChange={(e) => setForm({ ...form, validFrom: e.target.value })}
                    className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Bitiş Tarihi *</label>
                  <input
                    required
                    type="date"
                    value={form.validUntil}
                    onChange={(e) => setForm({ ...form, validUntil: e.target.value })}
                    className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Toplam Kullanım Limiti</label>
                  <input
                    type="number"
                    min="1"
                    value={form.usageLimit}
                    onChange={(e) => setForm({ ...form, usageLimit: e.target.value })}
                    placeholder="Boş = sınırsız"
                    className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-600 mb-1 block">Kişi Başı Limit</label>
                  <input
                    type="number"
                    min="1"
                    value={form.perUserLimit}
                    onChange={(e) => setForm({ ...form, perUserLimit: e.target.value })}
                    className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  />
                </div>
                <div className="col-span-2">
                  <label className="flex items-center gap-3 cursor-pointer p-3 rounded-xl border border-gray-200 hover:bg-gray-50 transition-colors">
                    <input
                      type="checkbox"
                      checked={form.firstOrderOnly}
                      onChange={(e) => setForm({ ...form, firstOrderOnly: e.target.checked })}
                      className="w-4 h-4 rounded accent-indigo-600"
                    />
                    <div>
                      <div className="text-sm font-medium text-gray-700">Sadece İlk Sipariş</div>
                      <div className="text-xs text-gray-400">Bu kuponu daha önce hiç satın alma yapmamış kullanıcılar kullanabilir</div>
                    </div>
                  </label>
                </div>
              </div>
              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm text-gray-600 hover:bg-gray-50"
                >
                  İptal
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="flex-1 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 disabled:opacity-50"
                >
                  {saving ? 'Oluşturuluyor...' : 'Kupon Oluştur'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
