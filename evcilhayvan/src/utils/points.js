import User from "../models/User.js";

const BADGE_THRESHOLDS = [
  { min: 10,  badge: "newcomer" },
  { min: 50,  badge: "active" },
  { min: 100, badge: "veteran" },
  { min: 200, badge: "champion" },
];

/**
 * Award points to a user and automatically assign badges if thresholds are reached.
 * @param {string|import('mongoose').Types.ObjectId} userId
 * @param {number} amount
 */
export async function awardPoints(userId, amount) {
  try {
    const user = await User.findByIdAndUpdate(
      userId,
      { $inc: { points: amount } },
      { new: true, select: "points badges" }
    );
    if (!user) return;

    const newBadges = BADGE_THRESHOLDS
      .filter(t => user.points >= t.min && !user.badges.includes(t.badge))
      .map(t => t.badge);

    if (newBadges.length > 0) {
      await User.findByIdAndUpdate(userId, { $addToSet: { badges: { $each: newBadges } } });
    }
  } catch {
    // Points are non-critical; never throw
  }
}
