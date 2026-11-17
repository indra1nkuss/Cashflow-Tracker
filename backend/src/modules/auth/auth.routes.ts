import { Router } from 'express';
import { authController } from './auth.controller.js';
import { validateRequest } from '../../common/middleware/validate-request.middleware.js';
import { registerSchema, loginSchema, forgotPasswordSchema, resetPasswordSchema } from './auth.validation.js';
import { authRateLimiter } from '../../common/middleware/rate-limiter.middleware.js';

const router = Router();

router.post(
  '/register',
  authRateLimiter,
  validateRequest({ body: registerSchema }),
  authController.register
);

router.post(
  '/login',
  authRateLimiter,
  validateRequest({ body: loginSchema }),
  authController.login
);

router.post(
  '/forgot-password',
  authRateLimiter,
  validateRequest({ body: forgotPasswordSchema }),
  authController.forgotPassword
);

router.post(
  '/reset-password',
  authRateLimiter,
  validateRequest({ body: resetPasswordSchema }),
  authController.resetPassword
);

export const authRoutes = router;

