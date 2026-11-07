import { prisma } from '../../config/database.js';
import { CreateCategoryInput, UpdateCategoryInput } from './categories.validation.js';
import { NotFoundError } from '../../common/errors/app-error.js';

export class CategoriesService {
  public async getCategories(userId: string, type?: 'INCOME' | 'EXPENSE') {
    return prisma.category.findMany({
      where: {
        OR: [{ userId }, { userId: null, isDefault: true }],
        ...(type ? { type } : {}),
      },
      orderBy: { name: 'asc' },
    });
  }

  public async createCategory(userId: string, input: CreateCategoryInput) {
    return prisma.category.create({
      data: {
        userId,
        name: input.name,
        type: input.type,
        icon: input.icon,
        color: input.color,
      },
    });
  }

  public async updateCategory(userId: string, categoryId: string, input: UpdateCategoryInput) {
    const existing = await prisma.category.findFirst({
      where: { id: categoryId, userId },
    });

    if (!existing) {
      throw new NotFoundError('Kategori tidak ditemukan atau Anda tidak memiliki akses');
    }

    return prisma.category.update({
      where: { id: categoryId },
      data: input,
    });
  }
}

export const categoriesService = new CategoriesService();

