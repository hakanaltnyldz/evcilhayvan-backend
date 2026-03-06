export function buildError(message, code = "unknown_error", details = undefined) {
  return { message, code, details };
}

export function sendError(res, statusCode, message, code = "unknown_error", details = undefined) {
  return res.status(statusCode).json(buildError(message, code, details));
}

export function sendOk(res, statusCode = 200, payload = {}) {
  return res.status(statusCode).json({ success: true, ok: true, ...payload });
}

export function attachResponseHelpers(_req, res, next) {
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.sendOk = (payload = {}, statusCode = 200) => sendOk(res, statusCode, payload);
  res.sendError = (statusCode, message, code = "unknown_error", details = undefined) =>
    sendError(res, statusCode, message, code, details);
  next();
}

export function errorHandler(err, _req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  console.error("[ErrorHandler] Caught error:", err.message, err.stack);

  // Multer hataları
  if (err.name === "MulterError") {
    console.error("[ErrorHandler] Multer error:", err.code, err.field);
    return res.status(400).json(buildError(
      err.code === "LIMIT_FILE_SIZE" ? "Dosya boyutu çok büyük" : "Dosya yüklenirken hata oluştu",
      err.code || "multer_error",
      { field: err.field }
    ));
  }

  // Custom multer filter error
  if (err.message?.includes("Only image uploads")) {
    return res.status(400).json(buildError("Sadece resim dosyaları kabul edilmektedir", "invalid_file_type"));
  }

  const statusCode = err.statusCode || err.status || 500;
  const code = err.code || "internal_error";
  const details = err.details || err.data || undefined;
  const message = err.message || "Internal server error";

  return res.status(statusCode).json(buildError(message, code, details));
}
