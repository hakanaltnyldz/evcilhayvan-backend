import Post from "../models/Post.js";
import User from "../models/User.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import { awardPoints } from "../utils/points.js";
import { sendPush } from "../utils/fcm.js";
import { io } from "../../server.js";

function normalizeHashtag(tag) {
  return String(tag ?? "")
    .trim()
    .replace(/^#+/, "")
    .replace(/[^\p{L}\p{N}_]/gu, "")
    .toLocaleLowerCase("tr-TR");
}

function extractHashtags(content) {
  if (!content) return [];
  const matches = String(content).match(/#[^\s#]+/g) ?? [];
  return [...new Set(matches.map((tag) => normalizeHashtag(tag)).filter(Boolean))];
}

function serializeReply(rawReply, serializedReply) {
  const reply = { ...serializedReply };
  if (
    rawReply?.userId &&
    typeof rawReply.userId === "object" &&
    rawReply.userId.name
  ) {
    reply.userName = rawReply.userId.name;
    reply.userAvatar = rawReply.userId.avatarUrl || null;
    reply.userId = String(rawReply.userId._id || rawReply.userId.id || reply.userId);
  } else if (reply.userId != null) {
    reply.userId = String(reply.userId);
  }
  return reply;
}

function serializeComment(rawComment, serializedComment) {
  const comment = { ...serializedComment };
  if (
    rawComment?.userId &&
    typeof rawComment.userId === "object" &&
    rawComment.userId.name
  ) {
    comment.userName = rawComment.userId.name;
    comment.userAvatar = rawComment.userId.avatarUrl || null;
    comment.userId = String(
      rawComment.userId._id || rawComment.userId.id || comment.userId
    );
  } else if (comment.userId != null) {
    comment.userId = String(comment.userId);
  }

  const rawReplies = Array.isArray(rawComment?.replies) ? rawComment.replies : [];
  const serializedReplies = Array.isArray(comment.replies) ? comment.replies : [];
  comment.replies = serializedReplies.map((reply, index) =>
    serializeReply(rawReplies[index], reply)
  );

  return comment;
}

function serializePost(post, viewerId) {
  const obj = post.toJSON();
  const likedUserIds = Array.isArray(post.likes)
    ? post.likes.map((id) => String(id))
    : [];
  const savedUserIds = Array.isArray(post.savedBy)
    ? post.savedBy.map((id) => String(id))
    : [];

  obj.likeCount = likedUserIds.length;
  obj.commentCount = Array.isArray(obj.comments) ? obj.comments.length : 0;
  obj.isLiked = viewerId ? likedUserIds.includes(String(viewerId)) : false;
  obj.isSaved = viewerId ? savedUserIds.includes(String(viewerId)) : false;
  obj.likes = likedUserIds;
  obj.hashtags = Array.isArray(obj.hashtags) ? obj.hashtags : [];
  delete obj.savedBy;

  if (post.userId && typeof post.userId === "object" && post.userId.name) {
    obj.userName = post.userId.name;
    obj.userAvatar = post.userId.avatarUrl || null;
    obj.userId = String(post.userId._id || post.userId.id || obj.userId);
  } else if (obj.userId != null) {
    obj.userId = String(obj.userId);
  }

  if (Array.isArray(obj.comments)) {
    obj.comments = obj.comments.map((comment, index) =>
      serializeComment(post.comments[index], comment)
    );
  }

  return obj;
}

async function emitUserEvent(userIds, event, payload) {
  const ids = [...new Set((Array.isArray(userIds) ? userIds : [userIds]).filter(Boolean).map(String))];
  if (!ids.length) return;
  try {
    const { io } = await import("../../server.js");
    ids.forEach((userId) => io.to(`user:${userId}`).emit(event, payload));
  } catch (error) {
    console.warn(`[${event}] socket emit skipped:`, error.message);
  }
}

async function notifyPostComment(post, commenter, comment) {
  const ownerId = String(post.userId);
  const commenterId = String(commenter._id);
  if (ownerId === commenterId) return;

  await sendPush(ownerId, {
    title: "Yeni yorum",
    body: `${commenter.name} gönderine yorum yaptı.`,
    data: { type: "post_comment", postId: String(post._id) },
  });

  await emitUserEvent(ownerId, "post:commented", {
    postId: String(post._id),
    comment,
    commenter: {
      id: commenterId,
      name: commenter.name,
      avatarUrl: commenter.avatarUrl || null,
    },
  });
}

async function notifyPostReply(post, parentComment, replier, reply) {
  const replierId = String(replier._id);
  const targets = new Set();
  const postOwnerId = String(post.userId);
  const commentOwnerId = String(parentComment.userId);

  if (postOwnerId !== replierId) targets.add(postOwnerId);
  if (commentOwnerId !== replierId) targets.add(commentOwnerId);

  if (!targets.size) return;

  await sendPush([...targets], {
    title: "Yeni yanıt",
    body: `${replier.name} bir yoruma yanıt verdi.`,
    data: {
      type: "post_reply",
      postId: String(post._id),
      commentId: String(parentComment._id),
    },
  });

  await emitUserEvent([...targets], "post:reply", {
    postId: String(post._id),
    commentId: String(parentComment._id),
    reply,
    replier: {
      id: replierId,
      name: replier.name,
      avatarUrl: replier.avatarUrl || null,
    },
  });
}

// GET /api/posts?page=1&limit=20&hashtag=kopek&mode=following
export async function getFeed(req, res) {
  try {
    const viewerId = req.user?.sub;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const skip = (page - 1) * limit;
    const hashtag = normalizeHashtag(req.query.hashtag);
    const mode = String(req.query.mode || "all").toLowerCase();

    const filter = { isActive: true };
    if (req.query.hashtag) {
      filter.hashtags = req.query.hashtag.toLowerCase();
    }

    // Takip edilenler modu
    if (req.query.mode === 'following' && req.user?.sub) {
      const currentUser = await User.findById(req.user.sub).select('following').lean();
      const followingIds = currentUser?.following || [];
      filter.userId = { $in: followingIds };
    }

    const rawPosts = await Post.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate("userId", "name avatarUrl")
      .populate("comments.userId", "name avatarUrl")
      .populate("comments.replies.userId", "name avatarUrl");

    // Populate'dan gelen güncel kullanıcı adı/avatarını stale denormalized alanlara yaz
    const posts = rawPosts.map(p => {
      const obj = p.toJSON();
      // likes/saves array yerine sadece count gönder (bant genişliği optimizasyonu)
      obj.likeCount = (p.likes || []).length;
      obj.saveCount = (p.saves || []).length;
      const requestUserId = req.user?.sub || req.user?._id;
      obj.isLiked = requestUserId ? (p.likes || []).some(id => String(id) === String(requestUserId)) : false;
      obj.isSaved = requestUserId ? (p.saves || []).some(id => String(id) === String(requestUserId)) : false;
      delete obj.likes;
      delete obj.saves;
      if (p.userId && typeof p.userId === 'object' && p.userId.name) {
        obj.userName = p.userId.name;
        obj.userAvatar = p.userId.avatarUrl || null;
      }
      if (Array.isArray(obj.comments)) {
        obj.comments = obj.comments.map((c, i) => {
          const rawComment = p.comments[i];
          if (rawComment?.userId && typeof rawComment.userId === 'object' && rawComment.userId.name) {
            c.userName = rawComment.userId.name;
            c.userAvatar = rawComment.userId.avatarUrl || null;
          }
          return c;
        });
      }
      return obj;
    });

    const total = await Post.countDocuments(filter);

    return sendOk(res, 200, {
      posts,
      page,
      totalPages: Math.ceil(total / limit),
      total,
    });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// GET /api/posts/hashtags/trending
export async function getTrendingHashtags(req, res) {
  try {
    const hashtags = await Post.aggregate([
      {
        $match: {
          isActive: true,
          hashtags: { $exists: true, $ne: [] },
        },
      },
      { $unwind: "$hashtags" },
      {
        $group: {
          _id: "$hashtags",
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1, _id: 1 } },
      { $limit: 30 },
      {
        $project: {
          _id: 0,
          tag: "$_id",
          count: 1,
        },
      },
    ]);

    return sendOk(res, 200, { hashtags });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// GET /api/posts/saved
export async function getSavedPosts(req, res) {
  try {
    const userId = req.user.sub;
    const posts = await Post.find({ isActive: true, savedBy: userId })
      .sort({ createdAt: -1 })
      .populate("userId", "name avatarUrl")
      .populate("comments.userId", "name avatarUrl")
      .populate("comments.replies.userId", "name avatarUrl");

    return sendOk(res, 200, {
      posts: posts.map((post) => serializePost(post, userId)),
    });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// POST /api/posts
export async function createPost(req, res) {
  try {
    const userId = req.user.sub;
    const user = await User.findById(userId).lean();
    if (!user) return sendError(res, 404, "Kullanici bulunamadi", "not_found");

    const { content, photos, petId, petName, hashtags } = req.body;
    const trimmedContent = content?.trim() || "";

    if (!trimmedContent && (!photos || photos.length === 0)) {
      return sendError(
        res,
        400,
        "Gonderi icerigi veya fotograf gerekli",
        "validation_error"
      );
    }

    // Otomatik hashtag çıkarma (içerikten #kelime)
    const extractedTags = trimmedContent
      ? [...trimmedContent.matchAll(/#(\w+)/g)].map(m => m[1].toLowerCase())
      : [];
    const allHashtags = [...new Set([...(hashtags || []), ...extractedTags])];

    const post = await Post.create({
      userId,
      userName: user.name,
      userAvatar: user.avatarUrl,
      content: trimmedContent,
      photos: photos || [],
      petId: petId || null,
      petName: petName || null,
      hashtags: allHashtags,
    });

    awardPoints(userId, 5).catch(() => {});
    return sendOk(res, 201, { post });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// PUT /api/posts/:id
export async function updatePost(req, res) {
  try {
    const userId = req.user.sub;
    const post = await Post.findById(req.params.id);
    if (!post || !post.isActive) {
      return sendError(res, 404, "Gonderi bulunamadi", "not_found");
    }
    if (String(post.userId) !== String(userId)) {
      return sendError(res, 403, "Yetkisiz", "forbidden");
    }

    const { content, photos } = req.body;
    if (content !== undefined) {
      post.content = content?.trim();
      post.hashtags = extractHashtags(post.content);
    }
    if (photos !== undefined) post.photos = photos;
    await post.save();

    return sendOk(res, 200, { post });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// DELETE /api/posts/:id
export async function deletePost(req, res) {
  try {
    const userId = req.user.sub;
    const post = await Post.findById(req.params.id);
    if (!post) return sendError(res, 404, "Gonderi bulunamadi", "not_found");
    if (String(post.userId) !== String(userId)) {
      return sendError(res, 403, "Yetkisiz", "forbidden");
    }

    post.isActive = false;
    await post.save();

    return sendOk(res, 200, { message: "Gonderi silindi" });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// POST /api/posts/:id/like
export async function toggleLike(req, res) {
  try {
    const userId = req.user.sub;
    const post = await Post.findById(req.params.id);
    if (!post || !post.isActive) {
      return sendError(res, 404, "Gonderi bulunamadi", "not_found");
    }

    const alreadyLiked = post.likes.some((id) => String(id) === String(userId));
    const updated = await Post.findOneAndUpdate(
      { _id: post._id },
      alreadyLiked
        ? { $pull: { likes: userId } }
        : { $addToSet: { likes: userId } },
      { new: true }
    );

    return sendOk(res, 200, {
      liked: !alreadyLiked,
      likeCount: updated.likes.length,
    });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// POST /api/posts/:id/save
export async function toggleSavePost(req, res) {
  try {
    const userId = req.user.sub;
    const post = await Post.findById(req.params.id);
    if (!post || !post.isActive) {
      return sendError(res, 404, "Gonderi bulunamadi", "not_found");
    }

    const alreadySaved = post.savedBy.some((id) => String(id) === String(userId));
    const updated = await Post.findOneAndUpdate(
      { _id: post._id },
      alreadySaved
        ? { $pull: { savedBy: userId } }
        : { $addToSet: { savedBy: userId } },
      { new: true }
    );

    return sendOk(res, 200, {
      saved: !alreadySaved,
      saveCount: updated.savedBy.length,
    });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// POST /api/posts/:id/comment
export async function addComment(req, res) {
  try {
    const userId = req.user.sub;
    const user = await User.findById(userId).lean();
    if (!user) return sendError(res, 404, "Kullanici bulunamadi", "not_found");

    const { text } = req.body;
    if (!text?.trim()) {
      return sendError(res, 400, "Yorum metni gerekli", "validation_error");
    }

    const post = await Post.findById(req.params.id);
    if (!post || !post.isActive) {
      return sendError(res, 404, "Gonderi bulunamadi", "not_found");
    }

    const comment = {
      userId,
      userName: user.name,
      userAvatar: user.avatarUrl,
      text: text.trim(),
      replies: [],
    };

    post.comments.push(comment);
    await post.save();

    const savedComment = post.comments[post.comments.length - 1];

    // Bildirim: yorum sahibi ≠ gönderi sahibi
    if (String(post.userId) !== String(userId)) {
      sendPush([String(post.userId)], {
        title: `${user.name} yorum yaptı`,
        body: text.trim().substring(0, 80),
        data: { type: "post_comment", postId: String(post._id) },
      }).catch(() => {});
      if (io?.to) {
        io.to(`user:${String(post.userId)}`).emit("post:commented", {
          postId: String(post._id),
          comment: savedComment,
        });
      }
    }

    return sendOk(res, 201, { comment: savedComment });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}

// POST /api/conversations/:convId/messages/:msgId/react
export async function reactToMessage(req, res) {
  try {
    const userId = String(req.user.sub);
    const { emoji } = req.body;
    if (!emoji) return sendError(res, 400, "Emoji gerekli", "validation_error");

    const Message = (await import("../models/Message.js")).default;
    const msg = await Message.findById(req.params.msgId);
    if (!msg) return sendError(res, 404, "Mesaj bulunamadi", "not_found");

    if (!msg.reactions) msg.reactions = new Map();

    const reactors = msg.reactions.get(emoji) || [];
    const alreadyReacted = reactors.some((id) => String(id) === userId);

    if (alreadyReacted) {
      msg.reactions.set(
        emoji,
        reactors.filter((id) => String(id) !== userId)
      );
    } else {
      reactors.push(userId);
      msg.reactions.set(emoji, reactors);
    }

    await msg.save();

    const { io } = await import("../../server.js");
    io.to(`conversation:${msg.conversationId}`).emit("message:reaction", {
      messageId: String(msg._id),
      reactions: Object.fromEntries(msg.reactions),
    });

    return sendOk(res, 200, { reactions: Object.fromEntries(msg.reactions) });
  } catch (err) {
    return sendError(res, 500, err.message, "internal_error");
  }
}
