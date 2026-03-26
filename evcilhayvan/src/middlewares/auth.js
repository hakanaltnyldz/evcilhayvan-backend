import { verifyToken } from "../utils/jwt.js";
import { sendError } from "../utils/apiResponse.js";
import User from "../models/User.js";

/**
 * Rol bazlı auth middleware.
 * allowedRoles verildiğinde kullanıcının güncel rolünü DB'den doğrular;
 * böylece ban/rol değişiklikleri mevcut token'ları geçersiz kılar.
 * @param {Array<string>} allowedRoles
 */
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
      return sendError(res, 401, "Geçersiz veya süresi dolmuş token", "invalid_token");
    }

    // Rol kısıtlaması olan endpoint'lerde DB'den güncel rolü doğrula
    // (ban, rol değişikliği vb. anlık etkili olsun)
    if (allowedRoles.length > 0) {
      try {
        const dbUser = await User.findById(payload.sub).select("role").lean();
        if (!dbUser) {
          return sendError(res, 401, "Kullanıcı bulunamadı", "user_not_found");
        }
        if (dbUser.role === "banned") {
          return sendError(res, 403, "Hesabınız askıya alınmıştır", "account_banned");
        }
        if (!allowedRoles.includes(dbUser.role)) {
          return sendError(res, 403, "Erişim reddedildi. Bu işlem için yetkiniz yok.", "forbidden");
        }
        // payload'ı güncel DB rolüyle güncelle
        payload = { ...payload, role: dbUser.role };
      } catch (err) {
        return sendError(res, 500, "Yetki doğrulama hatası", "auth_error");
      }
    } else {
      // Rol kısıtlaması olmasa bile banned kullanıcıyı engelle
      if (payload.role === "banned") {
        try {
          const dbUser = await User.findById(payload.sub).select("role").lean();
          if (dbUser?.role === "banned") {
            return sendError(res, 403, "Hesabınız askıya alınmıştır", "account_banned");
          }
        } catch (_) { /* DB hatası → token'daki role'e güven */ }
      }
    }

    req.user = { ...payload, _id: payload.sub };
    next();
  };
}

// Basit auth middleware (rol kontrolü olmadan)
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
    return sendError(res, 401, "Geçersiz veya süresi dolmuş token", "invalid_token");
  }

  // Banned kullanıcıyı engelle
  if (payload.role === "banned") {
    try {
      const dbUser = await User.findById(payload.sub).select("role").lean();
      if (dbUser?.role === "banned") {
        return sendError(res, 403, "Hesabınız askıya alınmıştır", "account_banned");
      }
    } catch (_) { /* DB hatası → devam et */ }
  }

  req.user = { ...payload, _id: payload.sub };
  next();
};
