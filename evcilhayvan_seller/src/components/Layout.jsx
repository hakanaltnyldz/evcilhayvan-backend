import { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import {
  HomeIcon,
  CubeIcon,
  ShoppingCartIcon,
  TagIcon,
  BuildingStorefrontIcon,
  ChartBarIcon,
  ArrowRightOnRectangleIcon,
  Bars3Icon,
  XMarkIcon,
} from '@heroicons/react/24/outline';

const navItems = [
  { to: '/',              icon: HomeIcon,                label: 'Dashboard',     end: true },
  { to: '/products',      icon: CubeIcon,                label: 'Ürünler' },
  { to: '/orders',        icon: ShoppingCartIcon,        label: 'Siparişler' },
  { to: '/coupons',       icon: TagIcon,                 label: 'Kuponlar' },
  { to: '/analytics',     icon: ChartBarIcon,            label: 'Analitik' },
  { to: '/store-profile', icon: BuildingStorefrontIcon,  label: 'Mağaza Profili' },
];

export default function Layout() {
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const user = (() => {
    try { return JSON.parse(localStorage.getItem('seller_user') || '{}'); }
    catch { return {}; }
  })();

  const handleLogout = () => {
    localStorage.removeItem('seller_token');
    localStorage.removeItem('seller_user');
    navigate('/login');
  };

  const SidebarContent = () => (
    <div className="flex flex-col h-full">
      {/* Logo */}
      <div className="px-6 py-5 border-b border-primary-500/30">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center text-xl">
            🐾
          </div>
          <div>
            <p className="font-bold text-white text-sm leading-tight">Evcil Hayvan</p>
            <p className="text-primary-200 text-xs">Satıcı Paneli</p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto scrollbar-thin">
        {navItems.map(({ to, icon: Icon, label, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            onClick={() => setSidebarOpen(false)}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition-all ${
                isActive
                  ? 'bg-white/20 text-white shadow-sm'
                  : 'text-primary-100 hover:bg-white/10 hover:text-white'
              }`
            }
          >
            <Icon className="w-5 h-5 flex-shrink-0" />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* User + logout */}
      <div className="px-3 py-4 border-t border-primary-500/30">
        <div className="flex items-center gap-3 px-4 py-3 rounded-xl bg-white/10 mb-2">
          <div className="w-8 h-8 rounded-full bg-primary-300 flex items-center justify-center text-primary-800 font-bold text-sm">
            {(user.name || 'S')[0].toUpperCase()}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-white text-sm font-semibold truncate">{user.name || 'Satıcı'}</p>
            <p className="text-primary-200 text-xs truncate">{user.email || ''}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="flex items-center gap-2 w-full px-4 py-2.5 rounded-xl text-sm font-medium text-primary-100 hover:bg-red-500/20 hover:text-red-300 transition-all"
        >
          <ArrowRightOnRectangleIcon className="w-5 h-5" />
          Çıkış Yap
        </button>
      </div>
    </div>
  );

  return (
    <div className="flex h-screen bg-primary-50 overflow-hidden">
      {/* Desktop Sidebar */}
      <aside className="hidden lg:flex flex-col w-60 bg-gradient-to-b from-primary-700 to-primary-600 flex-shrink-0">
        <SidebarContent />
      </aside>

      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        >
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />
        </div>
      )}

      {/* Mobile Sidebar Drawer */}
      <aside
        className={`fixed top-0 left-0 z-50 flex flex-col w-60 h-full
          bg-gradient-to-b from-primary-700 to-primary-600
          transform transition-transform duration-300 lg:hidden
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}
      >
        <button
          onClick={() => setSidebarOpen(false)}
          className="absolute top-4 right-4 text-white/70 hover:text-white p-1"
        >
          <XMarkIcon className="w-6 h-6" />
        </button>
        <SidebarContent />
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top bar (mobile only) */}
        <header className="lg:hidden flex items-center gap-3 px-4 py-3 bg-white border-b border-gray-100 shadow-sm">
          <button
            onClick={() => setSidebarOpen(true)}
            className="p-2 rounded-lg hover:bg-gray-100 text-primary-700"
          >
            <Bars3Icon className="w-6 h-6" />
          </button>
          <div className="flex items-center gap-2">
            <span className="text-lg">🐾</span>
            <span className="font-bold text-primary-700 text-sm">Satıcı Paneli</span>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto p-6 scrollbar-thin">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
