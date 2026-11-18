import { Router } from 'express';
import { accountsController } from './accounts.controller.js';
import { authenticateJwt } from '../../common/middleware/auth.middleware.js';
import { validateRequest } from '../../common/middleware/validate-request.middleware.js';
import { createAccountSchema, updateAccountSchema } from './accounts.validation.js';

const router = Router();

router.use(authenticateJwt);

router.get('/', accountsController.getAccounts);
router.post('/', validateRequest({ body: createAccountSchema }), accountsController.createAccount);
router.get('/:id', accountsController.getAccountById);
router.patch('/:id', validateRequest({ body: updateAccountSchema }), accountsController.updateAccount);
router.delete('/:id', accountsController.deleteAccount);

export const accountsRoutes = router;

