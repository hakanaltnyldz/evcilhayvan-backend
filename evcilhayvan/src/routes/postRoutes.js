import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  getFeed,
  getTrendingHashtags,
  getSavedPosts,
  createPost,
  updatePost,
  deletePost,
  toggleLike,
  toggleSavePost,
  addComment,
  replyToComment,
  reactToMessage,
} from "../controllers/postController.js";
import Post from "../models/Post.js";
import { sendOk, sendError } from "../utils/apiResponse.js";

const router = Router();

// Social feed
router.get("/posts", authRequired(), getFeed);
router.get("/posts/hashtags/trending", authRequired(), getTrendingHashtags);
router.get("/posts/saved", authRequired(), getSavedPosts);
router.post("/posts", authRequired(), createPost);
router.put("/posts/:id", authRequired(), updatePost);
router.delete("/posts/:id", authRequired(), deletePost);
router.post("/posts/:id/like", authRequired(), toggleLike);
router.post("/posts/:id/save", authRequired(), toggleSavePost);
router.post("/posts/:id/comment", authRequired(), addComment);
router.post(
  "/posts/:id/comments/:commentId/reply",
  authRequired(),
  replyToComment
);

// POST /api/posts/:id/comments/:commentId/reply — yoruma yanıt ver
router.post("/posts/:id/comments/:commentId/reply", authRequired, async (req, res) => {
  try {
    const userId = req.user.sub || req.user._id || req.user.id;
    const { text } = req.body;
    if (!text?.trim()) return sendError(res, 400, "Yanıt metni gerekli", "validation_error");

    const post = await Post.findById(req.params.id);
    if (!post || !post.isActive) return sendError(res, 404, "Gönderi bulunamadı", "not_found");

    const comment = post.comments.id(req.params.commentId);
    if (!comment) return sendError(res, 404, "Yorum bulunamadı", "not_found");

    const user = await (await import("../models/User.js")).default.findById(userId).lean();
    if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "not_found");

    const reply = { userId, userName: user.name, userAvatar: user.avatarUrl, text: text.trim() };
    comment.replies.push(reply);
    await post.save();

    const savedReply = comment.replies[comment.replies.length - 1];

    // Bildirim: gönderi sahibi
    const { sendPush } = await import("../utils/fcm.js");
    const { io } = await import("../../server.js");
    const notifyUsers = new Set();
    if (String(post.userId) !== String(userId)) notifyUsers.add(String(post.userId));
    if (String(comment.userId) !== String(userId)) notifyUsers.add(String(comment.userId));
    for (const uid of notifyUsers) {
      sendPush([uid], {
        title: `${user.name} yanıt verdi`,
        body: text.trim().substring(0, 80),
        data: { type: "post_reply", postId: String(post._id) },
      }).catch(() => {});
      if (io?.to) io.to(`user:${uid}`).emit("post:reply", { postId: String(post._id), reply: savedReply });
    }

    return sendOk(res, 201, { reply: savedReply });
  } catch (err) {
    return sendError(res, 500, "Yanıt gönderilemedi", "internal_error", err.message);
  }
});

// GET /api/posts/hashtags/trending — trend hashtagler
router.get("/posts/hashtags/trending", async (req, res) => {
  try {
    const hashtags = await Post.aggregate([
      { $match: { isActive: true, hashtags: { $exists: true, $ne: [] } } },
      { $unwind: "$hashtags" },
      { $group: { _id: "$hashtags", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 30 },
      { $project: { _id: 0, tag: "$_id", count: 1 } },
    ]);
    return sendOk(res, 200, { hashtags });
  } catch (err) {
    return sendError(res, 500, "Trendler alınamadı", "internal_error", err.message);
  }
});

// GET /api/posts/saved — kaydedilen gönderiler
router.get("/posts/saved", authRequired, async (req, res) => {
  try {
    const userId = req.user.sub || req.user._id || req.user.id;
    const posts = await Post.find({ saves: userId, isActive: true })
      .sort({ createdAt: -1 })
      .limit(50);
    return sendOk(res, 200, { posts });
  } catch (err) {
    return sendError(res, 500, "Kaydedilen gönderiler alınamadı", "internal_error", err.message);
  }
});

// POST /api/posts/:id/save — kaydet/çıkar (toggle)
router.post("/posts/:id/save", authRequired, async (req, res) => {
  try {
    const userId = req.user.sub || req.user._id || req.user.id;
    const post = await Post.findById(req.params.id);
    if (!post) return sendError(res, 404, "Gönderi bulunamadı", "not_found");

    const isSaved = post.saves.some((id) => String(id) === String(userId));
    if (isSaved) {
      post.saves.pull(userId);
      post.saveCount = Math.max(0, (post.saveCount || 0) - 1);
    } else {
      post.saves.addToSet(userId);
      post.saveCount = (post.saveCount || 0) + 1;
    }
    await post.save();
    return sendOk(res, 200, { saved: !isSaved, saveCount: post.saveCount });
  } catch (err) {
    return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
  }
});

// Message reactions (mounted at /api)
router.post(
  "/conversations/:convId/messages/:msgId/react",
  authRequired(),
  reactToMessage
);

export default router;
