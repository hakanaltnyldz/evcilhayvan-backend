// models/User.js
import mongoose from "mongoose";
import { randomInt } from "crypto";

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 80 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true },
    role: { type: String, enum: ["user", "admin", "seller", "vet", "banned"], default: "user" },
    city: { type: String, trim: true },
    about: { type: String, trim: true, maxlength: 500 },
    avatarUrl: { type: String, trim: true },
    fcmTokens: { type: [String], default: [], select: false },
    isVerified: { type: Boolean, default: false },
    verificationToken: { type: String, select: false },
    verificationTokenExpires: { type: Date, select: false },
    passwordResetToken: { type: String, select: false },
    passwordResetExpires: { type: Date, select: false },
    phone:      { type: String, trim: true },
    nationalId: { type: String, select: false },   // AES-256-CBC şifreli TC
    isSeller: { type: Boolean, default: false },
    blockedUsers: { type: [mongoose.Schema.Types.ObjectId], ref: "User", default: [], select: false },
    refreshToken: { type: String, select: false },
    refreshTokenExpires: { type: Date, select: false },
    notificationPreferences: {
      messages:        { type: Boolean, default: true },
      matches:         { type: Boolean, default: true },
      adoptions:       { type: Boolean, default: true },
      vaccinations:    { type: Boolean, default: true },
      orderUpdates:    { type: Boolean, default: true },
      sitterBookings:  { type: Boolean, default: true },
      lostFoundNearby: { type: Boolean, default: true },
      events:          { type: Boolean, default: true },
      birthdays:       { type: Boolean, default: true },
    },
    points: { type: Number, default: 0 },
    badges: { type: [String], default: [] },
    following: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    followers: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        delete ret.password;
        delete ret.refreshToken;
        delete ret.refreshTokenExpires;
        delete ret.verificationToken;
        delete ret.verificationTokenExpires;
        delete ret.passwordResetToken;
        delete ret.passwordResetExpires;
        return ret;
      },
    },
  }
);

UserSchema.methods.createVerificationToken = function () {
  const code = randomInt(100000, 1000000).toString();
  this.verificationToken = code;
  this.verificationTokenExpires = Date.now() + 10 * 60 * 1000;
  return code;
};

UserSchema.methods.createPasswordResetToken = function () {
  const code = randomInt(100000, 1000000).toString();
  this.passwordResetToken = code;
  this.passwordResetExpires = Date.now() + 10 * 60 * 1000;
  return code;
};

export default mongoose.model("User", UserSchema);
