export default function Table({ columns, rows, loading, emptyText = 'Veri yok' }) {
  if (loading) {
    return (
      <div className="flex justify-center py-16 text-gray-400">
        <span className="animate-spin text-2xl">⏳</span>
      </div>
    )
  }

  if (!rows.length) {
    return <p className="text-center py-12 text-gray-400">{emptyText}</p>
  }

  return (
    <div className="overflow-x-auto rounded-2xl border border-gray-100">
      <table className="min-w-full text-sm">
        <thead className="bg-gray-50 text-gray-500 uppercase text-xs">
          <tr>
            {columns.map((col) => (
              <th key={col.key} className="px-4 py-3 text-left font-semibold tracking-wide">
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-50 bg-white">
          {rows.map((row, i) => (
            <tr key={row._id ?? i} className="hover:bg-gray-50 transition-colors">
              {columns.map((col) => (
                <td key={col.key} className="px-4 py-3 text-gray-700">
                  {col.render ? col.render(row) : row[col.key] ?? '—'}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
