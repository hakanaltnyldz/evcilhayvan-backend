import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ShieldCheckIcon,
  ShoppingBagIcon,
  SparklesIcon,
} from '@heroicons/react/24/outline'
import api from '../api.js'
import { getDefaultRouteForRole, saveSession } from '../lib/session.js'

export default function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setError('')
    setLoading(true)

    try {
      const response = await api.post('/auth/login', { email, password })
      const token = response.data?.token
      const user = response.data?.user
      const role = user?.role

      if (!token || !user) {
        throw new Error('Oturum bilgisi alinamadi')
      }

      if (role !== 'admin' && role !== 'seller') {
        throw new Error('Bu panel yalnizca admin ve satici hesaplari icindir')
      }

      saveSession(token, user)
      navigate(getDefaultRouteForRole(role), { replace: true })
    } catch (requestError) {
      setError(requestError.response?.data?.message || requestError.message || 'Giris basarisiz')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen overflow-hidden bg-slate-950">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,_rgba(99,102,241,0.24),_transparent_32%),radial-gradient(circle_at_bottom_right,_rgba(16,185,129,0.18),_transparent_28%),linear-gradient(135deg,_#020617,_#111827_55%,_#1e293b)]" />
      <div className="relative grid min-h-screen items-center gap-10 px-4 py-12 lg:grid-cols-[1.15fr_0.85fr] lg:px-10">
        <section className="mx-auto w-full max-w-2xl text-white lg:mx-0">
          <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/6 px-4 py-2 text-sm text-slate-200 backdrop-blur">
            <SparklesIcon className="h-4 w-4 text-emerald-300" />
            Tek giris, iki ayri workspace
          </div>

          <div className="mt-6 max-w-xl">
            <h1 className="text-4xl font-black leading-tight sm:text-5xl">
              Admin ve satici girisini tek panelde topladik.
            </h1>
            <p className="mt-5 text-base leading-7 text-slate-300 sm:text-lg">
              Satici hesabi ayni giris ekranindan oturum acar, kendi workspace alanina duser.
              Admin hesabi ise operasyon, moderasyon ve partner yonetimini ayni uygulamada surdurur.
            </p>
          </div>

          <div className="mt-8 grid gap-4 sm:grid-cols-2">
            <FeatureCard
              icon={ShieldCheckIcon}
              title="Admin Workspace"
              text="Kullanicilar, siparisler, destek, kuponlar, partner onaylari ve audit kayitlari tek yerde."
            />
            <FeatureCard
              icon={ShoppingBagIcon}
              title="Satici Workspace"
              text="Urun, siparis, kupon, analitik ve magaza vitrini ayri bir panele gitmeden yonetilir."
            />
          </div>
        </section>

        <section className="mx-auto w-full max-w-md">
          <div className="rounded-[32px] border border-white/10 bg-white/95 p-8 shadow-2xl shadow-slate-950/30 backdrop-blur">
            <div className="mb-8">
              <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-900 text-white">
                <ShieldCheckIcon className="h-7 w-7" />
              </div>
              <h2 className="text-2xl font-bold text-slate-900">Panel Girisi</h2>
              <p className="mt-2 text-sm leading-6 text-slate-500">
                Admin veya satici hesabinizla ayni noktadan oturum acin.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="mb-1.5 block text-sm font-semibold text-slate-700">E-posta</label>
                <input
                  type="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  required
                  placeholder="ornek@mail.com"
                  className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400 focus:ring-4 focus:ring-indigo-100"
                />
              </div>

              <div>
                <label className="mb-1.5 block text-sm font-semibold text-slate-700">Sifre</label>
                <input
                  type="password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  required
                  placeholder="••••••••"
                  className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400 focus:ring-4 focus:ring-indigo-100"
                />
              </div>

              {error && (
                <div className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-2xl bg-slate-900 px-4 py-3.5 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {loading ? 'Giris yapiliyor...' : 'Panele Gir'}
              </button>
            </form>

            <div className="mt-6 rounded-2xl bg-slate-50 px-4 py-4 text-xs leading-6 text-slate-500">
              Giris sonrasi rolunuze gore ilgili workspace otomatik acilir. Ayrica seller
              modulu artik ayri bir uygulamaya ihtiyac duymadan ayni panelde calisir.
            </div>
          </div>
        </section>
      </div>
    </div>
  )
}

function FeatureCard({ icon: Icon, title, text }) {
  return (
    <div className="rounded-[28px] border border-white/10 bg-white/6 p-5 backdrop-blur">
      <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-2xl bg-white/10 text-white">
        <Icon className="h-5 w-5" />
      </div>
      <h3 className="text-lg font-semibold text-white">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-slate-300">{text}</p>
    </div>
  )
}
