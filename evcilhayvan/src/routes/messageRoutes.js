// src/routes/messageRoutes.js
import { Router } from "express";
import { body, param } from "express-validator";
import multer from "multer";
import path from "path";
import { authRequired } from "../middlewares/auth.js";
import { storageService } from "../services/storageService.js";
import {
  getMyConversations,
  getConversationById,
  getMessages,
  sendMessage,
  sendImageMessage,
  sendAudioMessage,
  markMessagesRead,
  createOrGetConversation,
  deleteConversation,
  deleteMessageForMe,
} from "../controllers/messageController.js";

const router = Router();

const _storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, storageService.uploadDir),
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, unique + path.extname(file.originalname || ""));
  },
});
const imageUpload = multer({
  storage: _storage,
  fileFilter: (_req, file, cb) => {
    if (file.mimetype?.startsWith("image/")) return cb(null, true);
    cb(new Error("Only images allowed"));
  },
  limits: { fileSize: 5 * 1024 * 1024 },
});

const audioUpload = multer({
  storage: _storage,
  fileFilter: (_req, file, cb) => {
    if (file.mimetype?.startsWith("audio/") || file.originalname?.endsWith('.m4a') || file.originalname?.endsWith('.aac')) {
      return cb(null, true);
    }
    cb(new Error("Only audio files allowed"));
  },
  limits: { fileSize: 10 * 1024 * 1024 },
});

router.use(authRequired());

router.get("/", getMyConversations);
router.get("/me", getMyConversations);

router.get(
  "/:conversationId/messages",
  [param("conversationId").isMongoId().withMessage("Gecersiz Sohbet ID")],
  getMessages
);

router.get(
  "/:conversationId",
  [param("conversationId").isMongoId().withMessage("Gecersiz Sohbet ID")],
  getConversationById
);

router.post(
  "/:conversationId/messages/image",
  [param("conversationId").isMongoId().withMessage("Gecersiz Sohbet ID")],
  imageUpload.single("image"),
  sendImageMessage
);

router.post(
  "/:conversationId/messages/audio",
  [param("conversationId").isMongoId().withMessage("Gecersiz Sohbet ID")],
  audioUpload.single("audio"),
  sendAudioMessage
);

router.post(
  "/:conversationId/messages",
  [
    param("conversationId").isMongoId().withMessage("Gecersiz Sohbet ID"),
    body("text").notEmpty().withMessage("Mesaj icerigi gerekli"),
  ],
  sendMessage
);

router.post(
  "/:conversationId",
  [
    param("conversationId").isMongoId().withMessage("Gecersiz Sohbet ID"),
    body("text").notEmpty().withMessage("Mesaj icerigi gerekli"),
  ],
  sendMessage
);

router.post(
  "/",
  [
    body("participantId").optional().isMongoId().withMessage("participantId gecersiz"),
    body("otherUserId").optional().isMongoId().withMessage("otherUserId gecersiz"),
    body("relatedPetId").optional().isMongoId().withMessage("relatedPetId gecersiz"),
    body("advertId").optional().isMongoId().withMessage("advertId gecersiz"),
  ],
  createOrGetConversation
);

router.delete(
  "/:conversationId",
  [param("conversationId").isMongoId().withMessage("Gecersiz Sohbet ID")],
  deleteConversation
);

router.patch(
  "/message/:messageId/for-me",
  [param("messageId").isMongoId().withMessage("Gecersiz Mesaj ID")],
  deleteMessageForMe
);

router.patch(
  "/:conversationId/read",
  [param("conversationId").isMongoId().withMessage("Gecersiz Sohbet ID")],
  markMessagesRead
);

export default router;
