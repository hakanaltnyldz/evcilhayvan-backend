import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  ArrowTrendingUpIcon,
  ClipboardDocumentListIcon,
  LifebuoyIcon,
  ReceiptPercentIcon,
  ShieldCheckIcon,
  ShoppingCartIcon,
  UserGroupIcon,
} from '@heroicons/react/24/outline'
import api from '../api.js'
import StatCard from '../components/StatCard.jsx'

const quickLinks = [
  {
    to: '/support',
    title: 'Destek Akisi',
    text: 'Acil destek taleplerini gor, not ekle ve durumu guncelle.',
    icon: LifebuoyIcon,
  },
  {
    to: '/seller-applications',
    title: 'Satici Basvurulari',
    text: 'Bekleyen satici taleplerini ayni gun icinde sonuclandir.',
    icon: ClipboardDocumentListIcon,
  },
  {
    to: '/audit-logs',
    title: 'Audit Kayitlari',
    text: 'Kim hangi kritik islemi yapti, geriye donuk olarak izle.',
    icon: ShieldCheckIcon,
  },
]

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    api.get('/admin/stats')
      .then((response) => setStats(response.data?.stats || null))
      .catch((requestError) => {
        setError(requestError.response?.data?.message || 'Istatistikler alinamadi')
      })
      .finally(() => setLoading(false))
  }, [])

  if (error) {
    return (
      <div className="rounded-[28px] border border-rose-200 bg-rose-50 p-6 text-rose-700">
        {error}
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <section className="grid gap-6 xl:grid-cols-[1.35fr_0.65fr]">
        <div className="rounded-[32px] bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 p-7 text-white shadow-panel">
          <div className="max-w-2xl">
            <span className="inline-flex rounded-full border border-white/10 bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-slate-200">
              Operasyon Merkezi
            </span>
            <h2 className="mt-4 text-3xl font-black tracking-tight">
              Moderasyon, destek ve partner akislarini ayni merkezden yonetin.
            </h2>
            <p className="mt-4 max-w-xl text-sm leading-7 text-slate-300">
              Yeni seller workspace ile beraber panel tek girise indi. Bu ekran kritik
              yogunlugu, destek yuku ve ticari akislar icin hizli bir kontrol noktasi sunar.
            </p>
          </div>

          <div className="mt-8 grid gap-4 md:grid-cols-3">
            <MiniMetric
              label="Bekleyen Basvuru"
              value={stats?.pendingSellerApplications}
              icon={ClipboardDocumentListIcon}
            />
            <MiniMetric
              label="Acik Destek"
              value={stats?.openSupportTickets}
              icon={LifebuoyIcon}
            />
            <MiniMetric
              label="Bekleyen Sikayet"
              value={stats?.pendingReports}
              icon={ArrowTrendingUpIcon}
            />
          </div>
        </div>

        <div className="rounded-[32px] border border-white bg-white p-6 shadow-panel">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">
            Hizli Erisim
          </p>
          <div className="mt-4 space-y-3">
            {quickLinks.map(({ to, title, text, icon: Icon }) => (
              <Link
                key={to}
                to={to}
                className="group flex items-start gap-4 rounded-3xl border border-slate-100 bg-slate-50/80 p-4 transition hover:border-slate-200 hover:bg-white"
              >
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-slate-900 text-white">
                  <Icon className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-slate-900 group-hover:text-indigo-700">
                    {title}
                  </p>
                  <p className="mt-1 text-sm leading-6 text-slate-500">{text}</p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Toplam Kullanici"
          value={stats?.totalUsers}
          loading={loading}
          color="indigo"
          icon={<UserGroupIcon className="h-6 w-6" />}
          subtitle="Tum aktif ve pasif hesaplar"
        />
        <StatCard
          title="Bu Ay Yeni Uye"
          value={stats?.newUsersThisMonth}
          loading={loading}
          color="green"
          icon={<ArrowTrendingUpIcon className="h-6 w-6" />}
          subtitle="Ay basindan bugune yeni kayit"
        />
        <StatCard
          title="Toplam Siparis"
          value={stats?.totalOrders}
          loading={loading}
          color="orange"
          icon={<ShoppingCartIcon className="h-6 w-6" />}
          subtitle="Ticari akisin genel hacmi"
        />
        <StatCard
          title="Aktif Kupon"
          value={stats?.totalActiveCoupons}
          loading={loading}
          color="purple"
          icon={<ReceiptPercentIcon className="h-6 w-6" />}
          subtitle="Yayinda kalan kampanyalar"
        />
      </section>

      <section className="grid gap-5 lg:grid-cols-3">
        <StatCard
          title="Aktif Ilan"
          value={stats?.activePets}
          loading={loading}
          color="blue"
          icon={<ShieldCheckIcon className="h-6 w-6" />}
          subtitle={`${stats?.totalPets || 0} toplam ilandan yayinda olanlar`}
        />
        <StatCard
          title="Bekleyen Seller"
          value={stats?.pendingSellerApplications}
          loading={loading}
          color="slate"
          icon={<ClipboardDocumentListIcon className="h-6 w-6" />}
          subtitle="Onay bekleyen yeni magaza basvurulari"
        />
        <StatCard
          title="Acik Destek Ticket"
          value={stats?.openSupportTickets}
          loading={loading}
          color="red"
          icon={<LifebuoyIcon className="h-6 w-6" />}
          subtitle="Panelden anlik yanitlanabilecek kayitlar"
        />
      </section>
    </div>
  )
}

function MiniMetric({ label, value, icon: Icon }) {
  return (
    <div className="rounded-[26px] border border-white/10 bg-white/8 p-4 backdrop-blur-sm">
      <div className="flex items-center justify-between gap-3">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-300">
          {label}
        </p>
        <Icon className="h-5 w-5 text-slate-200" />
      </div>
      <p className="mt-3 text-3xl font-black">{(value ?? 0).toLocaleString('tr-TR')}</p>
    </div>
  )
}
