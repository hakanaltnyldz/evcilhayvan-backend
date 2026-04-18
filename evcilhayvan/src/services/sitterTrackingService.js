import SitterBooking from "../models/SitterBooking.js";
import { sendPush } from "../utils/fcm.js";

export const TRACKING_GRACE_MS = 60_000;

const trackingGraceTimers = new Map();

function roundMoney(value) {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
}

function plannedDurationMs(booking) {
  const start = new Date(booking.startDate).getTime();
  const end = new Date(booking.endDate).getTime();
  const diff = end - start;
  return Number.isFinite(diff) && diff > 0 ? diff : TRACKING_GRACE_MS;
}

export function computePayableAmount(booking, { now = new Date() } = {}) {
  const totalPrice = Number(booking.totalPrice ?? 0);
  if (totalPrice <= 0) return 0;

  const totalPausedMs = Number(booking.earnings?.totalPausedMs ?? 0);
  const currentPauseMs =
    booking.earnings?.status === "paused" && booking.earnings?.pausedAt
      ? Math.max(0, now.getTime() - new Date(booking.earnings.pausedAt).getTime())
      : 0;

  const durationMs = plannedDurationMs(booking);
  const pausedMs = Math.min(durationMs, totalPausedMs + currentPauseMs);
  const activeRatio = Math.max(0, 1 - pausedMs / durationMs);
  return roundMoney(totalPrice * activeRatio);
}

function ensureTrackingState(booking) {
  if (!booking.liveTracking) booking.liveTracking = {};
  if (!booking.earnings) {
    booking.earnings = {
      status: "pending",
      totalPausedMs: 0,
      payableAmount: Number(booking.totalPrice ?? 0),
    };
  }
  if (!booking.serviceFlow) booking.serviceFlow = {};
}

export function markServiceStarted(booking, { now = new Date() } = {}) {
  ensureTrackingState(booking);
  booking.status = "active";
  booking.serviceFlow.startedAt = booking.serviceFlow.startedAt || now;
  booking.serviceFlow.pickedUpAt = booking.serviceFlow.pickedUpAt || now;
  booking.liveTracking.required = true;
  booking.liveTracking.isActive = true;
  booking.liveTracking.interruptedAt = undefined;
  booking.liveTracking.graceEndsAt = undefined;
  booking.liveTracking.offlineNotifiedAt = undefined;
  booking.earnings.status = "earning";
  booking.earnings.pausedAt = undefined;
  booking.earnings.pauseReason = undefined;
  booking.earnings.totalPausedMs = Number(booking.earnings.totalPausedMs ?? 0);
  booking.earnings.payableAmount = computePayableAmount(booking, { now });
}

export function markTrackingOnline(
  booking,
  { now = new Date(), lat, lng } = {},
) {
  ensureTrackingState(booking);

  if (
    booking.earnings.status === "paused" &&
    booking.earnings.pausedAt
  ) {
    booking.earnings.totalPausedMs =
      Number(booking.earnings.totalPausedMs ?? 0) +
      Math.max(0, now.getTime() - new Date(booking.earnings.pausedAt).getTime());
  }

  booking.liveTracking.required = true;
  booking.liveTracking.isActive = true;
  booking.liveTracking.lastUpdated = now;
  booking.liveTracking.interruptedAt = undefined;
  booking.liveTracking.graceEndsAt = undefined;
  booking.liveTracking.offlineNotifiedAt = undefined;
  if (lat !== undefined) booking.liveTracking.lastLat = lat;
  if (lng !== undefined) booking.liveTracking.lastLng = lng;

  if (booking.status === "active") {
    booking.earnings.status = "earning";
  }
  booking.earnings.pausedAt = undefined;
  booking.earnings.pauseReason = undefined;
  booking.earnings.payableAmount = computePayableAmount(booking, { now });
}

export function markTrackingOffline(
  booking,
  { now = new Date(), reason = "tracking_offline" } = {},
) {
  ensureTrackingState(booking);

  booking.liveTracking.isActive = false;
  booking.liveTracking.interruptedAt = now;
  booking.liveTracking.graceEndsAt = new Date(now.getTime() + TRACKING_GRACE_MS);

  if (booking.status === "active" && booking.earnings.status === "earning") {
    booking.earnings.status = "paused";
    booking.earnings.pausedAt = now;
    booking.earnings.pauseReason = reason;
  }

  booking.earnings.payableAmount = computePayableAmount(booking, { now });
}

export function markServiceCompleted(booking, { now = new Date() } = {}) {
  ensureTrackingState(booking);

  if (
    booking.earnings.status === "paused" &&
    booking.earnings.pausedAt
  ) {
    booking.earnings.totalPausedMs =
      Number(booking.earnings.totalPausedMs ?? 0) +
      Math.max(0, now.getTime() - new Date(booking.earnings.pausedAt).getTime());
  }

  booking.status = "completed";
  booking.completedAt = now;
  booking.serviceFlow.completedAt = now;
  booking.liveTracking.isActive = false;
  booking.liveTracking.required = false;
  booking.liveTracking.interruptedAt = undefined;
  booking.liveTracking.graceEndsAt = undefined;
  booking.earnings.status = "completed";
  booking.earnings.pausedAt = undefined;
  booking.earnings.pauseReason = undefined;
  booking.earnings.payableAmount = computePayableAmount(booking, { now });
}

export function cancelTrackingGrace(bookingId) {
  const key = String(bookingId);
  const timer = trackingGraceTimers.get(key);
  if (timer) {
    clearTimeout(timer);
    trackingGraceTimers.delete(key);
  }
}

function offlinePayload(booking) {
  return {
    bookingId: booking._id.toString(),
    lastLat: booking.liveTracking?.lastLat ?? null,
    lastLng: booking.liveTracking?.lastLng ?? null,
    lastUpdated: booking.liveTracking?.lastUpdated ?? null,
    payoutPaused: true,
    message:
      "Bakicinin konumu 1 dakikadir alinamiyor. Son gorulen konum gosteriliyor ve odeme duraklatildi.",
  };
}

export function scheduleTrackingGrace({ io, bookingId }) {
  cancelTrackingGrace(bookingId);

  const timer = setTimeout(async () => {
    try {
      const booking = await SitterBooking.findById(bookingId).select(
        "petOwnerId status liveTracking earnings totalPrice startDate endDate",
      );

      if (!booking) return;
      if (booking.status !== "active") return;
      if (booking.liveTracking?.isActive === true) return;

      booking.liveTracking = booking.liveTracking || {};
      booking.liveTracking.offlineNotifiedAt = new Date();
      booking.earnings = booking.earnings || {};
      booking.earnings.payableAmount = computePayableAmount(booking);
      await booking.save();

      const payload = offlinePayload(booking);
      io.to(`user:${booking.petOwnerId}`).emit("sitter:location_offline", payload);

      sendPush([String(booking.petOwnerId)], {
        title: "Bakici konumu durdu",
        body: "1 dakikadir konum gelmiyor. Son gorulen konum gosteriliyor ve odeme duraklatildi.",
        data: {
          type: "sitter_location_offline",
          bookingId: booking._id.toString(),
          lastLat: payload.lastLat ?? "",
          lastLng: payload.lastLng ?? "",
          lastUpdated: payload.lastUpdated ?? "",
          payoutPaused: "true",
        },
      }).catch(() => {});
    } catch (err) {
      console.error("[Tracking] grace notification error:", err.message);
    } finally {
      trackingGraceTimers.delete(String(bookingId));
    }
  }, TRACKING_GRACE_MS);

  trackingGraceTimers.set(String(bookingId), timer);
}
