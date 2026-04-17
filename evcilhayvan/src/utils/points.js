import User from "../models/User.js";

const BADGE_THRESHOLDS = [
  { min: 10, badge: "newcomer" },
  { min: 50, badge: "active" },
  { min: 100, badge: "veteran" },
  { min: 200, badge: "champion" },
];

export async function awardPoints(userId, amount) {
  if (!userId || !Number.isFinite(amount) || amount <= 0) return null;

  const user = await User.findByIdAndUpdate(
    userId,
    { $inc: { points: amount } },
    { new: true }
  );

  if (!user) return null;

  const earnedBadges = BADGE_THRESHOLDS
    .filter((threshold) => user.points >= threshold.min)
    .map((threshold) => threshold.badge);

  if (earnedBadges.length > 0) {
    await User.findByIdAndUpdate(userId, {
      $addToSet: { badges: { $each: earnedBadges } },
    });
    user.badges = Array.from(
      new Set([...(user.badges || []), ...earnedBadges])
    );
  }

  return user;
}
