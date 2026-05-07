import { verifyToken } from "../utils/jwt.js";
import { sendError } from "../utils/apiResponse.js";
import User from "../models/User.js";

async function loadActiveUserRole(userId, res) {
  const dbUser = await User.findById(userId).select("role").lean();
  if (!dbUser) {
    sendError(res, 401, "Kullanici bulunamadi", "user_not_found");
    return null;
  }
  if (dbUser.role === "banned") {
    sendError(res, 403, "Hesabiniz askiya alinmistir", "account_banned");
    return null;
  }
  return dbUser.role;
}

export function authRequired(allowedRoles = []) {
  return async (req, res, next) => {
    if (process.env.NODE_ENV !== "test") {
      console.log(`[Auth] ${req.method} ${req.path}`);
    }

    const hdr = req.headers.authorization || "";
    const token = hdr.startsWith("Bearer ") ? hdr.slice(7) : null;

    if (!token) {
      return sendError(res, 401, "Token gerekli", "auth_required");
    }

    let payload;
    try {
      payload = verifyToken(token);
    } catch (err) {
      return sendError(res, 401, "Gecersiz veya suresi dolmus token", "invalid_token");
    }

    try {
      const currentRole = await loadActiveUserRole(payload.sub, res);
      if (!currentRole) return;

      if (allowedRoles.length > 0 && !allowedRoles.includes(currentRole)) {
        return sendError(res, 403, "Erisim reddedildi. Bu islem icin yetkiniz yok.", "forbidden");
      }

      payload = { ...payload, role: currentRole };
    } catch (err) {
      return sendError(res, 500, "Yetki dogrulama hatasi", "auth_error");
    }

    req.user = { ...payload, _id: payload.sub };
    next();
  };
}

export const protect = async (req, res, next) => {
  if (process.env.NODE_ENV !== "test") {
    console.log(`[Auth] ${req.method} ${req.path}`);
  }

  const hdr = req.headers.authorization || "";
  const token = hdr.startsWith("Bearer ") ? hdr.slice(7) : null;

  if (!token) {
    return sendError(res, 401, "Token gerekli", "auth_required");
  }

  let payload;
  try {
    payload = verifyToken(token);
  } catch (err) {
    return sendError(res, 401, "Gecersiz veya suresi dolmus token", "invalid_token");
  }

  try {
    const currentRole = await loadActiveUserRole(payload.sub, res);
    if (!currentRole) return;
    payload = { ...payload, role: currentRole };
  } catch (err) {
    return sendError(res, 500, "Yetki dogrulama hatasi", "auth_error");
  }

  req.user = { ...payload, _id: payload.sub };
  next();
};
