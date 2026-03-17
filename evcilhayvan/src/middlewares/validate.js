import { validationResult } from "express-validator";
import { sendError } from "../utils/apiResponse.js";

/**
 * express-validator kontrolü yapan ortak middleware.
 * Route'larda [...validators], handleValidation, controllerFn sırasıyla kullanılır.
 */
export function handleValidation(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const messages = errors.array().map((e) => e.msg).join(", ");
    return sendError(res, 400, messages, "validation_error", errors.array());
  }
  next();
}
