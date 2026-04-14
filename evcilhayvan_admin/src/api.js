import axios from 'axios'
import { clearSession, getSessionToken } from './lib/session.js'

const rawBaseUrl =
  import.meta.env.VITE_API_URL || 'https://evcilhayvan-backend.onrender.com/api'

const BASE_URL = rawBaseUrl.endsWith('/api')
  ? rawBaseUrl
  : `${rawBaseUrl.replace(/\/$/, '')}/api`

const api = axios.create({ baseURL: BASE_URL })

api.interceptors.request.use((config) => {
  const token = getSessionToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      clearSession()
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
