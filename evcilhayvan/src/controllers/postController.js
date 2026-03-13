import Post from "../models/Post.js";
import User from "../models/User.js";

// GET /api/posts?page=1&limit=20
export async function getFeed(req, res) {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const skip = (page - 1) * limit;

    const posts = await Post.find({ isActive: true })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Post.countDocuments({ isActive: true });

    return res.sendOk({
      posts,
      page,
      totalPages: Math.ceil(total / limit),
      total,
    });
  } catch (err) {
    return res.sendError(err.message, 500);
  }
}

// POST /api/posts
export async function createPost(req, res) {
  try {
    const userId = req.user._id || req.user.id;
    const user = await User.findById(userId).lean();
    if (!user) return res.sendError("Kullanici bulunamadi", 404);

    const { content, photos, petId, petName } = req.body;

    if (!content && (!photos || photos.length === 0)) {
      return res.sendError("Gonderi icerigi veya fotograf gerekli", 400);
    }

    const post = await Post.create({
      userId,
      userName: user.name,
      userAvatar: user.avatarUrl,
      content: content?.trim(),
      photos: photos || [],
      petId: petId || null,
      petName: petName || null,
    });

    return res.sendOk({ post }, 201);
  } catch (err) {
    return res.sendError(err.message, 500);
  }
}

// DELETE /api/posts/:id
export async function deletePost(req, res) {
  try {
    const userId = req.user._id || req.user.id;
    const post = await Post.findById(req.params.id);
    if (!post) return res.sendError("Gonderi bulunamadi", 404);
    if (String(post.userId) !== String(userId)) return res.sendError("Yetkisiz", 403);

    post.isActive = false;
    await post.save();

    return res.sendOk({ message: "Gonderi silindi" });
  } catch (err) {
    return res.sendError(err.message, 500);
  }
}

// POST /api/posts/:id/like
export async function toggleLike(req, res) {
  try {
    const userId = req.user._id || req.user.id;
    const post = await Post.findById(req.params.id);
    if (!post || !post.isActive) return res.sendError("Gonderi bulunamadi", 404);

    const alreadyLiked = post.likes.some((id) => String(id) === String(userId));

    if (alreadyLiked) {
      post.likes = post.likes.filter((id) => String(id) !== String(userId));
    } else {
      post.likes.push(userId);
    }

    await post.save();

    return res.sendOk({ liked: !alreadyLiked, likeCount: post.likes.length });
  } catch (err) {
    return res.sendError(err.message, 500);
  }
}

// POST /api/posts/:id/comment
export async function addComment(req, res) {
  try {
    const userId = req.user._id || req.user.id;
    const user = await User.findById(userId).lean();
    if (!user) return res.sendError("Kullanici bulunamadi", 404);

    const { text } = req.body;
    if (!text?.trim()) return res.sendError("Yorum metni gerekli", 400);

    const post = await Post.findById(req.params.id);
    if (!post || !post.isActive) return res.sendError("Gonderi bulunamadi", 404);

    const comment = {
      userId,
      userName: user.name,
      userAvatar: user.avatarUrl,
      text: text.trim(),
    };

    post.comments.push(comment);
    await post.save();

    return res.sendOk({ comment: post.comments[post.comments.length - 1] }, 201);
  } catch (err) {
    return res.sendError(err.message, 500);
  }
}

// POST /api/conversations/:convId/messages/:msgId/react
export async function reactToMessage(req, res) {
  try {
    const userId = String(req.user._id || req.user.id);
    const { emoji } = req.body;
    if (!emoji) return res.sendError("Emoji gerekli", 400);

    const Message = (await import("../models/Message.js")).default;
    const msg = await Message.findById(req.params.msgId);
    if (!msg) return res.sendError("Mesaj bulunamadi", 404);

    if (!msg.reactions) msg.reactions = new Map();

    const reactors = msg.reactions.get(emoji) || [];
    const alreadyReacted = reactors.some((id) => String(id) === userId);

    if (alreadyReacted) {
      msg.reactions.set(emoji, reactors.filter((id) => String(id) !== userId));
    } else {
      reactors.push(userId);
      msg.reactions.set(emoji, reactors);
    }

    await msg.save();

    // Broadcast to conversation participants
    const { io } = await import("../../server.js");
    io.to(`conversation:${msg.conversationId}`).emit("message:reaction", {
      messageId: String(msg._id),
      reactions: Object.fromEntries(msg.reactions),
    });

    return res.sendOk({ reactions: Object.fromEntries(msg.reactions) });
  } catch (err) {
    return res.sendError(err.message, 500);
  }
}
