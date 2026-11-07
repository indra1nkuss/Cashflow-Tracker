import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../common/middleware/auth.middleware.js';
import { categoriesService } from './categories.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';
import { UnauthorizedError } from '../../common/errors/app-error.js';

export class CategoriesController {
  public async getCategories(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const type = req.query.type as 'INCOME' | 'EXPENSE' | undefined;
      const categories = await categoriesService.getCategories(req.user.userId, type);
      ApiResponse.success(res, categories, 'Daftar kategori berhasil diambil');
    } catch (error) {
      next(error);
    }
  }

  public async createCategory(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const category = await categoriesService.createCategory(req.user.userId, req.body);
      ApiResponse.created(res, category, 'Kategori berhasil dibuat');
    } catch (error) {
      next(error);
    }
  }

  public async updateCategory(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const category = await categoriesService.updateCategory(
        req.user.userId,
        req.params.id as string,
        req.body
      );
      ApiResponse.success(res, category, 'Kategori berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  }
}

export const categoriesController = new CategoriesController();

