import { Router } from 'express';
import { aiParserController } from './ai-parser.controller.js';
import { authenticateJwt } from '../../common/middleware/auth.middleware.js';
import { validateRequest } from '../../common/middleware/validate-request.middleware.js';
import { parseMessageSchema } from './ai-parser.validation.js';

const router = Router();

router.use(authenticateJwt);
router.post('/parse', validateRequest({ body: parseMessageSchema }), aiParserController.parse);

export const aiParserRoutes = router;

