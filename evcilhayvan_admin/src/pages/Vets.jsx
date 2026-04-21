import { useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import api from '../api.js'

const appointmentLabels = {
  pending: 'Bekleyen',
  confirmed: 'Onayli',
  completed: 'Tamamlanan',
  cancelled: 'Iptal',
  no_show: 'Gelmedi',
}

export default function Vets() {
  const [vets, setVets] = useState([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [fetchingPhotos, setFetchingPhotos] = useState(null)
  const [verifying, setVerifying] = useState(null)
  const [selectedVetId, setSelectedVetId] = useState('')
  const [selectedVet, setSelectedVet] = useState(null)
  const [insights, setInsights] = useState(null)
  const [insightsLoading, setInsightsLoading] = useState(false)

  useEffect(() => {
    setLoading(true)
    api
      .get('/admin/vets', { params: { page } })
      .then((res) => {
        setVets(res.data?.vets || [])
        setTotal(res.data?.total || 0)
      })
      .catch(() => toast.error('Veterinerler yuklenemedi'))
      .finally(() => setLoading(false))
  }, [page])

  async function openPanel(vet) {
    const vetId = vet.id || vet._id
    setSelectedVetId(vetId)
    setSelectedVet(vet)
    setInsights(null)
    setInsightsLoading(true)
    try {
      const response = await api.get(`/admin/vets/${vetId}/insights`)
      setSelectedVet(response.data?.vet || vet)
      setInsights(response.data?.insights || null)
    } catch (error) {
      toast.error(error.response?.data?.message || 'Veteriner detaylari alinamadi')
    } finally {
      setInsightsLoading(false)
    }
  }

  async function fetchPhotos(vet) {
    const vetId = vet.id || vet._id
    setFetchingPhotos(vetId)
    try {
      const response = await api.post(`/veterinaries/${vetId}/fetch-photos`)
      setVets((current) =>
        current.map((item) =>
          (item.id || item._id) === vetId
            ? { ...item, photos: response.data?.photos || item.photos }
            : item
        )
      )
      if (selectedVetId === vetId) {
        setSelectedVet((current) =>
          current ? { ...current, photos: response.data?.photos || current.photos } : current
        )
      }
      toast.success(response.data?.message || 'Fotograflar guncellendi')
    } catch (error) {
      toast.error(error.response?.data?.message || 'Fotograf cekilemedi')
    } finally {
      setFetchingPhotos(null)
    }
  }

  async function toggleVerify(vet) {
    const vetId = vet.id || vet._id
    setVerifying(vetId)
    try {
      const response = await api.patch(`/admin/vets/${vetId}/verify`, {
        isVerified: !vet.isVerified,
      })
      const updated = response.data?.vet
      setVets((current) =>
        current.map((item) =>
          (item.id || item._id) === vetId
            ? { ...item, isVerified: updated?.isVerified }
            : item
        )
      )
      if (selectedVetId === vetId) {
        setSelectedVet((current) =>
          current ? { ...current, isVerified: updated?.isVerified } : current
        )
      }
      toast.success(
        updated?.isVerified ? 'Veteriner dogrulandi' : 'Dogrulama kaldirildi'
      )
    } catch (error) {
      toast.error(error.response?.data?.message || 'Islem basarisiz')
    } finally {
      setVerifying(null)
    }
  }

  const totalPages = Math.ceil(total / 20)
  const selectedReviewStats = insights?.reviewStats || {}
  const selectedAppointmentStats = insights?.appointmentStats || {}

  return (
    <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_380px]">
      <div>
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">
              Veteriner Klinikleri
            </h1>
            <p className="mt-1 text-sm text-gray-500">{total} klinik</p>
          </div>
        </div>

        {loading ? (
          <div className="py-16 text-center text-gray-400">Yukleniyor...</div>
        ) : (
          <div className="space-y-3">
            {vets.map((vet) => {
              const vetId = vet.id || vet._id
              const isSelected = selectedVetId === vetId
              return (
                <div
                  key={vetId}
                  className={`flex items-center gap-4 rounded-2xl bg-white p-4 shadow-sm transition ${
                    isSelected ? 'ring-2 ring-indigo-200' : ''
                  }`}
                >
                  <button
                    type="button"
                    onClick={() => openPanel(vet)}
                    className="h-14 w-14 flex-shrink-0 overflow-hidden rounded-xl bg-gray-100"
                  >
                    {vet.photos?.[0] ? (
                      <img
                        src={vet.photos[0]}
                        alt={vet.name}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center text-2xl">
                        H
                      </div>
                    )}
                  </button>

                  <button
                    type="button"
                    onClick={() => openPanel(vet)}
                    className="min-w-0 flex-1 text-left"
                  >
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="truncate font-semibold text-gray-800">
                        {vet.name}
                      </span>
                      {vet.isVerified ? (
                        <span className="rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700">
                          Dogrulanmis
                        </span>
                      ) : null}
                      {vet.userId ? (
                        <span className="rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-700">
                          Sahiplenildi
                        </span>
                      ) : null}
                      {vet.googlePlaceId ? (
                        <span className="rounded-full bg-yellow-100 px-2 py-0.5 text-xs font-medium text-yellow-700">
                          Google
                        </span>
                      ) : null}
                    </div>
                    <p className="mt-0.5 truncate text-sm text-gray-500">
                      {vet.address || '-'}
                    </p>
                    <p className="text-xs text-gray-400">
                      {vet.photos?.length || 0} fotograf
                      {vet.googleRating
                        ? ` • ${vet.googleRating} puan (${vet.googleReviewCount || 0})`
                        : ''}
                    </p>
                  </button>

                  <div className="flex flex-shrink-0 items-center gap-2">
                    <button
                      onClick={() => openPanel(vet)}
                      className="rounded-lg bg-indigo-50 px-3 py-1.5 text-xs font-semibold text-indigo-700 transition-colors hover:bg-indigo-100"
                    >
                      Detay
                    </button>
                    <button
                      onClick={() => fetchPhotos(vet)}
                      disabled={fetchingPhotos === vetId}
                      className="rounded-lg bg-yellow-50 px-3 py-1.5 text-xs font-semibold text-yellow-700 transition-colors hover:bg-yellow-100 disabled:opacity-50"
                    >
                      {fetchingPhotos === vetId ? '...' : 'Fotograf'}
                    </button>
                    <button
                      onClick={() => toggleVerify(vet)}
                      disabled={verifying === vetId}
                      className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors disabled:opacity-50 ${
                        vet.isVerified
                          ? 'bg-gray-100 text-gray-600 hover:bg-red-50 hover:text-red-600'
                          : 'bg-green-50 text-green-700 hover:bg-green-100'
                      }`}
                    >
                      {verifying === vetId
                        ? '...'
                        : vet.isVerified
                        ? 'Kaldir'
                        : 'Dogrula'}
                    </button>
                  </div>
                </div>
              )
            })}

            {vets.length === 0 ? (
              <div className="py-16 text-center text-gray-400">
                Veteriner bulunamadi
              </div>
            ) : null}
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
        {!selectedVet ? (
          <EmptyPanel
            title="Detay paneli"
            text="Yorum, puan ve randevu istatistiklerini gormek icin bir klinik secin."
          />
        ) : insightsLoading ? (
          <div className="space-y-4">
            <div className="h-28 animate-pulse rounded-3xl bg-slate-100" />
            <div className="h-24 animate-pulse rounded-3xl bg-slate-100" />
            <div className="h-40 animate-pulse rounded-3xl bg-slate-100" />
          </div>
        ) : (
          <div className="space-y-5">
            <div className="rounded-[26px] bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 p-5 text-white">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-300">
                Klinik Profili
              </p>
              <h2 className="mt-3 text-2xl font-black">{selectedVet.name}</h2>
              <p className="mt-2 text-sm text-slate-300">
                {selectedVet.address || 'Adres bulunmuyor'}
              </p>
              <div className="mt-4 flex flex-wrap gap-2">
                <Badge tone="dark">
                  {selectedVet.isVerified ? 'Dogrulanmis' : 'Beklemede'}
                </Badge>
                <Badge tone="dark">
                  {selectedVet.userId ? 'Sahipli klinik' : 'Sahipsiz profil'}
                </Badge>
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <MetricBox
                label="Puan"
                value={(selectedReviewStats.averageRating || 0).toFixed(1)}
                helper={`${selectedReviewStats.reviewCount || 0} yorum`}
              />
              <MetricBox
                label="Toplam Randevu"
                value={selectedAppointmentStats.total || 0}
                helper="Tum statuler"
              />
              <MetricBox
                label="Onay Bekleyen"
                value={selectedAppointmentStats.pending || 0}
                helper="Aksiyon gerekli"
              />
              <MetricBox
                label="Tamamlanan"
                value={selectedAppointmentStats.completed || 0}
                helper="Kapanan randevu"
              />
            </div>

            <DetailSection
              title="Randevu Dagilimi"
              subtitle="Klinigin uygulama ici appointment yogunlugu."
            >
              <div className="space-y-3">
                {Object.entries(appointmentLabels).map(([key, label]) => (
                  <ProgressRow
                    key={key}
                    label={label}
                    value={selectedAppointmentStats[key] || 0}
                    max={Math.max(selectedAppointmentStats.total || 0, 1)}
                  />
                ))}
              </div>
            </DetailSection>

            <DetailSection
              title="Son Yorumlar"
              subtitle="Admin gorusunde son 5 geri bildirim."
            >
              {insights?.recentReviews?.length ? (
                <div className="space-y-3">
                  {insights.recentReviews.map((review) => (
                    <div
                      key={review._id}
                      className="rounded-2xl bg-slate-50 p-4"
                    >
                      <div className="flex items-center justify-between gap-3">
                        <div>
                          <p className="font-semibold text-slate-900">
                            {review.user?.name || 'Kullanici'}
                          </p>
                          <p className="text-xs text-slate-400">
                            {formatDate(review.createdAt)}
                          </p>
                        </div>
                        <span className="rounded-full bg-amber-100 px-2 py-1 text-xs font-semibold text-amber-700">
                          {review.rating}/5
                        </span>
                      </div>
                      {review.comment ? (
                        <p className="mt-3 text-sm leading-6 text-slate-600">
                          {review.comment}
                        </p>
                      ) : null}
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyMini text="Bu klinik icin yorum bulunmuyor." />
              )}
            </DetailSection>

            <DetailSection
              title="Yaklasan Randevular"
              subtitle="Pending ve confirmed randevularin ozet listesi."
            >
              {insights?.upcomingAppointments?.length ? (
                <div className="space-y-3">
                  {insights.upcomingAppointments.map((appointment) => (
                    <div
                      key={appointment._id}
                      className="rounded-2xl border border-slate-100 p-4"
                    >
                      <div className="flex items-center justify-between gap-3">
                        <p className="font-semibold text-slate-900">
                          {appointment.user?.name || 'Kullanici'}
                        </p>
                        <Badge tone="soft">
                          {appointmentLabels[appointment.status] || appointment.status}
                        </Badge>
                      </div>
                      <p className="mt-1 text-sm text-slate-500">
                        {appointment.pet?.name || 'Pet'} •{' '}
                        {appointment.type === 'online' ? 'Online' : 'Klinik'}
                      </p>
                      <p className="mt-2 text-xs text-slate-400">
                        {formatDate(appointment.date)}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyMini text="Yaklasan randevu yok." />
              )}
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
      <p className="mt-2 text-2xl font-black text-slate-900">
        {Number(value).toLocaleString('tr-TR')}
      </p>
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
          className="h-full rounded-full bg-indigo-500"
          style={{ width: `${Math.max(ratio * 100, value ? 8 : 0)}%` }}
        />
      </div>
    </div>
  )
}

function Badge({ children, tone = 'soft' }) {
  const classes =
    tone === 'dark'
      ? 'bg-white/10 text-slate-100 border border-white/10'
      : 'bg-slate-100 text-slate-700'
  return (
    <span className={`rounded-full px-2 py-1 text-xs font-semibold ${classes}`}>
      {children}
    </span>
  )
}

function EmptyPanel({ title, text }) {
  return (
    <div className="flex min-h-[420px] flex-col items-center justify-center rounded-[28px] border border-dashed border-slate-200 bg-slate-50 px-6 text-center">
      <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-900 text-white">
        V
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

function formatDate(value) {
  if (!value) return '-'
  return new Date(value).toLocaleString('tr-TR', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  })
}
