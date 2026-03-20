import { Outlet, NavLink, useNavigate } from 'react-router-dom'

const navItems = [
  { to: '/', label: 'Dashboard', icon: '📊', end: true },
  { to: '/users', label: 'Kullanıcılar', icon: '👥' },
  { to: '/pets', label: 'İlanlar', icon: '🐾' },
  { to: '/reports', label: 'Şikayetler', icon: '⚠️' },
  { to: '/orders', label: 'Siparişler', icon: '🛒' },
  { to: '/posts', label: 'Gönderiler', icon: '📝' },
]

export default function Layout() {
  const navigate = useNavigate()

  function handleLogout() {
    localStorage.removeItem('admin_token')
    navigate('/login')
  }

  return (
    <div className="flex h-screen bg-gray-100">
      {/* Sidebar */}
      <aside className="w-56 bg-white shadow-lg flex flex-col">
        <div className="px-6 py-5 border-b">
          <span className="text-lg font-bold text-indigo-600">🐾 Admin Panel</span>
        </div>
        <nav className="flex-1 px-3 py-4 space-y-1">
          {navItems.map(({ to, label, icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-indigo-50 text-indigo-700'
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                }`
              }
            >
              <span>{icon}</span>
              {label}
            </NavLink>
          ))}
        </nav>
        <div className="px-3 py-4 border-t">
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium text-red-600 hover:bg-red-50 transition-colors"
          >
            <span>🚪</span> Çıkış Yap
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto p-8">
        <Outlet />
      </main>
    </div>
  )
}
