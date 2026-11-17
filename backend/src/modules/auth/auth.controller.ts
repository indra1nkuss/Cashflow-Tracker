import { Request, Response, NextFunction } from 'express';
import { authService } from './auth.service.js';
import { ApiResponse } from '../../common/utils/api-response.js';

export class AuthController {
  public async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.register(req.body);
      ApiResponse.created(res, result, 'Registrasi berhasil');
    } catch (error) {
      next(error);
    }
  }

  public async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.login(req.body);
      ApiResponse.success(res, result, 'Login berhasil');
    } catch (error) {
      next(error);
    }
  }

  public async forgotPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email } = req.body as { email: string };
      const result = await authService.forgotPassword(email);
      ApiResponse.success(res, result, 'Permintaan reset password dikirim');
    } catch (error) {
      next(error);
    }
  }

  public async resetPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, otp, newPassword } = req.body as { email: string; otp: string; newPassword: string };
      await authService.resetPassword(email, otp, newPassword);
      ApiResponse.success(res, null, 'Password berhasil diubah. Silakan login dengan password baru Anda.');
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();

