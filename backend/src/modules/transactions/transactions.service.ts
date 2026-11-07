import { Decimal } from '@prisma/client/runtime/library';
import { prisma } from '../../config/database.js';
import { CreateTransactionInput, TransactionQueryInput } from './transactions.validation.js';
import { NotFoundError } from '../../common/errors/app-error.js';

export class TransactionsService {
  public async getTransactions(userId: string, query: TransactionQueryInput) {
    const whereClause: Record<string, unknown> = { userId };

    if (query.type) whereClause.type = query.type;
    if (query.accountId) whereClause.accountId = query.accountId;
    if (query.categoryId) whereClause.categoryId = query.categoryId;

    if (query.startDate || query.endDate) {
      whereClause.transactionDate = {
        ...(query.startDate ? { gte: new Date(query.startDate) } : {}),
        ...(query.endDate ? { lte: new Date(query.endDate) } : {}),
      };
    }

    const [total, transactions] = await Promise.all([
      prisma.transaction.count({ where: whereClause }),
      prisma.transaction.findMany({
        where: whereClause,
        include: {
          account: { select: { id: true, name: true, accountType: true } },
          category: { select: { id: true, name: true, icon: true, color: true } },
        },
        orderBy: { transactionDate: 'desc' },
        take: query.limit,
        skip: query.offset,
      }),
    ]);

    return {
      total,
      limit: query.limit,
      offset: query.offset,
      items: transactions.map((t) => ({
        ...t,
        amount: Number(t.amount),
      })),
    };
  }

  public async createTransaction(userId: string, input: CreateTransactionInput) {
    // Verify account ownership
    const account = await prisma.account.findFirst({
      where: { id: input.accountId, userId },
    });
    if (!account) {
      throw new NotFoundError('Akun transaksi tidak ditemukan');
    }

    // Verify category exists
    const category = await prisma.category.findFirst({
      where: {
        id: input.categoryId,
        OR: [{ userId }, { isDefault: true }],
      },
    });
    if (!category) {
      throw new NotFoundError('Kategori transaksi tidak ditemukan');
    }

    const transaction = await prisma.transaction.create({
      data: {
        userId,
        accountId: input.accountId,
        categoryId: input.categoryId,
        type: input.type,
        amount: new Decimal(input.amount),
        description: input.description,
        transactionDate: new Date(input.transactionDate),
        notes: input.notes,
        source: input.source,
      },
      include: {
        account: { select: { id: true, name: true } },
        category: { select: { id: true, name: true, icon: true } },
      },
    });

    return {
      ...transaction,
      amount: Number(transaction.amount),
    };
  }

  public async getTransactionById(userId: string, transactionId: string) {
    const transaction = await prisma.transaction.findFirst({
      where: { id: transactionId, userId },
      include: {
        account: true,
        category: true,
      },
    });

    if (!transaction) {
      throw new NotFoundError('Transaksi tidak ditemukan');
    }

    return {
      ...transaction,
      amount: Number(transaction.amount),
    };
  }

  public async deleteTransaction(userId: string, transactionId: string) {
    const transaction = await prisma.transaction.findFirst({
      where: { id: transactionId, userId },
    });

    if (!transaction) {
      throw new NotFoundError('Transaksi tidak ditemukan');
    }

    await prisma.transaction.delete({
      where: { id: transactionId },
    });

    return { success: true };
  }
}

export const transactionsService = new TransactionsService();

