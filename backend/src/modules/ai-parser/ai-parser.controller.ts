import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../common/middleware/auth.middleware.js';
import { aiParserService } from './ai-parser.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';

export class AiParserController {
  public async parse(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { message } = req.body;
      const parsed = await aiParserService.parseTransactionMessage(message, req.user?.userId);
      ApiResponse.success(res, parsed, 'Pesan berhasil dianalisis oleh AI parser');
    } catch (error) {
      next(error);
    }
  }
}

export const aiParserController = new AiParserController();

