import { Router } from 'express';
import { authController } from './auth.controller.js';
import { validateRequest } from '../../common/middleware/validate-request.middleware.js';
import { registerSchema, loginSchema } from './auth.validation.js';

const router = Router();

router.post(
  '/register',
  validateRequest({ body: registerSchema }),
  authController.register
);

router.post(
  '/login',
  validateRequest({ body: loginSchema }),
  authController.login
);

export const authRoutes = router;

