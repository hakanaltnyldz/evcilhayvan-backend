import fs from "fs";
import path from "path";
import { randomBytes } from "crypto";
import { config } from "../config/config.js";

export class StorageService {
  // file: req.file from multer (disk storage)
  async save(file) {
    if (!file?.filename) throw new Error("File missing");
    return this.getPublicUrl(file.filename);
  }

  // buffer: Buffer, originalname: string — memory storage için
  async saveBuffer(buffer, originalname) {
    throw new Error("saveBuffer not implemented");
  }

  getPublicUrl(filename) {
    return `/uploads/${filename}`;
  }
}

export class LocalStorageService extends StorageService {
  constructor(uploadDir = config.uploadDir) {
    super();
    this.uploadDir = uploadDir || path.join(process.cwd(), "uploads");
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  async saveBuffer(buffer, originalname) {
    const ext = path.extname(originalname || "").toLowerCase() || ".bin";
    const filename = Date.now() + "-" + randomBytes(8).toString("hex") + ext;
    const dest = path.join(this.uploadDir, filename);
    await fs.promises.writeFile(dest, buffer);
    return this.getPublicUrl(filename);
  }
}

export const storageService = new LocalStorageService();
