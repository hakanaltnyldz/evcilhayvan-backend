import User from "../models/User.js";
import UserReport from "../models/UserReport.js";

// POST /api/users/block/:userId
export const blockUser = async (req, res) => {
  try {
    const targetId = req.params.userId;
    const myId = req.user.id;

    if (String(targetId) === String(myId)) {
      return res.sendError("Kendinizi engelleyemezsiniz.", 400);
    }

    const target = await User.findById(targetId).select("_id name");
    if (!target) return res.sendError("Kullanıcı bulunamadı.", 404);

    await User.findByIdAndUpdate(myId, {
      $addToSet: { blockedUsers: targetId },
    });

    res.sendOk({ message: `${target.name} engellendi.` });
  } catch (err) {
    res.sendError(err.message);
  }
};

// DELETE /api/users/block/:userId
export const unblockUser = async (req, res) => {
  try {
    const targetId = req.params.userId;
    const myId = req.user.id;

    await User.findByIdAndUpdate(myId, {
      $pull: { blockedUsers: targetId },
    });

    res.sendOk({ message: "Engel kaldırıldı." });
  } catch (err) {
    res.sendError(err.message);
  }
};

// GET /api/users/blocked
export const getBlockedUsers = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select("blockedUsers")
      .populate("blockedUsers", "name avatarUrl");

    res.sendOk({ blockedUsers: user?.blockedUsers ?? [] });
  } catch (err) {
    res.sendError(err.message);
  }
};

// GET /api/users/is-blocked/:userId
export const isBlocked = async (req, res) => {
  try {
    const targetId = req.params.userId;
    const user = await User.findById(req.user.id).select("blockedUsers");
    const blocked = user?.blockedUsers?.some((id) => String(id) === String(targetId)) ?? false;
    res.sendOk({ blocked });
  } catch (err) {
    res.sendError(err.message);
  }
};

// POST /api/users/report/:userId
export const reportUser = async (req, res) => {
  try {
    const reportedId = req.params.userId;
    const reporterId = req.user.id;
    const { reason, description } = req.body;

    if (String(reportedId) === String(reporterId)) {
      return res.sendError("Kendinizi şikayet edemezsiniz.", 400);
    }

    const target = await User.findById(reportedId).select("_id name");
    if (!target) return res.sendError("Kullanıcı bulunamadı.", 404);

    const validReasons = ["spam", "harassment", "inappropriate_content", "fake_profile", "other"];
    if (!reason || !validReasons.includes(reason)) {
      return res.sendError("Geçerli bir şikayet nedeni seçiniz.", 400);
    }

    // Upsert: same reporter+reported can only have 1 report (update reason if re-reporting)
    await UserReport.findOneAndUpdate(
      { reporterId, reportedId },
      { reason, description: description?.trim() || "", status: "pending" },
      { upsert: true, new: true }
    );

    res.sendOk({ message: "Şikayetiniz alındı, incelenecektir." });
  } catch (err) {
    res.sendError(err.message);
  }
};

// GET /api/admin/reports (admin only)
export const getReports = async (req, res) => {
  try {
    if (req.user.role !== "admin") return res.sendError("Yetki yok.", 403);
    const { status = "pending" } = req.query;
    const reports = await UserReport.find({ status })
      .populate("reporterId", "name email")
      .populate("reportedId", "name email")
      .sort({ createdAt: -1 })
      .limit(100);
    res.sendOk({ reports });
  } catch (err) {
    res.sendError(err.message);
  }
};
