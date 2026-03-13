import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  getFeed,
  createPost,
  deletePost,
  toggleLike,
  addComment,
  reactToMessage,
} from "../controllers/postController.js";

const router = Router();

// Social feed
router.get("/posts", getFeed);
router.post("/posts", authRequired, createPost);
router.delete("/posts/:id", authRequired, deletePost);
router.post("/posts/:id/like", authRequired, toggleLike);
router.post("/posts/:id/comment", authRequired, addComment);

// Message reactions (mounted at /api)
router.post(
  "/conversations/:convId/messages/:msgId/react",
  authRequired,
  reactToMessage
);

export default router;
