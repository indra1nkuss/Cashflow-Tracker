import { Router } from 'express';
import { authController } from './auth.controller.js';
import { validateRequest } from '../../common/middleware/validate-request.middleware.js';
import { registerSchema, loginSchema } from './auth.validation.js';
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

export const authRoutes = router;

