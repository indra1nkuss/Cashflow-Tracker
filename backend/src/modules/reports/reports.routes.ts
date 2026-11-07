import { Router } from 'express';
import { reportsController } from './reports.controller.js';
import { authenticateJwt } from '../../common/middleware/auth.middleware.js';

const router = Router();

router.use(authenticateJwt);
router.get('/monthly', reportsController.getMonthlyBreakdown);

export const reportsRoutes = router;

