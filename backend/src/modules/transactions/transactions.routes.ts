import { Router } from 'express';
import { transactionsController } from './transactions.controller.js';
import { authenticateJwt } from '../../common/middleware/auth.middleware.js';
import { validateRequest } from '../../common/middleware/validate-request.middleware.js';
import { createTransactionSchema, transactionQuerySchema } from './transactions.validation.js';

const router = Router();

router.use(authenticateJwt);

router.get('/', validateRequest({ query: transactionQuerySchema }), transactionsController.getTransactions);
router.post('/', validateRequest({ body: createTransactionSchema }), transactionsController.createTransaction);
router.get('/:id', transactionsController.getTransactionById);
router.delete('/:id', transactionsController.deleteTransaction);

export const transactionsRoutes = router;

