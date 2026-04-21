import { useCallback, useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import api from '../api.js'

const serviceLabels = {
  walking: 'Gezdirme',
  home_sitting: 'Evde bakim',
  boarding: 'Pansiyon',
  daycare: 'Gunduz bakim',
  grooming: 'Timar',
  drop_in: 'Kisa ziyaret',
  training: 'Egitim',
}

const bookingLabels = {
  pending: 'Bekleyen',
  accepted: 'Onaylanan',
  active: 'Aktif',
  completed: 'Tamamlanan',
  cancelled: 'Iptal',
  rejected: 'Reddedilen',
}

export default function Sitters() {
  const [sitters, setSitters] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [filter, setFilter] = useState('all')
  const [loading, setLoading] = useState(false)
  const [actionId, setActionId] = useState(null)
  const [selectedSitterId, setSelectedSitterId] = useState('')
  const [selectedSitter, setSelectedSitter] = useState(null)
  const [insights, setInsights] = useState(null)
  const [insightsLoading, setInsightsLoading] = useState(false)

  const fetchSitters = useCallback(async () => {
    setLoading(true)
    try {
      const response = await api.get('/admin/pet-sitters', {
        params: { page, verified: filter },
      })
      const nextSitters = response.data?.sitters || []
      setSitters(nextSitters)
      setTotal(response.data?.total || 0)
      if (selectedSitterId) {
        const refreshed = nextSitters.find(
          (item) => (item._id || item.id) === selectedSitterId
        )
        if (refreshed) {
          setSelectedSitter((current) => ({ ...current, ...refreshed }))
        }
      }
    } catch (error) {
      toast.error(error.response?.data?.message || 'Bakicilar yuklenemedi')
    } finally {
      setLoading(false)
    }
  }, [page, filter, selectedSitterId])

  useEffect(() => {
    fetchSitters()
  }, [fetchSitters])

  async function openPanel(sitter) {
    const sitterId = sitter._id || sitter.id
    setSelectedSitterId(sitterId)
    setSelectedSitter(sitter)
    setInsights(null)
    setInsightsLoading(true)
    try {
      const response = await api.get(`/admin/pet-sitters/${sitterId}/insights`)
      setSelectedSitter(response.data?.sitter || sitter)
      setInsights(response.data?.insights || null)
    } catch (error) {
      toast.error(error.response?.data?.message || 'Bakici detaylari alinamadi')
    } finally {
      setInsightsLoading(false)
    }
  }

  function patchSitter(updated) {
    if (!updated) return
    const updatedId = updated._id || updated.id
    setSitters((current) =>
      current.map((item) =>
        (item._id || item.id) === updatedId ? { ...item, ...updated } : item
      )
    )
    if (selectedSitterId === updatedId) {
      setSelectedSitter((current) => (current ? { ...current, ...updated } : current))
    }
  }

  async function toggleVerify(sitter) {
    const sitterId = sitter._id || sitter.id
    setActionId(sitterId)
    try {
      const response = await api.patch(`/admin/pet-sitters/${sitterId}/verify`, {
        isVerified: !sitter.isVerified,
      })
      patchSitter(response.data?.sitter)
      toast.success(sitter.isVerified ? 'Dogrulama kaldirildi' : 'Bakici dogrulandi')
    } catch (error) {
      toast.error(error.response?.data?.message || 'Islem basarisiz')
    } finally {
      setActionId(null)
    }
  }

  async function toggleBan(sitter) {
    const sitterId = sitter._id || sitter.id
    setActionId(sitterId)
    try {
      const response = await api.patch(`/admin/pet-sitters/${sitterId}/ban`, {
        isBanned: sitter.isActive,
        reason: sitter.isActive
          ? 'Admin panelinden devre disi birakildi'
          : 'Admin panelinden tekrar aktif edildi',
      })
      patchSitter(response.data?.sitter)
      toast.success(
        sitter.isActive ? 'Bakici devre disi birakildi' : 'Bakici tekrar aktif edildi'
      )
    } catch (error) {
      toast.error(error.response?.data?.message || 'Islem basarisiz')
    } finally {
      setActionId(null)
    }
  }

  const totalPages = Math.ceil(total / 20)
  const performance = insights?.performance || {}
  const totalBookings = Math.max(performance.totalBookings || 0, 1)
  const serviceBreakdown = insights?.serviceBreakdown || []

  return (
    <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_380px]">
      <div>
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Bakici Yonetimi</h1>
            <p className="mt-1 text-sm text-gray-500">Toplam {total} bakici</p>
          </div>
          <div className="flex gap-2">
            {[
              { key: 'all', label: 'Tumu' },
              { key: 'false', label: 'Bekleyen' },
              { key: 'true', label: 'Dogrulanmis' },
            ].map(({ key, label }) => (
              <button
                key={key}
                onClick={() => {
                  setFilter(key)
                  setPage(1)
                }}
                className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${
                  filter === key
                    ? 'bg-indigo-600 text-white'
                    : 'border bg-white text-gray-600 hover:bg-gray-50'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="rounded-2xl bg-white py-16 text-center text-gray-400 shadow-sm">
            Yukleniyor...
          </div>
        ) : sitters.length === 0 ? (
          <div className="rounded-2xl bg-white py-16 text-center text-gray-400 shadow-sm">
            Bakici bulunamadi
          </div>
        ) : (
          <div className="space-y-3">
            {sitters.map((sitter) => {
              const sitterId = sitter._id || sitter.id
              const isSelected = sitterId === selectedSitterId
              const primaryService = sitter.services?.[0]?.type
              return (
                <div
                  key={sitterId}
                  className={`flex items-center gap-4 rounded-2xl bg-white p-4 shadow-sm transition ${
                    isSelected ? 'ring-2 ring-indigo-200' : ''
                  }`}
                >
                  <button
                    type="button"
                    onClick={() => openPanel(sitter)}
                    className="h-14 w-14 flex-shrink-0 overflow-hidden rounded-2xl bg-indigo-50"
                  >
                    {sitter.avatar ? (
                      <img
                        src={sitter.avatar}
                        alt={sitter.displayName}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center text-lg font-black text-indigo-600">
                        {sitter.displayName?.[0]?.toUpperCase() || '?'}
                      </div>
                    )}
                  </button>

                  <button
                    type="button"
                    onClick={() => openPanel(sitter)}
                    className="min-w-0 flex-1 text-left"
                  >
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="truncate font-semibold text-gray-900">
                        {sitter.displayName}
                      </span>
                      {sitter.isVerified ? <StatusBadge tone="green">Dogrulanmis</StatusBadge> : null}
                      {!sitter.isActive ? <StatusBadge tone="red">Devre disi</StatusBadge> : null}
                    </div>
                    <p className="mt-1 truncate text-sm text-gray-500">
                      {sitter.userId?.email || 'E-posta yok'}
                    </p>
                    <p className="mt-1 text-xs text-gray-400">
                      {primaryService
                        ? serviceLabels[primaryService] || primaryService
                        : 'Hizmet tanimi yok'}
                      {sitter.rating ? ` | ${sitter.rating.toFixed(1)} puan` : ''}
                      {sitter.reviewCount ? ` | ${sitter.reviewCount} yorum` : ''}
                    </p>
                  </button>

                  <div className="flex flex-shrink-0 flex-wrap items-center gap-2">
                    <button
                      onClick={() => openPanel(sitter)}
                      className="rounded-lg bg-indigo-50 px-3 py-1.5 text-xs font-semibold text-indigo-700 transition-colors hover:bg-indigo-100"
                    >
                      Detay
                    </button>
                    <button
                      onClick={() => toggleVerify(sitter)}
                      disabled={actionId === sitterId}
                      className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors disabled:opacity-50 ${
                        sitter.isVerified
                          ? 'bg-red-50 text-red-600 hover:bg-red-100'
                          : 'bg-green-50 text-green-700 hover:bg-green-100'
                      }`}
                    >
                      {actionId === sitterId
                        ? '...'
                        : sitter.isVerified
                        ? 'Kaldir'
                        : 'Dogrula'}
                    </button>
                    <button
                      onClick={() => toggleBan(sitter)}
                      disabled={actionId === sitterId}
                      className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors disabled:opacity-50 ${
                        sitter.isActive
                          ? 'bg-amber-50 text-amber-700 hover:bg-amber-100'
                          : 'bg-blue-50 text-blue-700 hover:bg-blue-100'
                      }`}
                    >
                      {actionId === sitterId
                        ? '...'
                        : sitter.isActive
                        ? 'Pasif Et'
                        : 'Aktif Et'}
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {totalPages > 1 ? (
          <div className="mt-6 flex justify-center gap-2">
            <button
              onClick={() => setPage((current) => Math.max(1, current - 1))}
              disabled={page === 1}
              className="rounded-xl border px-4 py-2 text-sm hover:bg-gray-50 disabled:opacity-40"
            >
              Onceki
            </button>
            <span className="px-4 py-2 text-sm text-gray-500">
              {page} / {totalPages}
            </span>
            <button
              onClick={() =>
                setPage((current) => Math.min(totalPages, current + 1))
              }
              disabled={page === totalPages}
              className="rounded-xl border px-4 py-2 text-sm hover:bg-gray-50 disabled:opacity-40"
            >
              Sonraki
            </button>
          </div>
        ) : null}
      </div>

      <aside className="rounded-[28px] border border-slate-200 bg-white p-5 shadow-panel xl:sticky xl:top-6 xl:h-fit">
        {!selectedSitter ? (
          <EmptyPanel
            title="Performans paneli"
            text="Tamamlanan is, gelir ve yorum dagilimini gormek icin bir bakici secin."
          />
        ) : insightsLoading ? (
          <div className="space-y-4">
            <div className="h-28 animate-pulse rounded-3xl bg-slate-100" />
            <div className="h-24 animate-pulse rounded-3xl bg-slate-100" />
            <div className="h-40 animate-pulse rounded-3xl bg-slate-100" />
          </div>
        ) : (
          <div className="space-y-5">
            <div className="rounded-[26px] bg-gradient-to-br from-slate-950 via-slate-900 to-cyan-900 p-5 text-white">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-300">
                Bakici Profili
              </p>
              <h2 className="mt-3 text-2xl font-black">
                {selectedSitter.displayName}
              </h2>
              <p className="mt-2 text-sm text-slate-300">
                {selectedSitter.userId?.email || 'Iletisim bilgisi yok'}
              </p>
              <div className="mt-4 flex flex-wrap gap-2">
                <SoftBadge dark>
                  {selectedSitter.isVerified ? 'Dogrulanmis' : 'Beklemede'}
                </SoftBadge>
                <SoftBadge dark>
                  {selectedSitter.isActive ? 'Aktif profil' : 'Pasif profil'}
                </SoftBadge>
                {selectedSitter.availability ? (
                  <SoftBadge dark>
                    {selectedSitter.availability === 'available'
                      ? 'Musait'
                      : selectedSitter.availability}
                  </SoftBadge>
                ) : null}
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <MetricBox
                label="Puan"
                value={(selectedSitter.rating || 0).toFixed(1)}
                helper={`${selectedSitter.reviewCount || 0} yorum`}
              />
              <MetricBox
                label="Tamamlanan"
                value={performance.completed || 0}
                helper="Kapanan rezervasyon"
              />
              <MetricBox
                label="Aktif Is"
                value={performance.active || 0}
                helper="Devam eden hizmet"
              />
              <MetricBox
                label="Toplam Kazanc"
                value={formatCurrency(performance.totalRevenue || 0)}
                helper={`Bu ay ${formatCurrency(performance.monthlyRevenue || 0)}`}
              />
            </div>

            <DetailSection
              title="Rezervasyon Dagilimi"
              subtitle="Operasyonel durumlarin admin gorunumu."
            >
              <div className="space-y-3">
                {Object.entries(bookingLabels).map(([key, label]) => (
                  <ProgressRow
                    key={key}
                    label={label}
                    value={performance[key] || 0}
                    max={totalBookings}
                  />
                ))}
              </div>
            </DetailSection>

            <DetailSection
              title="Hizmet Kirilimi"
              subtitle="Hangi servis tiplerinde daha cok talep aliyor."
            >
              {serviceBreakdown.length ? (
                <div className="space-y-3">
                  {serviceBreakdown.map((item) => (
                    <ProgressRow
                      key={item.serviceType}
                      label={serviceLabels[item.serviceType] || item.serviceType}
                      value={item.count || 0}
                      max={totalBookings}
                    />
                  ))}
                </div>
              ) : (
                <EmptyMini text="Hizmet dagilimi icin veri bulunmuyor." />
              )}
            </DetailSection>

            <DetailSection
              title="Son Yorumlar"
              subtitle="Owner review verisinden son 5 kayit."
            >
              {insights?.recentReviews?.length ? (
                <div className="space-y-3">
                  {insights.recentReviews.map((review) => (
                    <div key={review._id} className="rounded-2xl bg-slate-50 p-4">
                      <div className="flex items-center justify-between gap-3">
                        <div>
                          <p className="font-semibold text-slate-900">
                            {review.owner?.name || 'Musteri'}
                          </p>
                          <p className="text-xs text-slate-400">
                            {formatDate(review.createdAt)}
                          </p>
                        </div>
                        <span className="rounded-full bg-amber-100 px-2 py-1 text-xs font-semibold text-amber-700">
                          {review.rating}/5
                        </span>
                      </div>
                      <p className="mt-2 text-xs font-medium uppercase tracking-[0.14em] text-slate-400">
                        {serviceLabels[review.serviceType] || review.serviceType}
                      </p>
                      {review.comment ? (
                        <p className="mt-3 text-sm leading-6 text-slate-600">
                          {review.comment}
                        </p>
                      ) : null}
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyMini text="Bu bakici icin yorum bulunmuyor." />
              )}
            </DetailSection>

            <DetailSection
              title="Profil Ozeti"
              subtitle="Hizmet ve tur kapsami."
            >
              <div className="space-y-4">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                    Hizmetler
                  </p>
                  <div className="mt-3 flex flex-wrap gap-2">
                    {(selectedSitter.services || []).length ? (
                      selectedSitter.services.map((service) => (
                        <StatusBadge key={service.type} tone="blue">
                          {serviceLabels[service.type] || service.type}
                        </StatusBadge>
                      ))
                    ) : (
                      <span className="text-sm text-slate-400">Hizmet kaydi yok</span>
                    )}
                  </div>
                </div>
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                    Hizmet Verilen Turler
                  </p>
                  <div className="mt-3 flex flex-wrap gap-2">
                    {(selectedSitter.speciesServed || []).length ? (
                      selectedSitter.speciesServed.map((species) => (
                        <StatusBadge key={species} tone="slate">
                          {species}
                        </StatusBadge>
                      ))
                    ) : (
                      <span className="text-sm text-slate-400">Tur bilgisi yok</span>
                    )}
                  </div>
                </div>
              </div>
            </DetailSection>
          </div>
        )}
      </aside>
    </div>
  )
}

function DetailSection({ title, subtitle, children }) {
  return (
    <section className="rounded-[24px] border border-slate-100 bg-white">
      <div className="border-b border-slate-100 px-4 py-4">
        <h3 className="text-sm font-bold text-slate-900">{title}</h3>
        <p className="mt-1 text-xs leading-5 text-slate-500">{subtitle}</p>
      </div>
      <div className="p-4">{children}</div>
    </section>
  )
}

function MetricBox({ label, value, helper }) {
  return (
    <div className="rounded-3xl bg-slate-50 p-4">
      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">
        {label}
      </p>
      <p className="mt-2 text-2xl font-black text-slate-900">{value}</p>
      <p className="mt-1 text-xs text-slate-500">{helper}</p>
    </div>
  )
}

function ProgressRow({ label, value, max }) {
  const ratio = Math.max(0, Math.min(1, value / Math.max(max, 1)))
  return (
    <div>
      <div className="flex items-center justify-between gap-3">
        <span className="text-sm text-slate-600">{label}</span>
        <span className="text-sm font-semibold text-slate-900">
          {value.toLocaleString('tr-TR')}
        </span>
      </div>
      <div className="mt-2 h-2 overflow-hidden rounded-full bg-slate-100">
        <div
          className="h-full rounded-full bg-cyan-500"
          style={{ width: `${Math.max(ratio * 100, value ? 8 : 0)}%` }}
        />
      </div>
    </div>
  )
}

function StatusBadge({ children, tone = 'slate' }) {
  const classes = {
    slate: 'bg-slate-100 text-slate-700',
    blue: 'bg-blue-100 text-blue-700',
    green: 'bg-green-100 text-green-700',
    red: 'bg-red-100 text-red-600',
  }

  return (
    <span
      className={`rounded-full px-2 py-1 text-xs font-semibold ${
        classes[tone] || classes.slate
      }`}
    >
      {children}
    </span>
  )
}

function SoftBadge({ children, dark = false }) {
  return (
    <span
      className={`rounded-full px-2 py-1 text-xs font-semibold ${
        dark
          ? 'border border-white/10 bg-white/10 text-slate-100'
          : 'bg-slate-100 text-slate-700'
      }`}
    >
      {children}
    </span>
  )
}

function EmptyPanel({ title, text }) {
  return (
    <div className="flex min-h-[420px] flex-col items-center justify-center rounded-[28px] border border-dashed border-slate-200 bg-slate-50 px-6 text-center">
      <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-900 text-white">
        S
      </div>
      <h2 className="mt-4 text-lg font-bold text-slate-900">{title}</h2>
      <p className="mt-2 max-w-xs text-sm leading-6 text-slate-500">{text}</p>
    </div>
  )
}

function EmptyMini({ text }) {
  return (
    <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-4 py-8 text-center text-sm text-slate-400">
      {text}
    </div>
  )
}

function formatCurrency(value) {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: 'TRY',
    maximumFractionDigits: 0,
  }).format(value || 0)
}

function formatDate(value) {
  if (!value) return '-'
  return new Date(value).toLocaleString('tr-TR', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  })
}
