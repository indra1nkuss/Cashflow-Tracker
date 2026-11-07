import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../common/middleware/auth.middleware.js';
import { transactionsService } from './transactions.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';
import { UnauthorizedError } from '../../common/errors/app-error.js';
import { TransactionQueryInput } from './transactions.validation.js';

export class TransactionsController {
  public async getTransactions(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const result = await transactionsService.getTransactions(
        req.user.userId,
        req.query as unknown as TransactionQueryInput
      );
      ApiResponse.success(res, result.items, 'Transaksi berhasil diambil', 200, {
        total: result.total,
        limit: result.limit,
        offset: result.offset,
      });
    } catch (error) {
      next(error);
    }
  }

  public async createTransaction(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const transaction = await transactionsService.createTransaction(req.user.userId, req.body);
      ApiResponse.created(res, transaction, 'Transaksi berhasil disimpan');
    } catch (error) {
      next(error);
    }
  }

  public async getTransactionById(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const transaction = await transactionsService.getTransactionById(
        req.user.userId,
        req.params.id as string
      );
      ApiResponse.success(res, transaction, 'Detail transaksi berhasil diambil');
    } catch (error) {
      next(error);
    }
  }

  public async deleteTransaction(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      await transactionsService.deleteTransaction(req.user.userId, req.params.id as string);
      ApiResponse.success(res, null, 'Transaksi berhasil dihapus');
    } catch (error) {
      next(error);
    }
  }
}

export const transactionsController = new TransactionsController();

