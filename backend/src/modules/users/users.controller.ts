import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../common/middleware/auth.middleware.js';
import { usersService } from './users.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';
import { UnauthorizedError } from '../../common/errors/app-error.js';

export class UsersController {
  public async getProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new UnauthorizedError();
      }
      const profile = await usersService.getProfile(req.user.userId);
      ApiResponse.success(res, profile, 'User profile retrieved successfully');
    } catch (error) {
      next(error);
    }
  }
}

export const usersController = new UsersController();

