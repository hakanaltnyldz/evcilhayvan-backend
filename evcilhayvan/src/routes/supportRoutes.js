// src/routes/supportRoutes.js
import { Router } from 'express';
import { authRequired } from '../middlewares/auth.js';
import SupportTicket from '../models/SupportTicket.js';
import { sendOk, sendError } from '../utils/apiResponse.js';

const router = Router();
router.use(authRequired());

// POST /api/support/ticket
router.post('/ticket', async (req, res) => {
  try {
    const userId = req.user._id || req.user.id || req.user.sub;
    const { category, message } = req.body;

    const validCategories = ['app_bug', 'content_complaint', 'user_complaint', 'payment_issue', 'account_issue', 'other'];
    if (!category || !validCategories.includes(category)) {
      return sendError(res, 400, 'Geçerli bir kategori seçin.');
    }
    if (!message || message.trim().length < 10) {
      return sendError(res, 400, 'Mesaj en az 10 karakter olmalıdır.');
    }

    const ticket = await SupportTicket.create({
      userId,
      category,
      message: message.trim(),
    });

    return sendOk(res, 201, { ticket });
  } catch (err) {
    return sendError(res, 500, 'Şikayet gönderilemedi.', 'internal_error', err.message);
  }
});

// GET /api/support/my  — kullanıcının kendi ticketları
router.get('/my', async (req, res) => {
  try {
    const userId = req.user._id || req.user.id || req.user.sub;
    const tickets = await SupportTicket.find({ userId })
      .sort({ createdAt: -1 })
      .limit(20);
    return sendOk(res, 200, { tickets });
  } catch (err) {
    return sendError(res, 500, 'Şikayetler alınamadı.', 'internal_error', err.message);
  }
});

export default router;
