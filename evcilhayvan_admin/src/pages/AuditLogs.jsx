import { useEffect, useMemo, useState } from 'react'
import { ShieldCheckIcon } from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'
import api from '../api.js'

export default function AuditLogs() {
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(true)
  const [actionFilter, setActionFilter] = useState('')

  useEffect(() => {
    loadLogs()
  }, [])

  async function loadLogs() {
    setLoading(true)
    try {
      const response = await api.get('/admin/audit-logs', { params: { limit: 100 } })
      setLogs(response.data?.logs || [])
    } catch (error) {
      toast.error(error.response?.data?.message || 'Audit loglari yuklenemedi')
    } finally {
      setLoading(false)
    }
  }

  const actions = useMemo(() => {
    return Array.from(new Set(logs.map((log) => log.action).filter(Boolean))).sort()
  }, [logs])

  const filteredLogs = useMemo(() => {
    return actionFilter ? logs.filter((log) => log.action === actionFilter) : logs
  }, [logs, actionFilter])

  return (
    <div className="space-y-6">
      <div className="rounded-[32px] bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 p-6 text-white shadow-panel">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-slate-300">Sistem Izleme</p>
        <h2 className="mt-2 text-3xl font-black">Audit Loglari</h2>
        <p className="mt-2 max-w-3xl text-sm leading-7 text-slate-300">
          Panel icinde yapilan kritik islemlerin iz kayitlarini buradan filtreleyin ve inceleyin.
        </p>
      </div>

      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => setActionFilter('')}
          className={`rounded-2xl px-4 py-3 text-sm font-semibold transition ${
            actionFilter === ''
              ? 'bg-indigo-600 text-white'
              : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
          }`}
        >
          Tum aksiyonlar
        </button>
        {actions.map((action) => (
          <button
            key={action}
            type="button"
            onClick={() => setActionFilter(action)}
            className={`rounded-2xl px-4 py-3 text-sm font-semibold transition ${
              actionFilter === action
                ? 'bg-indigo-600 text-white'
                : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
            }`}
          >
            {action}
          </button>
        ))}
      </div>

      <div className="overflow-hidden rounded-[32px] border border-white bg-white shadow-panel">
        {loading ? (
          <div className="space-y-3 p-6">
            {Array.from({ length: 6 }).map((_, index) => (
              <div key={index} className="h-20 animate-pulse rounded-3xl bg-slate-100" />
            ))}
          </div>
        ) : filteredLogs.length === 0 ? (
          <div className="px-6 py-20 text-center">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-3xl bg-indigo-50 text-indigo-600">
              <ShieldCheckIcon className="h-8 w-8" />
            </div>
            <h3 className="mt-5 text-xl font-bold text-slate-900">Kayit bulunamadi</h3>
            <p className="mt-2 text-sm leading-6 text-slate-500">Secili filtre icin audit kaydi yok.</p>
          </div>
        ) : (
          <div className="space-y-3 p-4">
            {filteredLogs.map((log) => (
              <div key={log.id || log._id} className="rounded-[28px] border border-slate-100 bg-slate-50 px-5 py-4">
                <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-700">
                        {log.action}
                      </span>
                      {log.entityType ? (
                        <span className="rounded-full bg-slate-200 px-2.5 py-1 text-xs font-semibold text-slate-700">
                          {log.entityType}
                        </span>
                      ) : null}
                    </div>
                    <p className="mt-3 text-sm font-semibold text-slate-900">
                      Entity ID: {log.entityId || '—'}
                    </p>
                    <p className="mt-1 text-xs text-slate-500">
                      {new Date(log.createdAt).toLocaleString('tr-TR')}
                    </p>
                    {log.metadata ? (
                      <pre className="mt-4 overflow-x-auto rounded-2xl bg-slate-900 p-4 text-xs leading-6 text-slate-100">
                        {JSON.stringify(log.metadata, null, 2)}
                      </pre>
                    ) : null}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
