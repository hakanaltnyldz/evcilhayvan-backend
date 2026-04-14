import { useEffect, useState } from 'react'
import { ClipboardDocumentListIcon } from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'
import api from '../api.js'

export default function SellerApplications() {
  const [applications, setApplications] = useState([])
  const [loading, setLoading] = useState(true)
  const [actionId, setActionId] = useState(null)
  const [rejectTarget, setRejectTarget] = useState(null)
  const [rejectionReason, setRejectionReason] = useState('')

  useEffect(() => {
    loadApplications()
  }, [])

  async function loadApplications() {
    setLoading(true)
    try {
      const response = await api.get('/admin/seller/applications')
      setApplications(response.data?.applications || [])
    } catch (error) {
      toast.error(error.response?.data?.message || 'Satici basvurulari yuklenemedi')
    } finally {
      setLoading(false)
    }
  }

  async function approveApplication(application) {
    setActionId(application._id || application.id)
    try {
      await api.patch(`/admin/seller/applications/${application._id || application.id}/approve`)
      toast.success('Basvuru onaylandi')
      loadApplications()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Onay islemi basarisiz')
    } finally {
      setActionId(null)
    }
  }

  async function rejectApplication() {
    if (!rejectTarget) return
    setActionId(rejectTarget._id || rejectTarget.id)
    try {
      await api.patch(`/admin/seller/applications/${rejectTarget._id || rejectTarget.id}/reject`, {
        rejectionReason: rejectionReason.trim(),
      })
      toast.success('Basvuru reddedildi')
      setRejectTarget(null)
      setRejectionReason('')
      loadApplications()
    } catch (error) {
      toast.error(error.response?.data?.message || 'Reddetme islemi basarisiz')
    } finally {
      setActionId(null)
    }
  }

  return (
    <div className="space-y-6">
      <div className="rounded-[32px] bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 p-6 text-white shadow-panel">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-slate-300">Partner Yonetimi</p>
        <h2 className="mt-2 text-3xl font-black">Satici Basvurulari</h2>
        <p className="mt-2 max-w-3xl text-sm leading-7 text-slate-300">
          Yeni seller kayitlarini bu ekrandan onaylayin, reddedin ve gerekce kaydedin.
        </p>
      </div>

      <div className="overflow-hidden rounded-[32px] border border-white bg-white shadow-panel">
        {loading ? (
          <div className="space-y-3 p-6">
            {Array.from({ length: 4 }).map((_, index) => (
              <div key={index} className="h-20 animate-pulse rounded-3xl bg-slate-100" />
            ))}
          </div>
        ) : applications.length === 0 ? (
          <div className="px-6 py-20 text-center">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-3xl bg-indigo-50 text-indigo-600">
              <ClipboardDocumentListIcon className="h-8 w-8" />
            </div>
            <h3 className="mt-5 text-xl font-bold text-slate-900">Bekleyen basvuru yok</h3>
            <p className="mt-2 text-sm leading-6 text-slate-500">
              Yeni seller talepleri geldiginde bu alan otomatik dolar.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-slate-50 text-left text-xs uppercase tracking-[0.18em] text-slate-500">
                <tr>
                  <th className="px-5 py-4 font-semibold">Basvuran</th>
                  <th className="px-5 py-4 font-semibold">Sirket</th>
                  <th className="px-5 py-4 font-semibold">Iletisim</th>
                  <th className="px-5 py-4 font-semibold">Durum</th>
                  <th className="px-5 py-4 font-semibold text-right">Islemler</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {applications.map((application) => (
                  <tr key={application._id || application.id} className="hover:bg-slate-50/80">
                    <td className="px-5 py-4">
                      <p className="font-semibold text-slate-900">{application.user?.name || 'Kullanici'}</p>
                      <p className="mt-1 text-xs text-slate-400">{application.user?.email || '—'}</p>
                    </td>
                    <td className="px-5 py-4">
                      <p className="font-semibold text-slate-900">{application.companyName}</p>
                      <p className="mt-1 text-xs text-slate-500">{application.companyTitle}</p>
                    </td>
                    <td className="px-5 py-4 text-slate-600">
                      <p>{application.contactInfo}</p>
                      <p className="mt-1 text-xs text-slate-400">Vergi: {application.taxNumber}</p>
                    </td>
                    <td className="px-5 py-4">
                      <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${
                        application.status === 'approved'
                          ? 'bg-emerald-50 text-emerald-700'
                          : application.status === 'rejected'
                          ? 'bg-rose-50 text-rose-700'
                          : 'bg-amber-50 text-amber-700'
                      }`}>
                        {application.status}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex justify-end gap-2">
                        <button
                          type="button"
                          disabled={actionId === (application._id || application.id) || application.status !== 'pending'}
                          onClick={() => approveApplication(application)}
                          className="rounded-2xl bg-emerald-600 px-4 py-2 text-xs font-semibold text-white transition hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
                        >
                          Onayla
                        </button>
                        <button
                          type="button"
                          disabled={actionId === (application._id || application.id) || application.status !== 'pending'}
                          onClick={() => {
                            setRejectTarget(application)
                            setRejectionReason(application.rejectionReason || '')
                          }}
                          className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-2 text-xs font-semibold text-rose-700 transition hover:bg-rose-100 disabled:cursor-not-allowed disabled:opacity-60"
                        >
                          Reddet
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {rejectTarget ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-950/50 backdrop-blur-sm" onClick={() => setRejectTarget(null)} />
          <div className="relative w-full max-w-lg rounded-[32px] bg-white shadow-2xl">
            <div className="border-b border-slate-100 px-6 py-5">
              <h3 className="text-lg font-bold text-slate-900">Basvuruyu reddet</h3>
            </div>
            <div className="space-y-4 px-6 py-5">
              <p className="text-sm leading-6 text-slate-500">
                <span className="font-semibold text-slate-900">{rejectTarget.companyName}</span> basvurusu icin gerekce kaydedin.
              </p>
              <textarea
                rows={4}
                value={rejectionReason}
                onChange={(event) => setRejectionReason(event.target.value)}
                className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400 focus:ring-4 focus:ring-indigo-100"
              />
              <div className="flex gap-3">
                <button type="button" onClick={() => setRejectTarget(null)} className="flex-1 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-600">
                  Vazgec
                </button>
                <button type="button" onClick={rejectApplication} disabled={actionId === (rejectTarget._id || rejectTarget.id)} className="flex-1 rounded-2xl bg-rose-600 px-4 py-3 text-sm font-semibold text-white disabled:cursor-not-allowed disabled:opacity-60">
                  {actionId === (rejectTarget._id || rejectTarget.id) ? 'Kaydediliyor...' : 'Reddet'}
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}
