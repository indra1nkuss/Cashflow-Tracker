import { Router } from 'express';
import { dashboardController } from './dashboard.controller.js';
import { authenticateJwt } from '../../common/middleware/auth.middleware.js';

const router = Router();

router.use(authenticateJwt);
router.get('/summary', dashboardController.getSummary);

export const dashboardRoutes = router;

