import { Router, Request, Response } from 'express';
import { authRoutes } from '../modules/auth/auth.routes.js';
import { usersRoutes } from '../modules/users/users.routes.js';
import { dashboardRoutes } from '../modules/dashboard/dashboard.routes.js';
import { transactionsRoutes } from '../modules/transactions/transactions.routes.js';
import { categoriesRoutes } from '../modules/categories/categories.routes.js';
import { accountsRoutes } from '../modules/accounts/accounts.routes.js';
import { reportsRoutes } from '../modules/reports/reports.routes.js';
import { telegramRoutes } from '../modules/telegram/telegram.routes.js';
import { aiParserRoutes } from '../modules/ai-parser/ai-parser.routes.js';

const router = Router();

// Health check endpoint
router.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'Personal Finance Tracker API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// Mounted module routes
router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/transactions', transactionsRoutes);
router.use('/categories', categoriesRoutes);
router.use('/accounts', accountsRoutes);
router.use('/reports', reportsRoutes);
router.use('/telegram', telegramRoutes);
router.use('/ai-parser', aiParserRoutes);

export const apiRouter = router;

