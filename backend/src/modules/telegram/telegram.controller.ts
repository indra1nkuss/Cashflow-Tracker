import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../common/middleware/auth.middleware.js';
import { telegramService } from './telegram.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';
import { UnauthorizedError } from '../../common/errors/app-error.js';
import { Logger } from '../../common/utils/logger.js';

export class TelegramController {
  public async handleWebhook(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // Respond to Telegram immediately (standard webhook practice)
      res.status(200).json({ ok: true });

      // Process update asynchronously in the background
      telegramService.handleWebhookUpdate(req.body).catch((err) => {
        Logger.error('Error handling Telegram webhook update:', err);
      });
    } catch (error) {
      next(error);
    }
  }

  public async getLinkStatus(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const status = await telegramService.getLinkStatus(req.user.userId);
      ApiResponse.success(res, status, 'Telegram link status retrieved');
    } catch (error) {
      next(error);
    }
  }
}

export const telegramController = new TelegramController();

