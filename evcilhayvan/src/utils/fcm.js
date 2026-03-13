// src/utils/fcm.js
// Firebase Cloud Messaging helper
// Requires: firebase-admin installed + FIREBASE_SERVICE_ACCOUNT env var pointing to serviceAccount.json

import User from "../models/User.js";

let _admin = null;
let _messaging = null;

function getMessaging() {
  if (_messaging) return _messaging;

  try {
    // Dynamic import to avoid crash if firebase-admin not installed
    const admin = _admin;
    if (!admin) return null;
    _messaging = admin.messaging();
    return _messaging;
  } catch {
    return null;
  }
}

export function initFcm(adminInstance) {
  _admin = adminInstance;
}

/**
 * Send push notification to one or more users by userId
 * @param {string|string[]} userIds
 * @param {{ title: string, body: string, data?: Record<string, string> }} payload
 */
export async function sendPush(userIds, { title, body, data = {} }) {
  const messaging = getMessaging();
  if (!messaging) {
    console.log("[FCM] Skipped (firebase-admin not initialized):", title);
    return;
  }

  const ids = Array.isArray(userIds) ? userIds : [userIds];
  if (!ids.length) return;

  // Fetch FCM tokens from DB
  const users = await User.find({ _id: { $in: ids } }).select("fcmTokens");
  const tokens = users.flatMap((u) => u.fcmTokens ?? []).filter(Boolean);
  if (!tokens.length) return;

  // Send multicast (max 500 tokens per call)
  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  const stringData = {};
  for (const [k, v] of Object.entries(data)) {
    stringData[k] = String(v);
  }

  for (const chunk of chunks) {
    try {
      const response = await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data: stringData,
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default", badge: 1 } } },
      });
      // Remove invalid tokens
      const toRemove = [];
      response.responses.forEach((r, idx) => {
        if (!r.success && r.error?.code === "messaging/registration-token-not-registered") {
          toRemove.push(chunk[idx]);
        }
      });
      if (toRemove.length) {
        await User.updateMany({ fcmTokens: { $in: toRemove } }, { $pullAll: { fcmTokens: toRemove } });
      }
    } catch (err) {
      console.error("[FCM] Send error:", err.message);
    }
  }
}
