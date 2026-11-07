import { Router } from 'express';
import { usersController } from './users.controller.js';
import { authenticateJwt } from '../../common/middleware/auth.middleware.js';

const router = Router();

router.use(authenticateJwt);
router.get('/me', usersController.getProfile);

export const usersRoutes = router;

