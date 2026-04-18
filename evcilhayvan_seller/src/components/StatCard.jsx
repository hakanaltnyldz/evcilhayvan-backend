export default function StatCard({ title, value, icon, color = 'green', subtitle, loading }) {
  const colorMap = {
    green:  { bg: 'bg-primary-50',  text: 'text-primary-700',  icon: 'bg-primary-100 text-primary-600' },
    amber:  { bg: 'bg-amber-50',    text: 'text-amber-700',    icon: 'bg-amber-100 text-amber-600' },
    red:    { bg: 'bg-red-50',      text: 'text-red-700',      icon: 'bg-red-100 text-red-600' },
    blue:   { bg: 'bg-blue-50',     text: 'text-blue-700',     icon: 'bg-blue-100 text-blue-600' },
    purple: { bg: 'bg-purple-50',   text: 'text-purple-700',   icon: 'bg-purple-100 text-purple-600' },
  };
  const c = colorMap[color] || colorMap.green;

  return (
    <div className={`${c.bg} rounded-2xl p-5 border border-white shadow-sm`}>
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-gray-500 text-sm font-medium">{title}</p>
          {loading ? (
            <div className="mt-2 h-8 w-24 bg-gray-200 rounded-lg animate-pulse" />
          ) : (
            <p className={`mt-1 text-2xl font-bold ${c.text}`}>{value ?? '—'}</p>
          )}
          {subtitle && (
            <p className="mt-0.5 text-xs text-gray-400">{subtitle}</p>
          )}
        </div>
        {icon && (
          <div className={`${c.icon} w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0 ml-3`}>
            {icon}
          </div>
        )}
      </div>
    </div>
  );
}
