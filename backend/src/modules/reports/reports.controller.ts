import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../common/middleware/auth.middleware.js';
import { reportsService } from './reports.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';
import { UnauthorizedError } from '../../common/errors/app-error.js';

export class ReportsController {
  public async getMonthlyBreakdown(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const now = new Date();
      const year = req.query.year ? parseInt(req.query.year as string, 10) : now.getFullYear();
      const month = req.query.month ? parseInt(req.query.month as string, 10) : now.getMonth() + 1;

      const report = await reportsService.getMonthlyBreakdown(req.user.userId, year, month);
      ApiResponse.success(res, report, 'Monthly report retrieved successfully');
    } catch (error) {
      next(error);
    }
  }
}

export const reportsController = new ReportsController();

