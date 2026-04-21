import { NavLink } from 'react-router-dom'
import { useEffect, useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import api from '../api.js'

const RETURN_STATUS_META = {
  pending: { label: 'Incelemede', cls: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandi', cls: 'bg-emerald-50 text-emerald-700' },
  rejected: { label: 'Reddedildi', cls: 'bg-rose-50 text-rose-700' },
}

const ORDER_STATUS_META = {
  pending: 'Bekliyor',
  processing: 'Hazirlaniyor',
  shipped: 'Kargoda',
  delivered: 'Teslim edildi',
  cancelled: 'Iptal edildi',
}

export default function Returns() {
  const [returns, setReturns] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState('all')
  const [loading, setLoading] = useState(true)
  const [selectedReturn, setSelectedReturn] = useState(null)
  const [resolutionNote, setResolutionNote] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    loadReturns(1, statusFilter)
  }, [statusFilter])

  async function loadReturns(nextPage = page, nextStatus = statusFilter) {
    setLoading(true)
    try {
      const params = { page: nextPage, limit: 20 }
      if (nextStatus !== 'all') params.status = nextStatus
      const response = await api.get('/admin/orders/returns', { params })
      setReturns(response.data?.returns || [])
      setTotal(response.data?.total || 0)
      setPage(nextPage)
    } catch (error) {
      toast.error(error.response?.data?.message || 'Iade talepleri yuklenemedi')
    } finally {
      setLoading(false)
    }
  }

  function openDetail(item) {
    setSelectedReturn(item)
    setResolutionNote(item.returnRequest?.resolvedNote || '')
  }

  function closeDetail() {
    setSelectedReturn(null)
    setResolutionNote('')
  }

  async function resolveReturn(nextStatus) {
    if (!selectedReturn) return

    setSaving(true)
    try {
      await api.patch(`/admin/orders/${selectedReturn._id}/return-status`, {
        status: nextStatus,
        note: resolutionNote.trim(),
      })
      toast.success(nextStatus === 'approved' ? 'Iade talebi onaylandi' : 'Iade talebi reddedildi')
      closeDetail()
      await loadReturns(page, statusFilter)
    } catch (error) {
      toast.error(error.response?.data?.message || 'Iade talebi guncellenemedi')
    } finally {
      setSaving(false)
    }
  }

  const totalPages = Math.ceil(total / 20)
  const pageStats = useMemo(() => {
    return returns.reduce(
      (summary, item) => {
        const status = item.returnRequest?.status
        if (status === 'pending') summary.pending += 1
        if (status === 'approved') summary.approved += 1
        if (status === 'rejected') summary.rejected += 1
        return summary
      },
      { pending: 0, approved: 0, rejected: 0 }
    )
  }, [returns])

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap gap-2">
        <NavLink
          to="/orders"
          className={({ isActive }) =>
            `rounded-2xl px-4 py-2 text-sm font-semibold transition ${
              isActive
                ? 'bg-indigo-600 text-white'
                : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
            }`
          }
        >
          Siparisler
        </NavLink>
        <NavLink
          to="/returns"
          end
          className={({ isActive }) =>
            `rounded-2xl px-4 py-2 text-sm font-semibold transition ${
              isActive
                ? 'bg-indigo-600 text-white'
                : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
            }`
          }
        >
          Iade Talepleri
        </NavLink>
      </div>

      <div className="rounded-[32px] bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 p-6 text-white shadow-panel">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-slate-300">Commerce Ops</p>
        <h2 className="mt-2 text-3xl font-black">Iade Yonetimi</h2>
        <p className="mt-2 max-w-3xl text-sm leading-7 text-slate-300">
          Musteri iade taleplerini tek ekranda inceleyin, gerekceyi okuyun ve onay ya da red karari verin.
        </p>
      </div>

      <section className="grid gap-4 md:grid-cols-4">
        <MetricCard label="Toplam Talep" value={total} tone="slate" />
        <MetricCard label="Bu Sayfada Bekleyen" value={pageStats.pending} tone="amber" />
        <MetricCard label="Bu Sayfada Onaylanan" value={pageStats.approved} tone="emerald" />
        <MetricCard label="Bu Sayfada Reddedilen" value={pageStats.rejected} tone="rose" />
      </section>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap gap-2">
          {[
            ['all', 'Tumu'],
            ['pending', 'Incelemede'],
            ['approved', 'Onaylanan'],
            ['rejected', 'Reddedilen'],
          ].map(([value, label]) => (
            <button
              key={value}
              type="button"
              onClick={() => setStatusFilter(value)}
              className={`rounded-2xl px-4 py-2 text-sm font-semibold transition ${
                statusFilter === value
                  ? 'bg-indigo-600 text-white'
                  : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        <p className="text-sm text-slate-500">{total} iade talebi</p>
      </div>

      <div className="overflow-hidden rounded-[32px] border border-white bg-white shadow-panel">
        {loading ? (
          <div className="space-y-3 p-6">
            {Array.from({ length: 5 }).map((_, index) => (
              <div key={index} className="h-20 animate-pulse rounded-3xl bg-slate-100" />
            ))}
          </div>
        ) : returns.length === 0 ? (
          <div className="px-6 py-20 text-center">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-3xl bg-indigo-50 text-3xl text-indigo-600">
              ↩
            </div>
            <h3 className="mt-5 text-xl font-bold text-slate-900">Iade talebi bulunamadi</h3>
            <p className="mt-2 text-sm leading-6 text-slate-500">
              Secili filtreye uyan yeni bir talep geldiginde bu liste otomatik dolar.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-slate-50 text-left text-xs uppercase tracking-[0.18em] text-slate-500">
                <tr>
                  <th className="px-5 py-4 font-semibold">Musteri</th>
                  <th className="px-5 py-4 font-semibold">Siparis</th>
                  <th className="px-5 py-4 font-semibold">Iade Nedeni</th>
                  <th className="px-5 py-4 font-semibold">Talep Tarihi</th>
                  <th className="px-5 py-4 font-semibold">Durum</th>
                  <th className="px-5 py-4 font-semibold text-right">Islem</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {returns.map((item) => {
                  const customerName = item.user?.name || item.user?.email || 'Misafir Musteri'
                  const customerEmail = item.user?.email || item.guestInfo?.email || '—'
                  const returnStatus = RETURN_STATUS_META[item.returnRequest?.status] || RETURN_STATUS_META.pending
                  return (
                    <tr key={item._id} className="hover:bg-slate-50/80">
                      <td className="px-5 py-4">
                        <p className="font-semibold text-slate-900">{customerName}</p>
                        <p className="mt-1 text-xs text-slate-400">{customerEmail}</p>
                      </td>
                      <td className="px-5 py-4">
                        <p className="font-mono text-xs font-semibold text-slate-500">#{item._id?.slice(-8).toUpperCase()}</p>
                        <p className="mt-1 text-xs text-slate-400">
                          {item.items?.length || 0} urun · {formatCurrency(item.totalAmount)}
                        </p>
                      </td>
                      <td className="px-5 py-4">
                        <p className="font-semibold text-slate-900">{item.returnRequest?.reason || 'Belirtilmedi'}</p>
                        <p className="mt-1 max-w-xs text-xs text-slate-500">
                          {item.returnRequest?.description || 'Aciklama girilmemis'}
                        </p>
                      </td>
                      <td className="px-5 py-4 text-slate-500">
                        {formatDate(item.returnRequest?.requestedAt || item.createdAt)}
                      </td>
                      <td className="px-5 py-4">
                        <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${returnStatus.cls}`}>
                          {returnStatus.label}
                        </span>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex justify-end">
                          <button
                            type="button"
                            onClick={() => openDetail(item)}
                            className="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-50"
                          >
                            Incele
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {totalPages > 1 ? (
        <div className="flex justify-center gap-2">
          <button
            type="button"
            onClick={() => loadReturns(page - 1, statusFilter)}
            disabled={page === 1}
            className="rounded-2xl border border-slate-200 px-4 py-2 text-sm text-slate-600 disabled:cursor-not-allowed disabled:opacity-40"
          >
            ← Onceki
          </button>
          <span className="px-4 py-2 text-sm text-slate-500">{page} / {totalPages}</span>
          <button
            type="button"
            onClick={() => loadReturns(page + 1, statusFilter)}
            disabled={page === totalPages}
            className="rounded-2xl border border-slate-200 px-4 py-2 text-sm text-slate-600 disabled:cursor-not-allowed disabled:opacity-40"
          >
            Sonraki →
          </button>
        </div>
      ) : null}

      {selectedReturn ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-950/55 backdrop-blur-sm" onClick={closeDetail} />
          <div className="relative max-h-[90vh] w-full max-w-4xl overflow-y-auto rounded-[32px] bg-white shadow-2xl">
            <div className="sticky top-0 flex items-center justify-between border-b border-slate-100 bg-white px-6 py-5">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Iade Talebi</p>
                <h3 className="mt-1 text-lg font-bold text-slate-900">
                  Siparis #{selectedReturn._id?.slice(-8).toUpperCase()}
                </h3>
              </div>
              <button
                type="button"
                onClick={closeDetail}
                className="rounded-xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600"
              >
                ×
              </button>
            </div>

            <div className="space-y-6 p-6">
              <section className="grid gap-4 md:grid-cols-3">
                <InfoCard
                  label="Musteri"
                  value={selectedReturn.user?.name || selectedReturn.user?.email || 'Misafir Musteri'}
                  secondary={selectedReturn.user?.email || selectedReturn.guestInfo?.email || '—'}
                />
                <InfoCard
                  label="Siparis Durumu"
                  value={ORDER_STATUS_META[selectedReturn.status] || selectedReturn.status || '—'}
                  secondary={formatDate(selectedReturn.createdAt)}
                />
                <InfoCard
                  label="Iade Durumu"
                  value={RETURN_STATUS_META[selectedReturn.returnRequest?.status]?.label || 'Incelemede'}
                  secondary={selectedReturn.returnRequest?.resolvedAt ? formatDate(selectedReturn.returnRequest.resolvedAt) : 'Henuz sonuclanmadi'}
                />
              </section>

              <section className="grid gap-4 lg:grid-cols-[1.4fr_1fr]">
                <div className="rounded-[28px] border border-slate-100 bg-slate-50 p-5">
                  <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Talep Detayi</p>
                  <div className="mt-4 space-y-4">
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Neden</p>
                      <p className="mt-2 font-semibold text-slate-900">{selectedReturn.returnRequest?.reason || 'Belirtilmedi'}</p>
                    </div>
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Aciklama</p>
                      <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-slate-600">
                        {selectedReturn.returnRequest?.description || 'Musteri ek bir aciklama birakmamis.'}
                      </p>
                    </div>
                    {selectedReturn.returnRequest?.photos?.length ? (
                      <div>
                        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Kanit Gorselleri</p>
                        <div className="mt-3 grid gap-3 sm:grid-cols-3">
                          {selectedReturn.returnRequest.photos.map((photo, index) => (
                            <a
                              key={`${selectedReturn._id}-photo-${index}`}
                              href={photo}
                              target="_blank"
                              rel="noreferrer"
                              className="overflow-hidden rounded-2xl border border-slate-200 bg-white"
                            >
                              <img src={photo} alt={`Iade gorseli ${index + 1}`} className="h-32 w-full object-cover" />
                            </a>
                          ))}
                        </div>
                      </div>
                    ) : null}
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="rounded-[28px] border border-slate-100 bg-slate-50 p-5">
                    <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Siparis Ozet</p>
                    <div className="mt-4 space-y-3">
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-slate-500">Toplam tutar</span>
                        <span className="font-semibold text-slate-900">{formatCurrency(selectedReturn.totalAmount)}</span>
                      </div>
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-slate-500">Urun adedi</span>
                        <span className="font-semibold text-slate-900">{selectedReturn.items?.length || 0}</span>
                      </div>
                    </div>
                    <div className="mt-4 space-y-3">
                      {(selectedReturn.items || []).map((item, index) => (
                        <div key={`${selectedReturn._id}-item-${index}`} className="rounded-2xl border border-slate-200 bg-white px-4 py-3">
                          <p className="font-semibold text-slate-900">{item.name || 'Urun'}</p>
                          <p className="mt-1 text-xs text-slate-500">
                            Adet: {item.quantity || 0} · {formatCurrency((item.price || 0) * (item.quantity || 0))}
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="rounded-[28px] border border-slate-100 bg-slate-50 p-5">
                    <label className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Admin Notu</label>
                    <textarea
                      rows={4}
                      value={resolutionNote}
                      onChange={(event) => setResolutionNote(event.target.value)}
                      disabled={selectedReturn.returnRequest?.status !== 'pending'}
                      placeholder="Karar notu ekleyin"
                      className="mt-3 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400 focus:ring-4 focus:ring-indigo-100 disabled:bg-slate-100 disabled:text-slate-500"
                    />
                    {selectedReturn.returnRequest?.status === 'pending' ? (
                      <div className="mt-4 flex gap-3">
                        <button
                          type="button"
                          onClick={() => resolveReturn('rejected')}
                          disabled={saving}
                          className="flex-1 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-semibold text-rose-700 transition hover:bg-rose-100 disabled:cursor-not-allowed disabled:opacity-60"
                        >
                          {saving ? 'Kaydediliyor...' : 'Reddet'}
                        </button>
                        <button
                          type="button"
                          onClick={() => resolveReturn('approved')}
                          disabled={saving}
                          className="flex-1 rounded-2xl bg-emerald-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
                        >
                          {saving ? 'Kaydediliyor...' : 'Onayla'}
                        </button>
                      </div>
                    ) : (
                      <p className="mt-3 text-sm text-slate-500">Bu talep sonuclanmis. Notu sadece goruntuleyebilirsiniz.</p>
                    )}
                  </div>
                </div>
              </section>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}

function MetricCard({ label, value, tone = 'slate' }) {
  const toneMap = {
    slate: 'bg-slate-950 text-white',
    amber: 'bg-amber-50 text-amber-700 border border-amber-100',
    emerald: 'bg-emerald-50 text-emerald-700 border border-emerald-100',
    rose: 'bg-rose-50 text-rose-700 border border-rose-100',
  }

  return (
    <div className={`rounded-[28px] px-5 py-5 shadow-sm ${toneMap[tone] || toneMap.slate}`}>
      <p className="text-xs font-semibold uppercase tracking-[0.18em] opacity-70">{label}</p>
      <p className="mt-3 text-3xl font-black">{Number(value || 0).toLocaleString('tr-TR')}</p>
    </div>
  )
}

function InfoCard({ label, value, secondary }) {
  return (
    <div className="rounded-[28px] border border-slate-100 bg-slate-50 px-5 py-5">
      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{label}</p>
      <p className="mt-3 font-semibold text-slate-900">{value}</p>
      {secondary ? <p className="mt-1 text-xs text-slate-500">{secondary}</p> : null}
    </div>
  )
}

function formatCurrency(value) {
  return `₺${Number(value || 0).toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
}

function formatDate(value) {
  if (!value) return '—'
  const date = new Date(value)
  return date.toLocaleDateString('tr-TR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}
