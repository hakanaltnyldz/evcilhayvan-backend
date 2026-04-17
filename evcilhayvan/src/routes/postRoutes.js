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

// Message reactions (mounted at /api)
router.post(
  "/conversations/:convId/messages/:msgId/react",
  authRequired(),
  reactToMessage
);

export default router;
