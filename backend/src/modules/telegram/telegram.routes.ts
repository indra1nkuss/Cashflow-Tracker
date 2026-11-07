import { Router } from 'express';
import { telegramController } from './telegram.controller.js';
import { authenticateJwt } from '../../common/middleware/auth.middleware.js';

const router = Router();

// Telegram Webhook endpoint (public, called by Telegram servers)
router.post('/webhook', telegramController.handleWebhook);

// Authenticated endpoints for mobile app
router.get('/link-status', authenticateJwt, telegramController.getLinkStatus);

export const telegramRoutes = router;

