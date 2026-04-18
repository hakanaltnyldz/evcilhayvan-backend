import AuditLog from "../models/AuditLog.js";
import { sendError, sendOk } from "../utils/apiResponse.js";

export async function listAuditLogs(req, res) {
  try {
    const { limit = 50, page = 1, action } = req.query;
    const pageNumber = Number(page);
    const pageSize = Number(limit);
    if (!Number.isInteger(pageNumber) || pageNumber < 1 || pageNumber > 1000) {
      return sendError(res, 400, "page 1 ile 1000 arasinda olmali", "validation_error");
    }
    if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 200) {
      return sendError(res, 400, "limit 1 ile 200 arasinda olmali", "validation_error");
    }
    const skip = (pageNumber - 1) * pageSize;
    const filter = {};
    if (action) filter.action = action;

    const [logs, total, actions] = await Promise.all([
      AuditLog.find(filter).sort({ createdAt: -1 }).skip(skip).limit(pageSize),
      AuditLog.countDocuments(filter),
      AuditLog.distinct("action", {}),
    ]);

    return sendOk(res, 200, {
      logs,
      total,
      page: pageNumber,
      hasMore: skip + logs.length < total,
      actions: actions.filter(Boolean).sort(),
    });
  } catch (err) {
    return sendError(res, 500, "Audit logları alınamadı", "internal_error", err.message);
  }
}
