import { useEffect, useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import api from '../api.js'

const SOURCE_OPTIONS = [
  { value: 'all', label: 'Tum Kaynaklar' },
  { value: 'reports', label: 'Sikayetler' },
  { value: 'support', label: 'Destek' },
  { value: 'posts', label: 'Gonderiler' },
  { value: 'care_reports', label: 'Bakim Raporlari' },
]

const STATUS_OPTIONS = [
  { value: 'open', label: 'Acik Isler' },
  { value: 'resolved', label: 'Cozulenler' },
  { value: 'all', label: 'Tum Durumlar' },
]

const sourcePills = {
  report: 'bg-rose-100 text-rose-700',
  support: 'bg-amber-100 text-amber-700',
  post: 'bg-indigo-100 text-indigo-700',
  care_report: 'bg-emerald-100 text-emerald-700',
}

const priorityPills = {
  high: 'bg-rose-100 text-rose-700',
  medium: 'bg-amber-100 text-amber-700',
  low: 'bg-slate-100 text-slate-700',
}

const actionLabels = {
  reviewed: 'Incele',
  dismissed: 'Reddet',
  reviewing: 'Incelemeye Al',
  closed: 'Kapat',
  open: 'Yeniden Ac',
  hide: 'Gizle',
  unhide: 'Yayina Al',
  delete: 'Sil',
}

const actionClasses = {
  reviewed: 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200',
  dismissed: 'bg-slate-100 text-slate-700 hover:bg-slate-200',
  reviewing: 'bg-amber-100 text-amber-700 hover:bg-amber-200',
  closed: 'bg-slate-900 text-white hover:bg-slate-700',
  open: 'bg-indigo-100 text-indigo-700 hover:bg-indigo-200',
  hide: 'bg-amber-100 text-amber-700 hover:bg-amber-200',
  unhide: 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200',
  delete: 'bg-rose-100 text-rose-700 hover:bg-rose-200',
}

function buildMediaUrl(raw) {
  if (!raw) return null
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw
  const apiBase = api.defaults.baseURL || ''
  const backendBase = apiBase.replace(/\/api\/?$/, '')
  return `${backendBase}${raw}`
}

function SummaryCard({ title, value, hint, tone }) {
  const toneClass =
    tone === 'rose'
      ? 'text-rose-600'
      : tone === 'amber'
        ? 'text-amber-600'
        : tone === 'emerald'
          ? 'text-emerald-600'
          : 'text-slate-900'

  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <p className="text-sm text-slate-500">{title}</p>
      <p className={`mt-3 text-3xl font-black ${toneClass}`}>{value}</p>
      <p className="mt-2 text-xs text-slate-500">{hint}</p>
    </div>
  )
}

export default function ModerationQueue() {
  const [items, setItems] = useState([])
  const [summary, setSummary] = useState(null)
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [source, setSource] = useState('all')
  const [status, setStatus] = useState('open')
  const [searchInput, setSearchInput] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [loading, setLoading] = useState(true)
  const [actingKey, setActingKey] = useState('')

  async function loadQueue() {
    setLoading(true)
    try {
      const res = await api.get('/admin/moderation/queue', {
        params: {
          page,
          source,
          status,
          ...(searchQuery ? { search: searchQuery } : {}),
        },
      })
      setItems(res.data?.items || [])
      setSummary(res.data?.summary || null)
      setTotal(res.data?.total || 0)
    } catch (err) {
      toast.error(err.response?.data?.message || 'Moderasyon kuyrugu alinamadi')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadQueue()
  }, [page, source, status, searchQuery])

  async function handleAction(item, action) {
    const key = `${item.queueId}:${action}`
    if (action === 'delete' && !window.confirm('Bu kaydi moderasyon akisindan kalici olarak silmek istiyor musunuz?')) {
      return
    }

    setActingKey(key)
    try {
      await api.patch(`/admin/moderation/queue/${item.source}/${item.entityId}`, { action })
      toast.success(`${actionLabels[action] || action} uygulandi`)
      loadQueue()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Moderasyon aksiyonu basarisiz')
    } finally {
      setActingKey('')
    }
  }

  function submitSearch(event) {
    event.preventDefault()
    setPage(1)
    setSearchQuery(searchInput.trim())
  }

  const totalPages = Math.max(1, Math.ceil(total / 20))

  const summaryCards = useMemo(() => {
    if (!summary) return []
    return [
      {
        title: 'Acik Moderasyon',
        value: summary.totalOpenItems ?? 0,
        hint: 'Tum kaynaklardan gelen aktif aksiyon ihtiyaci',
        tone: 'rose',
      },
      {
        title: 'Bekleyen Sikayet',
        value: summary.openReports ?? 0,
        hint: 'Kullanici kaynakli dogrudan sikayetler',
        tone: 'amber',
      },
      {
        title: 'Acik Destek',
        value: summary.openSupportTickets ?? 0,
        hint: 'Icerik ve kullanici sikayeti ticketlari',
        tone: 'slate',
      },
      {
        title: 'Gizli Gonderi',
        value: summary.hiddenPosts ?? 0,
        hint: 'Yayindan alinmis ve tekrar bakilmasi gereken paylasimlar',
        tone: 'emerald',
      },
    ]
  }, [summary])

  return (
    <div className="space-y-6">
      <div className="rounded-3xl bg-gradient-to-r from-slate-950 via-slate-900 to-rose-950 p-6 text-white shadow-xl">
        <p className="text-xs font-semibold uppercase tracking-[0.24em] text-rose-200">Moderation Queue</p>
        <div className="mt-2 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <h1 className="text-3xl font-black">Icerik Moderasyon Kuyrugu</h1>
            <p className="mt-2 max-w-3xl text-sm text-slate-300">
              Sikayetler, support complaint ticket’lari, gizlenmis gonderiler ve yeni bakim raporlarini tek listede toparlar.
            </p>
          </div>
          <button
            type="button"
            onClick={loadQueue}
            className="rounded-2xl border border-white/15 bg-white/10 px-5 py-3 text-sm font-semibold text-white transition hover:bg-white/15"
          >
            Listeyi Yenile
          </button>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {summaryCards.map((card) => (
          <SummaryCard key={card.title} {...card} />
        ))}
      </div>

      <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="grid gap-3 lg:grid-cols-[0.9fr_0.9fr_1.2fr_auto]">
          <label className="block">
            <span className="mb-2 block text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Kaynak</span>
            <select
              value={source}
              onChange={(e) => {
                setSource(e.target.value)
                setPage(1)
              }}
              className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-900 focus:border-indigo-300 focus:outline-none"
            >
              {SOURCE_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </label>

          <label className="block">
            <span className="mb-2 block text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Durum</span>
            <select
              value={status}
              onChange={(e) => {
                setStatus(e.target.value)
                setPage(1)
              }}
              className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-900 focus:border-indigo-300 focus:outline-none"
            >
              {STATUS_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </label>

          <form onSubmit={submitSearch} className="block">
            <span className="mb-2 block text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Arama</span>
            <div className="flex gap-3">
              <input
                type="text"
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                placeholder="Not, mesaj veya gonderi metni ara"
                className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-900 placeholder:text-slate-400 focus:border-indigo-300 focus:outline-none"
              />
              <button
                type="submit"
                className="rounded-2xl bg-indigo-600 px-5 py-3 text-sm font-semibold text-white transition hover:bg-indigo-700"
              >
                Filtrele
              </button>
            </div>
          </form>

          <div className="self-end rounded-2xl bg-slate-100 px-4 py-3 text-sm text-slate-600">
            {total} kayit
          </div>
        </div>
      </div>

      {loading ? (
        <div className="rounded-3xl border border-slate-200 bg-white p-12 text-center text-slate-400 shadow-sm">
          Kuyruk yukleniyor...
        </div>
      ) : items.length === 0 ? (
        <div className="rounded-3xl border border-dashed border-slate-300 bg-white p-12 text-center shadow-sm">
          <div className="text-4xl">Queue Clear</div>
          <p className="mt-3 text-sm text-slate-500">
            Secili filtrelerde islem bekleyen icerik bulunmuyor.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {items.map((item) => {
            const mediaUrl = buildMediaUrl(item.media)
            return (
              <article
                key={item.queueId}
                className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm"
              >
                <div className="flex flex-col gap-5 p-5 xl:flex-row">
                  <div className="flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className={`rounded-full px-3 py-1 text-xs font-semibold ${sourcePills[item.source] || 'bg-slate-100 text-slate-700'}`}>
                        {item.source}
                      </span>
                      <span className={`rounded-full px-3 py-1 text-xs font-semibold ${priorityPills[item.priority] || priorityPills.low}`}>
                        {item.priority === 'high' ? 'Yuksek' : item.priority === 'medium' ? 'Orta' : 'Dusuk'}
                      </span>
                      <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700">
                        {item.badge}
                      </span>
                      <span className="ml-auto text-xs font-medium text-slate-400">
                        {new Date(item.createdAt).toLocaleString('tr-TR')}
                      </span>
                    </div>

                    <div className="mt-4">
                      <h2 className="text-xl font-bold text-slate-900">{item.title}</h2>
                      <p className="mt-1 text-sm font-medium text-slate-500">{item.subtitle}</p>
                      <p className="mt-3 text-sm leading-6 text-slate-700">{item.excerpt}</p>
                    </div>

                    <div className="mt-4 flex flex-wrap gap-3">
                      {(item.metrics || []).map((metric) => (
                        <div key={`${item.queueId}:${metric.label}`} className="rounded-2xl bg-slate-100 px-4 py-3">
                          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400">{metric.label}</p>
                          <p className="mt-1 text-sm font-semibold text-slate-800">{metric.value}</p>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="flex w-full flex-col gap-4 xl:w-80">
                    {mediaUrl ? (
                      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-100">
                        <img src={mediaUrl} alt={item.title} className="h-44 w-full object-cover" />
                      </div>
                    ) : (
                      <div className="flex h-44 items-center justify-center rounded-2xl border border-dashed border-slate-300 bg-slate-50 text-sm font-semibold text-slate-400">
                        Gorsel yok
                      </div>
                    )}

                    <div className="flex flex-wrap gap-2">
                      {(item.actions || []).map((action) => {
                        const buttonKey = `${item.queueId}:${action}`
                        return (
                          <button
                            key={action}
                            type="button"
                            onClick={() => handleAction(item, action)}
                            disabled={actingKey === buttonKey}
                            className={`rounded-2xl px-4 py-2 text-sm font-semibold transition ${actionClasses[action] || 'bg-slate-100 text-slate-700 hover:bg-slate-200'} ${
                              actingKey === buttonKey ? 'cursor-not-allowed opacity-60' : ''
                            }`}
                          >
                            {actingKey === buttonKey ? '...' : actionLabels[action] || action}
                          </button>
                        )
                      })}
                    </div>
                  </div>
                </div>
              </article>
            )
          })}
        </div>
      )}

      {totalPages > 1 ? (
        <div className="flex items-center justify-center gap-3">
          <button
            type="button"
            onClick={() => setPage((prev) => Math.max(1, prev - 1))}
            disabled={page === 1}
            className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >
            Onceki
          </button>
          <span className="text-sm font-medium text-slate-500">
            {page} / {totalPages}
          </span>
          <button
            type="button"
            onClick={() => setPage((prev) => Math.min(totalPages, prev + 1))}
            disabled={page === totalPages}
            className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >
            Sonraki
          </button>
        </div>
      ) : null}
    </div>
  )
}
