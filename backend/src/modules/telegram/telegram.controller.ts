import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../common/middleware/auth.middleware.js';
import { telegramService } from './telegram.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';
import { UnauthorizedError } from '../../common/errors/app-error.js';
import { Logger } from '../../common/utils/logger.js';

export class TelegramController {
  public async handleWebhook(req: Request, res: Response, _next?: NextFunction): Promise<void> {
    try {
      // Must await processing in serverless environment (Vercel) before sending response!
      await telegramService.handleWebhookUpdate(req.body);
      res.status(200).json({ ok: true });
    } catch (error) {
      Logger.error('Error handling Telegram webhook update:', error);
      // Return 200 to Telegram so it does not retry repeatedly on errors
      res.status(200).json({ ok: true });
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

  public async generateLinkCode(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const result = telegramService.generateLinkCode(req.user.userId);
      ApiResponse.success(res, result, 'Link code generated successfully');
    } catch (error) {
      next(error);
    }
  }

  public async unlink(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      await telegramService.unlink(req.user.userId);
      ApiResponse.success(res, { success: true }, 'Telegram account unlinked');
    } catch (error) {
      next(error);
    }
  }
}

export const telegramController = new TelegramController();
