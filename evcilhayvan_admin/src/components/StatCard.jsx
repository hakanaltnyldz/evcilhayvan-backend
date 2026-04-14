export default function StatCard({
  title,
  value,
  icon,
  color = 'indigo',
  subtitle = '',
  loading = false,
}) {
  const styles = {
    indigo: 'bg-indigo-50 text-indigo-700 ring-1 ring-indigo-100',
    green: 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-100',
    orange: 'bg-orange-50 text-orange-700 ring-1 ring-orange-100',
    red: 'bg-rose-50 text-rose-700 ring-1 ring-rose-100',
    blue: 'bg-sky-50 text-sky-700 ring-1 ring-sky-100',
    purple: 'bg-violet-50 text-violet-700 ring-1 ring-violet-100',
    slate: 'bg-slate-100 text-slate-700 ring-1 ring-slate-200',
  }

  const displayValue =
    typeof value === 'number'
      ? value.toLocaleString('tr-TR')
      : value || '—'

  return (
    <div className="rounded-[28px] border border-white bg-white p-5 shadow-panel">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1">
          <p className="text-sm font-medium text-slate-500">{title}</p>
          {loading ? (
            <div className="mt-3 h-8 w-24 animate-pulse rounded-xl bg-slate-100" />
          ) : (
            <p className="mt-2 text-3xl font-bold tracking-tight text-slate-900">{displayValue}</p>
          )}
          {subtitle ? (
            <p className="mt-2 text-xs leading-5 text-slate-400">{subtitle}</p>
          ) : null}
        </div>

        {icon ? (
          <div className={`flex h-12 w-12 items-center justify-center rounded-2xl ${styles[color] || styles.indigo}`}>
            {typeof icon === 'string' ? <span className="text-2xl">{icon}</span> : icon}
          </div>
        ) : null}
      </div>
    </div>
  )
}
