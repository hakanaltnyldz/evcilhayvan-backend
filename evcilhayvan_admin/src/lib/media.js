const rawBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000'

export const publicBaseUrl = rawBaseUrl.endsWith('/api')
  ? rawBaseUrl.slice(0, -4)
  : rawBaseUrl.replace(/\/$/, '')

export function resolveMediaUrl(value) {
  if (!value) return null
  return value.startsWith('http') ? value : `${publicBaseUrl}${value}`
}
