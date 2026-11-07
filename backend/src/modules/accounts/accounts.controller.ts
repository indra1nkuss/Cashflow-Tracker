import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../common/middleware/auth.middleware.js';
import { accountsService } from './accounts.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';
import { UnauthorizedError } from '../../common/errors/app-error.js';

export class AccountsController {
  public async getAccounts(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const accounts = await accountsService.getAccountsWithBalance(req.user.userId);
      ApiResponse.success(res, accounts, 'Daftar akun berhasil diambil');
    } catch (error) {
      next(error);
    }
  }

  public async createAccount(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const account = await accountsService.createAccount(req.user.userId, req.body);
      ApiResponse.created(res, account, 'Akun berhasil dibuat');
    } catch (error) {
      next(error);
    }
  }

  public async getAccountById(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const account = await accountsService.getAccountById(req.user.userId, req.params.id as string);
      ApiResponse.success(res, account, 'Detail akun berhasil diambil');
    } catch (error) {
      next(error);
    }
  }

  public async updateAccount(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const account = await accountsService.updateAccount(req.user.userId, req.params.id as string, req.body);
      ApiResponse.success(res, account, 'Akun berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  }
}

export const accountsController = new AccountsController();

