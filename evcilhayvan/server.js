// server.js
import express from "express";
import compression from "compression";
import cors from "cors";
import fs from "fs";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import mongoSanitize from "express-mongo-sanitize";
import mongoose from "mongoose";
import path from "path";
import { createServer } from "http";
import { Server as SocketIOServer } from "socket.io";
import { config } from "./src/config/config.js";
import { attachResponseHelpers, errorHandler } from "./src/utils/apiResponse.js";
import { verifyToken } from "./src/utils/jwt.js";

// Routes
import authRoutes from "./src/routes/authRoutes.js";
import petRoutes from "./src/routes/petRoutes.js";
import advertRoutes from "./src/routes/advertRoutes.js";
import interactionRoutes from "./src/routes/interactionRoutes.js";
import messageRoutes from "./src/routes/messageRoutes.js";
import matchingRoutes from "./src/routes/matchingRoutes.js";
import matchRequestRoutes from "./src/routes/matchRequestRoutes.js";
import adoptionApplicationRoutes from "./src/routes/adoptionApplicationRoutes.js";
import storeRoutes from "./src/routes/storeRoutes.js";
import sellerRoutes from "./src/routes/sellerRoutes.js";
import adminSellerRoutes from "./src/routes/adminSellerRoutes.js";
import storeFrontRoutes from "./src/routes/storeFrontRoutes.js";
import myAdvertRoutes from "./src/routes/myAdvertRoutes.js";
import uploadRoutes from "./src/routes/uploadRoutes.js";
import auditRoutes from "./src/routes/auditRoutes.js";
import testSocketRoutes from "./src/routes/testSocketRoutes.js";
import favoriteRoutes from "./src/routes/favoriteRoutes.js";
import reviewRoutes from "./src/routes/reviewRoutes.js";
import couponRoutes from "./src/routes/couponRoutes.js";
import orderRoutes from "./src/routes/orderRoutes.js";
import addressRoutes from "./src/routes/addressRoutes.js";
import veterinaryRoutes from "./src/routes/veterinaryRoutes.js";
import appointmentRoutes from "./src/routes/appointmentRoutes.js";
import vaccinationRoutes from "./src/routes/vaccinationRoutes.js";
import lostFoundRoutes from "./src/routes/lostFoundRoutes.js";
import petSitterRoutes from "./src/routes/petSitterRoutes.js";
import sitterBookingRoutes from "./src/routes/sitterBookingRoutes.js";
import petEventRoutes from "./src/routes/petEventRoutes.js";
import postRoutes from "./src/routes/postRoutes.js";
import blockReportRoutes from "./src/routes/blockReportRoutes.js";
import healthRoutes from "./src/routes/healthRoutes.js";
import aiRoutes from "./src/routes/aiRoutes.js";
import adminRoutes from "./src/routes/adminRoutes.js";
import supportRoutes from "./src/routes/supportRoutes.js";
import { startVaccinationReminderJob } from "./src/services/vaccinationReminderService.js";
import { seedVaccinationSchedules } from "./src/services/vaccinationSeedService.js";
import { startBirthdayReminderJob } from "./src/services/birthdayReminderService.js";
import { startAppointmentReminderJob } from "./src/services/appointmentReminderService.js";
import { startAdvertExpiryReminderJob } from "./src/services/advertExpiryReminderService.js";
import { initFcm } from "./src/utils/fcm.js";

// --- Firebase Admin init (optional) ---
// FIREBASE_SERVICE_ACCOUNT → JSON içeriği (string olarak) veya dosya yolu
(async () => {
  const saEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!saEnv) {
    console.log("ℹ️  FCM disabled (FIREBASE_SERVICE_ACCOUNT not set)");
    return;
  }
  try {
    const { default: admin } = await import("firebase-admin");
    let serviceAccount;
    // JSON string mi, dosya yolu mu?
    if (saEnv.trim().startsWith("{")) {
      serviceAccount = JSON.parse(saEnv);
    } else if (fs.existsSync(saEnv)) {
      serviceAccount = JSON.parse(fs.readFileSync(saEnv, "utf8"));
    } else {
      console.warn("⚠️  FCM: FIREBASE_SERVICE_ACCOUNT dosyası bulunamadı:", saEnv);
      return;
    }
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    }
    initFcm(admin);
    console.log("✅ Firebase Admin initialized");
  } catch (e) {
    console.warn("⚠️  Firebase Admin init failed:", e.message);
  }
})();

export const app = express();
export const httpServer = createServer(app);

// --- Socket.io ---
export const io = new SocketIOServer(httpServer, {
  cors: {
    origin: config.corsOrigins,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  },
});

// io'yu app'e ekle — routes içinden req.app.get("io") ile erişilebilsin
app.set("io", io);

// User-Socket mapping: userId -> Set of socketIds (user can have multiple connections)
export const userSocketMap = new Map();

// Helper function to get socket IDs for a user
export function getSocketsByUserId(userId) {
  return userSocketMap.get(String(userId)) || new Set();
}

// Helper function to check if user is online
export function isUserOnline(userId) {
  const sockets = userSocketMap.get(String(userId));
  return sockets && sockets.size > 0;
}

// ─── Rate Limiting ─────────────────────────────────────────────────────────
// Genel API: dakikada 100 istek
const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Çok fazla istek gönderildi. Lütfen biraz bekleyin.", code: "rate_limit" },
  skip: (req) => req.path === "/api/health",
});

// Auth endpointleri: 15 dakikada 20 deneme (brute-force koruması)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Çok fazla giriş denemesi. 15 dakika sonra tekrar deneyin.", code: "auth_rate_limit" },
});

// Yükleme endpointleri: dakikada 10
const uploadLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Çok fazla yükleme isteği.", code: "upload_rate_limit" },
});

// Middlewares
app.use(cors({ origin: config.corsOrigins, credentials: true }));
app.use(compression());
app.use(express.json({ limit: "2mb" }));
app.use(helmet());
app.use(morgan(config.env === "production" ? "short" : "dev"));
// NoSQL injection koruması: req.body / req.params içindeki $ ve . operatörlerini temizle
// express-mongo-sanitize — Node 22'de req.query getter çakışmasını önle
app.use((req, res, next) => {
  if (req.body) req.body = mongoSanitize.sanitize(req.body, { replaceWith: '_' });
  if (req.params) req.params = mongoSanitize.sanitize(req.params, { replaceWith: '_' });
  next();
});
app.use("/api", globalLimiter);
app.use("/api/auth/login", authLimiter);
app.use("/api/auth/register", authLimiter);
app.use("/api/auth/forgot-password", authLimiter);
app.use("/api/uploads", uploadLimiter);
app.use((req, res, next) => {
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.charset = "utf-8";
  next();
});
app.use(attachResponseHelpers);

// Static
const __dirname = path.resolve(path.dirname(""));
const uploadStaticPath = path.isAbsolute(config.uploadDir)
  ? config.uploadDir
  : path.join(__dirname, config.uploadDir);
app.use("/uploads", express.static(uploadStaticPath, { maxAge: '7d', etag: true }));

// Health
app.get("/api/health", (_req, res) => res.sendOk({ ok: true }));
app.get("/api/utf8-test", (_req, res) =>
  res.json({
    city: "İstanbul",
    match: "Eşleştirme",
    adopt: "Sahiplendirme",
  })
);

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/pets", petRoutes);
app.use("/api/adverts", advertRoutes);
app.use("/api/interactions", interactionRoutes);
app.use("/api/conversations", messageRoutes);
app.use("/api/matching", matchingRoutes);
app.use("/api/matches", matchRequestRoutes);
app.use("/api/adoption-applications", adoptionApplicationRoutes);
// StoreFront routes MUST come before storeRoutes to prevent /:storeId catching "categories"
app.use("/api", storeFrontRoutes);
app.use("/api/stores", storeRoutes);
app.use("/api/store", storeRoutes);
app.use("/api", sellerRoutes);
app.use("/api", adminSellerRoutes);
app.use("/api/my-adverts", myAdvertRoutes);
app.use("/api/uploads", uploadRoutes);
app.use("/api/admin", auditRoutes);
if (process.env.NODE_ENV !== 'production') {
  app.use("/api/test", testSocketRoutes);
}
app.use("/api/favorites", favoriteRoutes);
app.use("/api", reviewRoutes);
app.use("/api", couponRoutes);
app.use("/api", orderRoutes);
app.use("/api", addressRoutes);
app.use("/api/veterinaries", veterinaryRoutes);
app.use("/api/appointments", appointmentRoutes);
app.use("/api/vaccinations", vaccinationRoutes);
app.use("/api/lost-found", lostFoundRoutes);
app.use("/api/pet-sitters", petSitterRoutes);
app.use("/api/sitter-bookings", sitterBookingRoutes);
app.use("/api/events", petEventRoutes);
app.use("/api", postRoutes);
app.use("/api/users", blockReportRoutes);
app.use("/api/health", healthRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/support", supportRoutes);

// Error handler (keep last)
app.use(errorHandler);

// DB & Server
export async function startServer() {
  try {
    await mongoose.connect(config.mongoUri, {
      maxPoolSize: 10,
      minPoolSize: 2,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      maxIdleTimeMS: 30000,
    });
    console.log("MongoDB connected");
    await seedVaccinationSchedules();
    httpServer.listen(config.port, "0.0.0.0", () => {
      console.log(`Server listening on 0.0.0.0:${config.port}`);
      // Cron job'leri 5'er saniye arayla başlat (MongoDB startup yükünü dağıtmak için)
      startVaccinationReminderJob(io);
      setTimeout(() => startBirthdayReminderJob(io), 5_000);
      setTimeout(() => startAppointmentReminderJob(io), 10_000);
      setTimeout(() => startAdvertExpiryReminderJob(io), 15_000);
      // Keep-alive ping: Render free tier 15dk sonra uyumasın
      setInterval(async () => {
        try {
          await fetch('https://evcilhayvan-backend.onrender.com/api/health');
          console.log('[KeepAlive] ping ok');
        } catch (_) {}
      }, 14 * 60 * 1000);
    });
  } catch (err) {
    console.error("Mongo connection error:", err.message);
    process.exit(1);
  }
}

if (config.env !== "test") {
  startServer();
}

// Socket.io authentication middleware
io.use((socket, next) => {
  try {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) {
      return next(new Error("Kimlik dogrulama gerekli"));
    }
    const decoded = verifyToken(token);
    socket.userId = decoded.sub;
    next();
  } catch (err) {
    next(new Error("Gecersiz veya suresi dolmus token"));
  }
});

// Socket handlers
io.on("connection", (socket) => {
  console.log("Socket connected:", socket.id, "user:", socket.userId);

  const connectedUserId = socket.userId;

  // Otomatik olarak user room'a katıl (artık token'dan alınıyor)
  if (connectedUserId) {
    const userIdStr = String(connectedUserId);
    if (!userSocketMap.has(userIdStr)) {
      userSocketMap.set(userIdStr, new Set());
    }
    userSocketMap.get(userIdStr).add(socket.id);
    socket.join(`user:${userIdStr}`);
    console.log(`User ${userIdStr} joined with socket ${socket.id}. Total connections: ${userSocketMap.get(userIdStr).size}`);
  }

  // Backward compatibility: join:user event'i artık token ile doğrulanıyor
  socket.on("join:user", (userId) => {
    // userId parametresi artık göz ardı edilir, socket.userId kullanılır
    if (!connectedUserId) return;
  });

  socket.on("join:conversation", async (conversationId) => {
    if (!conversationId || !connectedUserId) return;
    // Kullanıcının bu conversation'a erişimi olduğunu doğrula
    try {
      const Conversation = (await import("./src/models/Conversation.js")).default;
      const conv = await Conversation.findOne({
        _id: conversationId,
        participants: connectedUserId,
      });
      if (conv) {
        socket.join(`conv:${conversationId}`);
      }
    } catch (err) {
      console.error("[Socket] join:conversation error:", err.message);
    }
  });

  socket.on("leave:conversation", (conversationId) => {
    if (!conversationId) return;
    socket.leave(`conv:${conversationId}`);
  });

  socket.on("sendMessage", (payload) => {
    const { conversationId } = payload || {};
    if (!conversationId || !connectedUserId) return;
    // Sadece kullanıcı bu conversation room'unda ise mesaj gönderebilir
    const rooms = socket.rooms;
    if (!rooms.has(`conv:${conversationId}`)) return;
    io.to(`conv:${conversationId}`).emit("message:new", payload?.message ?? payload);
  });

  // === Bakıcı Canlı Konum Events ===
  socket.on("sitter:location_update", async ({ bookingId, lat, lng }) => {
    if (!connectedUserId || !bookingId) return;
    try {
      const SitterBooking = (await import("./src/models/SitterBooking.js")).default;
      const booking = await SitterBooking.findById(bookingId).select("sitter user status");
      if (!booking) return;
      if (booking.sitter.toString() !== String(connectedUserId)) return; // sadece bakıcı emit edebilir
      if (!['accepted', 'active'].includes(booking.status)) return;
      // Pet sahibine konumu ilet
      io.to(`user:${booking.user}`).emit("sitter:location_update", {
        bookingId,
        lat,
        lng,
        updatedAt: Date.now(),
      });
    } catch (err) {
      console.error("[Socket] sitter:location_update error:", err.message);
    }
  });

  socket.on("sitter:walk_started", async ({ bookingId }) => {
    if (!connectedUserId || !bookingId) return;
    try {
      const SitterBooking = (await import("./src/models/SitterBooking.js")).default;
      const booking = await SitterBooking.findById(bookingId).select("sitter user status");
      if (!booking) return;
      if (booking.sitter.toString() !== String(connectedUserId)) return;
      // Durumu güncelle
      await SitterBooking.findByIdAndUpdate(bookingId, { status: 'active' });
      io.to(`user:${booking.user}`).emit("sitter:walk_started", { bookingId, startedAt: Date.now() });
    } catch (err) {
      console.error("[Socket] sitter:walk_started error:", err.message);
    }
  });

  socket.on("sitter:walk_ended", async ({ bookingId }) => {
    if (!connectedUserId || !bookingId) return;
    try {
      const SitterBooking = (await import("./src/models/SitterBooking.js")).default;
      const booking = await SitterBooking.findById(bookingId).select("sitter user status");
      if (!booking) return;
      if (booking.sitter.toString() !== String(connectedUserId)) return;
      io.to(`user:${booking.user}`).emit("sitter:walk_ended", { bookingId, endedAt: Date.now() });
    } catch (err) {
      console.error("[Socket] sitter:walk_ended error:", err.message);
    }
  });

  socket.on("disconnect", () => {
    console.log("Socket disconnected:", socket.id);

    if (connectedUserId) {
      const userIdStr = String(connectedUserId);
      const userSockets = userSocketMap.get(userIdStr);
      if (userSockets) {
        userSockets.delete(socket.id);
        if (userSockets.size === 0) {
          userSocketMap.delete(userIdStr);
          console.log(`User ${userIdStr} is now offline`);
        } else {
          console.log(`User ${userIdStr} still has ${userSockets.size} connection(s)`);
        }
      }
    }
  });
});
