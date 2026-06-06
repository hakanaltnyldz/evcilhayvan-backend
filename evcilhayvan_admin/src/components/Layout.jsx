import { useMemo, useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import {
  ArrowRightOnRectangleIcon,
  Bars3Icon,
  ShieldCheckIcon,
  ShoppingBagIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline'
import { getNavigationByRole, getPageMeta } from '../config/navigation.js'
import { clearSession, getSessionRole, getSessionUser } from '../lib/session.js'

const roleThemes = {
  admin: {
    shell: 'bg-slate-100',
    sidebar: 'from-slate-950 via-slate-900 to-indigo-950',
    sidebarBorder: 'border-white/10',
    active: 'bg-white/12 text-white shadow-lg shadow-black/10',
    inactive: 'text-slate-300 hover:bg-white/6 hover:text-white',
    badge: 'bg-indigo-500/20 text-indigo-100 ring-1 ring-indigo-300/25',
    accent: 'bg-indigo-500 text-white',
    roleLabel: 'Admin Workspace',
    roleIcon: ShieldCheckIcon,
  },
  seller: {
    shell: 'bg-emerald-50',
    sidebar: 'from-primary-900 via-primary-800 to-primary-700',
    sidebarBorder: 'border-white/10',
    active: 'bg-white/14 text-white shadow-lg shadow-primary-950/15',
    inactive: 'text-primary-100 hover:bg-white/8 hover:text-white',
    badge: 'bg-emerald-400/18 text-emerald-50 ring-1 ring-emerald-200/25',
    accent: 'bg-primary-500 text-white',
    roleLabel: 'Satici Workspace',
    roleIcon: ShoppingBagIcon,
  },
}

export default function Layout() {
  const location = useLocation()
  const navigate = useNavigate()
  const [mobileOpen, setMobileOpen] = useState(false)
  const role = getSessionRole() || 'admin'
  const user = getSessionUser() || {}
  const sections = getNavigationByRole(role)
  const pageMeta = getPageMeta(location.pathname, role)
  const theme = roleThemes[role] || roleThemes.admin
  const RoleIcon = theme.roleIcon

  const pageDescription = useMemo(() => {
    const descriptions = {
      '/dashboard': 'Tum yonetim akislarini tek ekrandan izleyin.',
      '/users': 'Rol, ban ve hesap temizligi islemlerini buradan yonetin.',
      '/pets': 'Yayinda olan ve kapatilan ilanlari anlik kontrol edin.',
      '/orders': 'Kargo ve siparis sureclerini merkezi olarak yonetin.',
      '/returns': 'Iade taleplerini inceleyin, onaylayin veya gerekce ile reddedin.',
      '/platform-settings': 'Komisyon, feature flag ve operasyonel esikleri canli ortam icin yonetin.',
      '/moderation-queue': 'Sikayet, support ve icerik akislarini tek moderasyon kuyruunda toplayin.',
      '/reports': 'Sikayet ve moderasyon akisini hizli sekilde sonuclandirin.',
      '/support': 'Destek taleplerine ic not ve durum guncellemesi ekleyin.',
      '/sitter-operations': 'Bakici rezervasyonlari, yuruyus akisi ve bakim raporlarini izleyin.',
      '/seller': 'Magaza performansi, siparisler ve urunler burada toplandi.',
      '/seller/products': 'Urun katalounu guncelleyin, stok ve gorunurlugu kontrol edin.',
      '/seller/orders': 'Satici siparislerini filtreleyin ve kargo akisini yonetin.',
      '/seller/store-profile': 'Magaza vitrini, sosyal alanlar ve gorseller buradan duzenlenir.',
      '/seller-applications': 'Yeni satici basvurularini onaylayin veya reddedin.',
      '/audit-logs': 'Yapilan kritik degisikliklerin iz kaydini inceleyin.',
    }

    return descriptions[pageMeta?.to] || 'Panel islemleri role gore bu alanda toplanir.'
  }, [pageMeta])

  function handleLogout() {
    clearSession()
    navigate('/login')
  }

  function SidebarContent() {
    return (
      <div className="flex h-full flex-col">
        <div className={`border-b px-6 py-5 ${theme.sidebarBorder}`}>
          <div className="flex items-center gap-3">
            <div className={`flex h-11 w-11 items-center justify-center rounded-2xl ${theme.badge}`}>
              <RoleIcon className="h-6 w-6" />
            </div>
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-white">Evcil Hayvan Paneli</p>
              <p className="truncate text-xs text-slate-300">{theme.roleLabel}</p>
            </div>
          </div>
        </div>

        <div className="flex-1 space-y-6 overflow-y-auto px-4 py-5 scrollbar-thin">
          {sections.map((section) => (
            <div key={section.title}>
              <p className="px-3 pb-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400">
                {section.title}
              </p>
              <div className="space-y-1">
                {section.items.map(({ to, label, icon: Icon }) => (
                  <NavLink
                    key={to}
                    to={to}
                    end={to === '/seller' || to === '/dashboard'}
                    onClick={() => setMobileOpen(false)}
                    className={({ isActive }) =>
                      `flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium transition-all ${
                        isActive ? theme.active : theme.inactive
                      }`
                    }
                  >
                    <Icon className="h-5 w-5 flex-shrink-0" />
                    <span>{label}</span>
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className={`border-t px-4 py-4 ${theme.sidebarBorder}`}>
          <div className="mb-3 rounded-2xl bg-white/8 px-4 py-3">
            <div className="flex items-center gap-3">
              <div className={`flex h-10 w-10 items-center justify-center rounded-full ${theme.badge}`}>
                <span className="text-sm font-bold">
                  {(user.name || user.email || role || 'P')[0]?.toUpperCase()}
                </span>
              </div>
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold text-white">{user.name || 'Panel Kullanici'}</p>
                <p className="truncate text-xs text-slate-300">{user.email || theme.roleLabel}</p>
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={handleLogout}
            className="flex w-full items-center justify-center gap-2 rounded-2xl border border-white/10 px-4 py-3 text-sm font-semibold text-white transition hover:bg-white/8"
          >
            <ArrowRightOnRectangleIcon className="h-5 w-5" />
            Cikis Yap
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className={`min-h-screen ${theme.shell}`}>
      <div className="flex min-h-screen">
        <aside className={`hidden w-72 flex-col bg-gradient-to-b lg:flex ${theme.sidebar}`}>
          <SidebarContent />
        </aside>

        {mobileOpen && (
          <div className="fixed inset-0 z-40 bg-slate-950/45 backdrop-blur-sm lg:hidden" onClick={() => setMobileOpen(false)} />
        )}

        <aside
          className={`fixed inset-y-0 left-0 z-50 w-72 transform bg-gradient-to-b ${theme.sidebar} transition-transform duration-300 lg:hidden ${
            mobileOpen ? 'translate-x-0' : '-translate-x-full'
          }`}
        >
          <button
            type="button"
            onClick={() => setMobileOpen(false)}
            className="absolute right-4 top-4 rounded-xl p-2 text-white/70 hover:bg-white/10 hover:text-white"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
          <SidebarContent />
        </aside>

        <div className="flex min-w-0 flex-1 flex-col">
          <header className="sticky top-0 z-30 border-b border-white/70 bg-white/90 backdrop-blur-xl">
            <div className="flex items-center justify-between gap-4 px-4 py-4 sm:px-6 lg:px-8">
              <div className="flex min-w-0 items-center gap-3">
                <button
                  type="button"
                  onClick={() => setMobileOpen(true)}
                  className="rounded-2xl border border-slate-200 bg-white p-2 text-slate-700 shadow-sm lg:hidden"
                >
                  <Bars3Icon className="h-6 w-6" />
                </button>
                <div className="min-w-0">
                  <div className="mb-1 flex flex-wrap items-center gap-2">
                    <span className={`rounded-full px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] ${theme.badge}`}>
                      {theme.roleLabel}
                    </span>
                    <span className="text-sm text-slate-400">{pageMeta?.label || 'Panel'}</span>
                  </div>
                  <h1 className="truncate text-xl font-bold text-slate-900 sm:text-2xl">
                    {pageMeta?.label || 'Yonetim Paneli'}
                  </h1>
                  <p className="mt-1 hidden text-sm text-slate-500 sm:block">
                    {pageDescription}
                  </p>
                </div>
              </div>

              <div className="hidden items-center gap-3 rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-sm sm:flex">
                <div className="min-w-0 text-right">
                  <p className="truncate text-sm font-semibold text-slate-900">{user.name || 'Panel Kullanici'}</p>
                  <p className="truncate text-xs text-slate-500">{user.email || role}</p>
                </div>
                <div className={`flex h-11 w-11 items-center justify-center rounded-full ${theme.accent}`}>
                  <span className="text-sm font-bold">
                    {(user.name || user.email || role || 'P')[0]?.toUpperCase()}
                  </span>
                </div>
              </div>
            </div>
          </header>

          <main className="flex-1 px-4 py-6 sm:px-6 lg:px-8">
            <Outlet />
          </main>
        </div>
      </div>
    </div>
  )
}
