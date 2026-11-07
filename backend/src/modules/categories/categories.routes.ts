import { Router } from 'express';
import { categoriesController } from './categories.controller.js';
import { authenticateJwt } from '../../common/middleware/auth.middleware.js';
import { validateRequest } from '../../common/middleware/validate-request.middleware.js';
import { createCategorySchema, updateCategorySchema } from './categories.validation.js';

const router = Router();

router.use(authenticateJwt);

router.get('/', categoriesController.getCategories);
router.post('/', validateRequest({ body: createCategorySchema }), categoriesController.createCategory);
router.patch('/:id', validateRequest({ body: updateCategorySchema }), categoriesController.updateCategory);

export const categoriesRoutes = router;

