import path from "path";
import mongoose from "mongoose";
import request from "supertest";
import { MongoMemoryServer } from "mongodb-memory-server";
import { jest } from "@jest/globals";

jest.setTimeout(120000);

let app;
let mongo;
let User;
let Pet;
let Veterinary;
let VetReview;
let PetSitter;
let Product;
let CartItem;
let Coupon;
let SupportTicket;
let VetClaimRequest;
let issueTokens;

const PASSWORD = "password123";
const tinyPngBuffer = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7Z7J0AAAAASUVORK5CYII=",
  "base64"
);

const authHeader = (token) => ({ Authorization: `Bearer ${token}` });
const uniqueEmail = (prefix) => `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}@test.com`;

async function createVerifiedUser({
  name = "Test User",
  email = uniqueEmail("user"),
  role = "user",
  isSeller = false,
} = {}) {
  await request(app)
    .post("/api/auth/register")
    .send({ name, email, password: PASSWORD })
    .expect(201);

  const verifyDoc = await User.findOne({ email }).select("+verificationToken");
  const verifyRes = await request(app)
    .post("/api/auth/verify-email")
    .send({ email, code: verifyDoc.verificationToken })
    .expect(200);

  let user = await User.findOne({ email });
  if (role !== "user" || isSeller) {
    user.role = role;
    user.isSeller = isSeller;
    await user.save();
    const tokens = await issueTokens(user);
    return { user, token: tokens.accessToken, refreshToken: tokens.refreshToken, email };
  }

  return {
    user,
    token: verifyRes.body.token,
    refreshToken: verifyRes.body.refreshToken,
    email,
  };
}

describe("Critical regression coverage", () => {
  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    process.env.MONGO_URI = mongo.getUri();
    process.env.JWT_SECRET = "test-secret";
    process.env.UPLOAD_DIR = path.join(process.cwd(), "uploads-test");
    process.env.NODE_ENV = "test";

    ({ app } = await import("../server.js"));
    ({ default: User } = await import("../src/models/User.js"));
    ({ default: Pet } = await import("../src/models/Pet.js"));
    ({ default: Veterinary } = await import("../src/models/Veterinary.js"));
    ({ default: VetReview } = await import("../src/models/VetReview.js"));
    ({ default: PetSitter } = await import("../src/models/PetSitter.js"));
    ({ default: Product } = await import("../src/models/Product.js"));
    ({ default: CartItem } = await import("../src/models/CartItem.js"));
    ({ default: Coupon } = await import("../src/models/Coupon.js"));
    ({ default: SupportTicket } = await import("../src/models/SupportTicket.js"));
    ({ default: VetClaimRequest } = await import("../src/models/VetClaimRequest.js"));
    ({ issueTokens } = await import("../src/utils/tokens.js"));

    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
    await mongoose.connect(process.env.MONGO_URI);
  });

  afterAll(async () => {
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.dropDatabase();
      await mongoose.connection.close();
    }
    if (mongo) {
      await mongo.stop();
    }
  });

  it("rate limits repeated failed email verification attempts", async () => {
    const email = uniqueEmail("verify");

    await request(app)
      .post("/api/auth/register")
      .send({ name: "Verify User", email, password: PASSWORD })
      .expect(201);

    for (let attempt = 0; attempt < 8; attempt += 1) {
      await request(app)
        .post("/api/auth/verify-email")
        .send({ email, code: "000000" })
        .expect(400);
    }

    const blockedRes = await request(app)
      .post("/api/auth/verify-email")
      .send({ email, code: "000000" })
      .expect(429);

    expect(blockedRes.body.code).toBe("too_many_verification_attempts");
  });

  it("ignores privileged fields when creating pets", async () => {
    const owner = await createVerifiedUser({ name: "Pet Owner" });

    const petRes = await request(app)
      .post("/api/pets")
      .set(authHeader(owner.token))
      .send({
        name: "Luna",
        species: "dog",
        advertType: "adoption",
        ownerId: new mongoose.Types.ObjectId().toString(),
        isActive: false,
      })
      .expect(201);

    const savedPet = await Pet.findById(petRes.body.pet.id);
    expect(String(savedPet.ownerId)).toBe(String(owner.user._id));
    expect(savedPet.isActive).toBe(true);
  });

  it("enforces vet review ownership using the authenticated subject", async () => {
    const reviewer = await createVerifiedUser({ name: "Reviewer" });
    const otherUser = await createVerifiedUser({ name: "Other Reviewer" });
    const vet = await Veterinary.create({ name: `Clinic ${Date.now()}` });

    await request(app)
      .post(`/api/veterinaries/${vet._id}/reviews`)
      .set(authHeader(reviewer.token))
      .send({ rating: 5, comment: "Harika" })
      .expect(201);

    const review = await VetReview.findOne({ vet: vet._id, user: reviewer.user._id });
    expect(review).toBeTruthy();

    await request(app)
      .delete(`/api/veterinaries/reviews/${review._id}`)
      .set(authHeader(otherUser.token))
      .expect(403);

    await request(app)
      .delete(`/api/veterinaries/reviews/${review._id}`)
      .set(authHeader(reviewer.token))
      .expect(200);
  });

  it("validates coupon requests and recalculates discounts from the authenticated cart", async () => {
    const customer = await createVerifiedUser({ name: "Coupon Customer" });
    const seller = await createVerifiedUser({ name: "Coupon Seller", role: "seller", isSeller: true });

    const product = await Product.create({
      name: "Mama",
      price: 100,
      stock: 10,
      seller: seller.user._id,
    });

    await CartItem.create({
      user: customer.user._id,
      product: product._id,
      quantity: 1,
      variantKey: "default",
    });

    const coupon = await Coupon.create({
      code: `SAVE${Date.now()}`,
      discountType: "percentage",
      discountValue: 10,
      minPurchaseAmount: 0,
      validFrom: new Date(Date.now() - 60_000),
      validUntil: new Date(Date.now() + 60_000),
      perUserLimit: 1,
    });

    await request(app)
      .post("/api/coupons/validate")
      .set(authHeader(customer.token))
      .send({ code: coupon.code, cartTotal: 0 })
      .expect(400);

    const validateRes = await request(app)
      .post("/api/coupons/validate")
      .set(authHeader(customer.token))
      .send({ code: coupon.code, cartTotal: 100 })
      .expect(200);

    expect(validateRes.body.valid).toBe(true);
    expect(validateRes.body.discountAmount).toBe(10);
    expect(validateRes.body.finalAmount).toBe(90);
  });

  it("validates sitter booking create/update, walk update, and care report flows", async () => {
    const owner = await createVerifiedUser({ name: "Booking Owner" });
    const sitterUser = await createVerifiedUser({ name: "Booking Sitter" });

    const pet = await Pet.create({
      ownerId: owner.user._id,
      name: "Buddy",
      species: "dog",
      advertType: "adoption",
      isActive: true,
    });

    const sitter = await PetSitter.create({
      userId: sitterUser.user._id,
      displayName: "Walker",
      availability: true,
      services: [{ type: "walking", pricePerHour: 25, pricePerDay: 0 }],
    });

    const startDate = new Date(Date.now() + 60 * 60 * 1000).toISOString();
    const endDate = new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString();

    await request(app)
      .post("/api/sitter-bookings")
      .set(authHeader(owner.token))
      .send({
        sitterId: "invalid-id",
        petId: pet._id.toString(),
        serviceType: "walking",
        startDate,
        endDate,
      })
      .expect(400);

    const bookingRes = await request(app)
      .post("/api/sitter-bookings")
      .set(authHeader(owner.token))
      .send({
        sitterId: sitter._id.toString(),
        petId: pet._id.toString(),
        serviceType: "walking",
        startDate,
        endDate,
        notes: "Aksamustu yuruyusu",
      })
      .expect(201);

    const bookingId = bookingRes.body.booking.id || bookingRes.body.booking._id;

    await request(app)
      .post(`/api/sitter-bookings/${bookingId}/updates`)
      .set(authHeader(sitterUser.token))
      .send({ type: "bad_type" })
      .expect(400);

    await request(app)
      .post(`/api/sitter-bookings/${bookingId}/care-reports`)
      .set(authHeader(sitterUser.token))
      .send({ mood: "angry" })
      .expect(400);

    await request(app)
      .patch(`/api/sitter-bookings/${bookingId}/status`)
      .set(authHeader(owner.token))
      .send({ status: "accepted" })
      .expect(403);

    await request(app)
      .patch(`/api/sitter-bookings/${bookingId}/status`)
      .set(authHeader(sitterUser.token))
      .send({ status: "accepted" })
      .expect(200);

    await request(app)
      .patch(`/api/sitter-bookings/${bookingId}/status`)
      .set(authHeader(owner.token))
      .send({ status: "completed" })
      .expect(400);

    await request(app)
      .patch(`/api/sitter-bookings/${bookingId}/status`)
      .set(authHeader(sitterUser.token))
      .send({ status: "active" })
      .expect(200);

    const trackingOffRes = await request(app)
      .patch(`/api/sitter-bookings/${bookingId}/tracking`)
      .set(authHeader(sitterUser.token))
      .send({ active: false, reason: "location_service_disabled" })
      .expect(200);

    expect(trackingOffRes.body.liveTracking.isActive).toBe(false);
    expect(trackingOffRes.body.liveTracking.graceEndsAt).toBeTruthy();
    expect(trackingOffRes.body.earnings.status).toBe("paused");
    expect(trackingOffRes.body.earnings.payableAmount).toBeLessThanOrEqual(
      bookingRes.body.booking.totalPrice
    );

    await request(app)
      .post(`/api/sitter-bookings/${bookingId}/updates`)
      .set(authHeader(sitterUser.token))
      .send({
        type: "location",
        coordinates: [32.8597, 39.9334],
      })
      .expect(201);

    const trackingOnRes = await request(app)
      .patch(`/api/sitter-bookings/${bookingId}/tracking`)
      .set(authHeader(sitterUser.token))
      .send({ active: true })
      .expect(200);

    expect(trackingOnRes.body.liveTracking.isActive).toBe(true);
    expect(trackingOnRes.body.earnings.status).toBe("earning");

    await request(app)
      .patch(`/api/sitter-bookings/${bookingId}/status`)
      .set(authHeader(sitterUser.token))
      .send({ status: "completed" })
      .expect(200);
  });

  it("accepts legacy mobile upload aliases for single-image uploads", async () => {
    const member = await createVerifiedUser({ name: "Uploader" });

    for (const endpoint of ["/api/uploads/image", "/api/uploads/single"]) {
      const response = await request(app)
        .post(endpoint)
        .set(authHeader(member.token))
        .attach("file", tinyPngBuffer, "tiny.png")
        .expect(201);

      expect(response.body.url).toMatch(/^\/uploads\//);
      expect(response.body.type).toBe("image");
    }
  });

  it("guards admin stats, support updates, vet claim review, and audit actions", async () => {
    const admin = await createVerifiedUser({ name: "Platform Admin", role: "admin" });
    const member = await createVerifiedUser({ name: "Support Member" });

    await request(app)
      .get("/api/admin/stats?from=2026-15-40")
      .set(authHeader(admin.token))
      .expect(400);

    await request(app)
      .get("/api/admin/support?page=0")
      .set(authHeader(admin.token))
      .expect(400);

    const supportTicket = await SupportTicket.create({
      userId: member.user._id,
      category: "account_issue",
      message: "Destek gerekiyor",
    });

    await request(app)
      .patch(`/api/admin/support/${supportTicket._id}`)
      .set(authHeader(admin.token))
      .send({ status: "reviewing", adminNote: { bad: true } })
      .expect(400);

    const supportRes = await request(app)
      .patch(`/api/admin/support/${supportTicket._id}`)
      .set(authHeader(admin.token))
      .send({ status: "reviewing", adminNote: "  kontrol edildi  " })
      .expect(200);

    expect(supportRes.body.ticket.adminNote).toBe("kontrol edildi");

    const vet = await Veterinary.create({ name: `Audit Vet ${Date.now()}` });
    const claim = await VetClaimRequest.create({
      vetId: vet._id,
      userId: member.user._id,
      fullName: "Dr. Test",
      phone: "5551234567",
      role: "veteriner",
      note: "Belge bekleniyor",
    });

    await request(app)
      .patch(`/api/admin/vet-claims/${claim._id}/review`)
      .set(authHeader(admin.token))
      .send({ action: "rejected" })
      .expect(400);

    const claimRes = await request(app)
      .patch(`/api/admin/vet-claims/${claim._id}/review`)
      .set(authHeader(admin.token))
      .send({ action: "rejected", adminNote: "Eksik belge" })
      .expect(200);

    expect(claimRes.body.claim.status).toBe("rejected");
    expect(claimRes.body.claim.adminNote).toBe("Eksik belge");

    const auditRes = await request(app)
      .get("/api/admin/audit-logs")
      .set(authHeader(admin.token))
      .expect(200);

    expect(auditRes.body.actions).toEqual(
      expect.arrayContaining(["admin.vet_claim.review"])
    );
  });
});
