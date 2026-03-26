import { Router } from "express";
import multer from "multer";
import path from "path";
import { authRequired } from "../middlewares/auth.js";
import { storageService } from "../services/storageService.js";
import { sendError, sendOk } from "../utils/apiResponse.js";

const router = Router();

const uploadDir = storageService.uploadDir;

// İzin verilen uzantılar (whitelist)
const ALLOWED_IMAGE_EXTS = new Set([".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif"]);
const ALLOWED_VIDEO_EXTS = new Set([".mp4", ".mov", ".avi", ".webm", ".mkv"]);

// Görüntü magic bytes (dosya başı imzası) — MIME spoofing koruması
const IMAGE_MAGIC = [
  [0xff, 0xd8, 0xff],                 // JPEG
  [0x89, 0x50, 0x4e, 0x47],           // PNG
  [0x47, 0x49, 0x46],                 // GIF
  [0x52, 0x49, 0x46, 0x46],           // WEBP (RIFF header)
];

function checkImageMagic(buffer) {
  return IMAGE_MAGIC.some((sig) =>
    sig.every((byte, i) => buffer[i] === byte)
  );
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const rawExt = path.extname(file.originalname || "").toLowerCase();
    // Uzantıyı whitelist ile sınırla; bilinmeyen uzantılara .bin ver
    const ext = ALLOWED_IMAGE_EXTS.has(rawExt) || ALLOWED_VIDEO_EXTS.has(rawExt) ? rawExt : ".bin";
    cb(null, unique + ext);
  },
});

// multer storage: magic bytes için memory'e al, sonra diske yaz
const memStorage = multer.memoryStorage();

const imageFilter = (_req, file, cb) => {
  const ext = path.extname(file.originalname || "").toLowerCase();
  if (!ALLOWED_IMAGE_EXTS.has(ext)) {
    return cb(new Error(`Desteklenmeyen dosya uzantısı: ${ext}`));
  }
  if (!file.mimetype?.startsWith("image/")) {
    return cb(new Error("Yalnızca resim yükleyebilirsiniz"));
  }
  cb(null, true);
};

const videoFilter = (_req, file, cb) => {
  const ext = path.extname(file.originalname || "").toLowerCase();
  if (!ALLOWED_VIDEO_EXTS.has(ext)) {
    return cb(new Error(`Desteklenmeyen video uzantısı: ${ext}`));
  }
  if (!file.mimetype?.startsWith("video/")) {
    return cb(new Error("Yalnızca video yükleyebilirsiniz"));
  }
  cb(null, true);
};

const uploadImage = multer({ storage: memStorage, fileFilter: imageFilter, limits: { fileSize: 10 * 1024 * 1024 } }); // 10MB
const uploadVideo = multer({ storage, fileFilter: videoFilter, limits: { fileSize: 100 * 1024 * 1024 } }); // 100MB

router.post("/images", authRequired(), uploadImage.single("file"), async (req, res) => {
  if (!req.file) {
    return sendError(res, 400, "Dosya gerekli", "file_required");
  }
  // Magic bytes kontrolü — MIME/uzantı sahteciliğini önle
  if (!checkImageMagic(req.file.buffer)) {
    return sendError(res, 400, "Geçersiz resim dosyası", "invalid_file");
  }
  try {
    const publicPath = await storageService.saveBuffer(req.file.buffer, req.file.originalname);
    return sendOk(res, 201, { url: publicPath, type: "image" });
  } catch (err) {
    console.error("[Upload] Error saving file:", err);
    return sendError(res, 500, "Dosya kaydedilemedi", "upload_error");
  }
});

router.post("/videos", authRequired(), uploadVideo.single("file"), async (req, res) => {
  if (!req.file) return sendError(res, 400, "Dosya gerekli", "file_required");
  const publicPath = await storageService.save(req.file);
  return sendOk(res, 201, { url: publicPath, type: "video" });
});

export default router;
