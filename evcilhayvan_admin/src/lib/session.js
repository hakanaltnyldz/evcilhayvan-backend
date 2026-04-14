const TOKEN_KEYS = ['panel_token', 'admin_token', 'seller_token']
const USER_KEYS = ['panel_user', 'seller_user', 'admin_user']

function safeGet(storage, key) {
  try {
    return storage.getItem(key)
  } catch {
    return null
  }
}

function safeSet(storage, key, value) {
  try {
    storage.setItem(key, value)
  } catch {
    // ignore storage errors
  }
}

function safeRemove(storage, key) {
  try {
    storage.removeItem(key)
  } catch {
    // ignore storage errors
  }
}

function readFromStorages(keys) {
  for (const key of keys) {
    const localValue = safeGet(localStorage, key)
    if (localValue) return localValue

    const sessionValue = safeGet(sessionStorage, key)
    if (sessionValue) return sessionValue
  }
  return null
}

function writePanelToken(token) {
  safeSet(localStorage, 'panel_token', token)
  safeSet(sessionStorage, 'panel_token', token)
}

function writePanelUser(user) {
  const serialized = JSON.stringify(user)
  safeSet(localStorage, 'panel_user', serialized)
  safeSet(sessionStorage, 'panel_user', serialized)
}

function clearLegacyKeys() {
  for (const key of [...TOKEN_KEYS, ...USER_KEYS]) {
    safeRemove(localStorage, key)
    safeRemove(sessionStorage, key)
  }
}

export function getSessionToken() {
  const token = readFromStorages(TOKEN_KEYS)
  if (!token) return null

  writePanelToken(token)
  return token
}

export function getSessionUser() {
  const rawUser = readFromStorages(USER_KEYS)
  if (!rawUser) {
    const hasLegacyAdminToken =
      safeGet(sessionStorage, 'admin_token') || safeGet(localStorage, 'admin_token')

    if (hasLegacyAdminToken) {
      return { role: 'admin' }
    }

    return null
  }

  try {
    const user = JSON.parse(rawUser)
    writePanelUser(user)
    return user
  } catch {
    return null
  }
}

export function getSessionRole() {
  return getSessionUser()?.role || null
}

export function saveSession(token, user) {
  clearLegacyKeys()
  if (token) {
    writePanelToken(token)
  }
  if (user) {
    writePanelUser(user)
  }
}

export function clearSession() {
  clearLegacyKeys()
}

export function getDefaultRouteForRole(role) {
  return role === 'seller' ? '/seller' : '/dashboard'
}

export function isAllowedRole(role, allowedRoles) {
  return Boolean(role && allowedRoles.includes(role))
}
