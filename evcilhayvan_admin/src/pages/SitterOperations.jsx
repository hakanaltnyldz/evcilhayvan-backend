import { useCallback, useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import api from '../api.js'
import { resolveMediaUrl } from '../lib/media.js'

const tabs = [
  { key: 'bookings', label: 'Rezervasyonlar' },
  { key: 'walks', label: 'Yuruyus Akisi' },
  { key: 'reports', label: 'Bakim Raporlari' },
]

const bookingStatuses = [
  { key: 'all', label: 'Tumu' },
  { key: 'pending', label: 'Bekleyen' },
  { key: 'accepted', label: 'Onaylanan' },
  { key: 'active', label: 'Aktif' },
  { key: 'completed', label: 'Tamamlanan' },
  { key: 'cancelled', label: 'Iptal' },
  { key: 'rejected', label: 'Reddedilen' },
]

const serviceLabels = {
  walking: 'Gezdirme',
  home_sitting: 'Evde bakim',
  boarding: 'Pansiyon',
  daycare: 'Gunduz bakim',
  grooming: 'Timar',
}

const bookingLabels = {
  pending: 'Bekleyen',
  accepted: 'Onaylanan',
  active: 'Aktif',
  completed: 'Tamamlanan',
  cancelled: 'Iptal',
  rejected: 'Reddedilen',
}

const updateLabels = {
  location: 'Konum',
  photo: 'Fotograf',
  note: 'Not',
  arrived: 'Varis',
  walk_started: 'Basladi',
  walk_ended: 'Bitti',
}

const moodLabels = {
  great: 'Cok iyi',
  good: 'Iyi',
  okay: 'Normal',
  tired: 'Yorgun',
}

const activityLabels = {
  walk: 'Yuruyus',
  play: 'Oyun',
  grooming: 'Bakim',
  vet_visit: 'Veteriner',
  bath: 'Banyo',
  training: 'Egitim',
}

export default function SitterOperations() {
  const [activeTab, setActiveTab] = useState('bookings')
  const [pages, setPages] = useState({ bookings: 1, walks: 1, reports: 1 })
  const [bookingStatus, setBookingStatus] = useState('all')
  const [rows, setRows] = useState([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)

  const currentPage = pages[activeTab] || 1

  const loadRows = useCallback(async () => {
    setLoading(true)
    try {
      const params = { page: currentPage }
      let endpoint = '/admin/sitter-bookings'
      let dataKey = 'bookings'

      if (activeTab === 'walks') {
        endpoint = '/admin/walk-updates'
        dataKey = 'updates'
      } else if (activeTab === 'reports') {
        endpoint = '/admin/care-reports'
        dataKey = 'reports'
      } else if (bookingStatus !== 'all') {
        params.status = bookingStatus
      }

      const response = await api.get(endpoint, { params })
      setRows(response.data?.[dataKey] || [])
      setTotal(response.data?.total || 0)
    } catch (error) {
      toast.error(error.response?.data?.message || 'Operasyon verileri yuklenemedi')
      setRows([])
      setTotal(0)
    } finally {
      setLoading(false)
    }
  }, [activeTab, bookingStatus, currentPage])

  useEffect(() => {
    loadRows()
  }, [loadRows])

  function changeTab(nextTab) {
    setActiveTab(nextTab)
  }

  function setCurrentPage(nextPage) {
    setPages((current) => ({ ...current, [activeTab]: nextPage }))
  }

  const totalPages = Math.ceil(total / 20)

  return (
    <div>
      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Bakici Operasyonlari</h1>
          <p className="mt-1 text-sm text-slate-500">
            Rezervasyon, yuruyus guncellemesi ve bakim raporlarini tek ekranda izleyin.
          </p>
        </div>
        <button
          type="button"
          onClick={loadRows}
          disabled={loading}
          className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50 disabled:opacity-50"
        >
          {loading ? 'Yenileniyor...' : 'Yenile'}
        </button>
      </div>

      <div className="mb-5 flex flex-wrap gap-2">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            onClick={() => changeTab(tab.key)}
            className={`rounded-2xl px-4 py-2 text-sm font-semibold transition ${
              activeTab === tab.key
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {activeTab === 'bookings' ? (
        <div className="mb-6 flex flex-wrap gap-2">
          {bookingStatuses.map((status) => (
            <button
              key={status.key}
              type="button"
              onClick={() => {
                setBookingStatus(status.key)
                setPages((current) => ({ ...current, bookings: 1 }))
              }}
              className={`rounded-xl px-3 py-1.5 text-xs font-semibold transition ${
                bookingStatus === status.key
                  ? 'bg-slate-900 text-white'
                  : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
              }`}
            >
              {status.label}
            </button>
          ))}
        </div>
      ) : null}

      <div className="mb-4 flex items-center justify-between">
        <span className="text-sm font-semibold text-slate-700">
          {total.toLocaleString('tr-TR')} kayit
        </span>
        <span className="text-xs text-slate-400">Sayfa {currentPage}</span>
      </div>

      {loading ? (
        <LoadingState />
      ) : rows.length === 0 ? (
        <EmptyState />
      ) : (
        <div className="space-y-4">
          {activeTab === 'bookings'
            ? rows.map((booking) => <BookingCard key={booking._id || booking.id} booking={booking} />)
            : null}
          {activeTab === 'walks'
            ? rows.map((update) => <WalkUpdateCard key={update._id || update.id} update={update} />)
            : null}
          {activeTab === 'reports'
            ? rows.map((report) => <CareReportCard key={report._id || report.id} report={report} />)
            : null}
        </div>
      )}

      {totalPages > 1 ? (
        <div className="mt-6 flex justify-center gap-2">
          <button
            type="button"
            onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
            disabled={currentPage === 1 || loading}
            className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40"
          >
            Onceki
          </button>
          <span className="px-4 py-2 text-sm text-slate-500">
            {currentPage} / {totalPages}
          </span>
          <button
            type="button"
            onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
            disabled={currentPage === totalPages || loading}
            className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40"
          >
            Sonraki
          </button>
        </div>
      ) : null}
    </div>
  )
}

function BookingCard({ booking }) {
  return (
    <article className="rounded-3xl border border-slate-100 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-lg font-bold text-slate-900">
              {serviceLabels[booking.serviceType] || booking.serviceType || 'Hizmet'}
            </h2>
            <StatusBadge status={booking.status} />
          </div>
          <p className="mt-1 text-sm text-slate-500">
            {formatDate(booking.startDate)} - {formatDate(booking.endDate)}
          </p>
        </div>
        <div className="text-right">
          <p className="text-xl font-black text-slate-900">{formatCurrency(booking.totalPrice)}</p>
          <p className="text-xs text-slate-400">Rezervasyon tutari</p>
        </div>
      </div>

      <div className="mt-5 grid gap-3 md:grid-cols-3">
        <InfoBox label="Evcil hayvan sahibi" value={displayUser(booking.petOwnerId)} />
        <InfoBox label="Bakici" value={displayUser(booking.sitterUserId)} />
        <InfoBox
          label="Takip"
          value={booking.liveTracking?.isActive ? 'Konum takibi aktif' : 'Konum takibi pasif'}
        />
      </div>

      {booking.notes ? (
        <p className="mt-4 rounded-2xl bg-slate-50 px-4 py-3 text-sm leading-6 text-slate-600">
          {booking.notes}
        </p>
      ) : null}
    </article>
  )
}

function WalkUpdateCard({ update }) {
  const booking = update.bookingId || {}
  const coords = Array.isArray(update.coordinates) ? update.coordinates : []
  const lng = Number(coords[0])
  const lat = Number(coords[1])
  const hasCoords = Number.isFinite(lat) && Number.isFinite(lng)
  const photoUrl = resolveMediaUrl(update.photoUrl)

  return (
    <article className="rounded-3xl border border-slate-100 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-lg font-bold text-slate-900">
              {updateLabels[update.type] || update.type || 'Guncelleme'}
            </h2>
            {booking.status ? <StatusBadge status={booking.status} /> : null}
          </div>
          <p className="mt-1 text-sm text-slate-500">{formatDateTime(update.timestamp)}</p>
        </div>
        {hasCoords ? (
          <a
            href={`https://www.google.com/maps?q=${lat},${lng}`}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-xl bg-indigo-50 px-3 py-2 text-xs font-semibold text-indigo-700 hover:bg-indigo-100"
          >
            Haritada Ac
          </a>
        ) : null}
      </div>

      <div className="mt-5 grid gap-3 md:grid-cols-3">
        <InfoBox label="Hizmet" value={serviceLabels[booking.serviceType] || booking.serviceType || '-'} />
        <InfoBox label="Sahip" value={displayUser(booking.petOwnerId)} />
        <InfoBox label="Baslangic" value={formatDate(booking.startDate)} />
      </div>

      <div className="mt-4 flex flex-wrap gap-4">
        {photoUrl ? (
          <img
            src={photoUrl}
            alt="Yuruyus guncellemesi"
            className="h-28 w-28 rounded-2xl object-cover"
          />
        ) : null}
        <div className="min-w-[240px] flex-1 rounded-2xl bg-slate-50 px-4 py-3 text-sm leading-6 text-slate-600">
          {update.message || 'Mesaj eklenmemis.'}
          {hasCoords ? (
            <p className="mt-2 font-mono text-xs text-slate-400">
              {lat.toFixed(5)}, {lng.toFixed(5)}
            </p>
          ) : null}
        </div>
      </div>
    </article>
  )
}

function CareReportCard({ report }) {
  const booking = report.bookingId || {}
  const photos = Array.isArray(report.photos) ? report.photos.slice(0, 4) : []

  return (
    <article className="rounded-3xl border border-slate-100 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-lg font-bold text-slate-900">Gun {report.day || '-'}</h2>
            <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
              {moodLabels[report.mood] || report.mood || 'Durum yok'}
            </span>
            {booking.status ? <StatusBadge status={booking.status} /> : null}
          </div>
          <p className="mt-1 text-sm text-slate-500">{formatDateTime(report.timestamp)}</p>
        </div>
        <span
          className={`rounded-xl px-3 py-2 text-xs font-semibold ${
            report.foodEaten ? 'bg-green-50 text-green-700' : 'bg-amber-50 text-amber-700'
          }`}
        >
          {report.foodEaten ? 'Yemek yedi' : 'Yemek yemedi'}
        </span>
      </div>

      <div className="mt-5 grid gap-3 md:grid-cols-3">
        <InfoBox label="Hizmet" value={serviceLabels[booking.serviceType] || booking.serviceType || '-'} />
        <InfoBox label="Sahip" value={displayUser(booking.petOwnerId)} />
        <InfoBox label="Baslangic" value={formatDate(booking.startDate)} />
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        {(report.activities || []).length ? (
          report.activities.map((activity) => (
            <span key={activity} className="rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-600">
              {activityLabels[activity] || activity}
            </span>
          ))
        ) : (
          <span className="text-xs text-slate-400">Aktivite girilmemis</span>
        )}
      </div>

      {report.notes ? (
        <p className="mt-4 rounded-2xl bg-slate-50 px-4 py-3 text-sm leading-6 text-slate-600">
          {report.notes}
        </p>
      ) : null}

      {photos.length ? (
        <div className="mt-4 flex flex-wrap gap-2">
          {photos.map((photo) => {
            const url = resolveMediaUrl(photo)
            return url ? (
              <img
                key={photo}
                src={url}
                alt="Bakim raporu"
                className="h-20 w-20 rounded-2xl object-cover"
              />
            ) : null
          })}
        </div>
      ) : null}
    </article>
  )
}

function InfoBox({ label, value }) {
  return (
    <div className="rounded-2xl bg-slate-50 px-4 py-3">
      <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">{label}</p>
      <p className="mt-1 truncate text-sm font-semibold text-slate-800">{value || '-'}</p>
    </div>
  )
}

function StatusBadge({ status }) {
  const tone = {
    pending: 'bg-amber-50 text-amber-700',
    accepted: 'bg-blue-50 text-blue-700',
    active: 'bg-indigo-50 text-indigo-700',
    completed: 'bg-green-50 text-green-700',
    cancelled: 'bg-red-50 text-red-700',
    rejected: 'bg-rose-50 text-rose-700',
  }

  return (
    <span className={`rounded-full px-2 py-1 text-xs font-semibold ${tone[status] || 'bg-slate-100 text-slate-600'}`}>
      {bookingLabels[status] || status || 'Durum yok'}
    </span>
  )
}

function LoadingState() {
  return (
    <div className="space-y-4">
      {[1, 2, 3].map((item) => (
        <div key={item} className="h-40 animate-pulse rounded-3xl bg-white shadow-sm" />
      ))}
    </div>
  )
}

function EmptyState() {
  return (
    <div className="rounded-3xl border border-dashed border-slate-200 bg-white py-16 text-center text-sm text-slate-400">
      Kayit bulunamadi
    </div>
  )
}

function displayUser(user) {
  if (!user) return '-'
  return user.name || user.email || '-'
}

function formatDate(value) {
  if (!value) return '-'
  return new Date(value).toLocaleDateString('tr-TR')
}

function formatDateTime(value) {
  if (!value) return '-'
  return new Date(value).toLocaleString('tr-TR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function formatCurrency(value) {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: 'TRY',
    maximumFractionDigits: 0,
  }).format(value || 0)
}
