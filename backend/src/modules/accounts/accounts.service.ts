import { Decimal } from '@prisma/client/runtime/library';
import { prisma } from '../../config/database.js';
import { CreateAccountInput, UpdateAccountInput } from './accounts.validation.js';
import { NotFoundError } from '../../common/errors/app-error.js';

export class AccountsService {
  /**
   * Retrieves all accounts for a user with calculated current balances.
   * Saldo dihitung dari: initialBalance + SUM(INCOME) - SUM(EXPENSE)
   */
  public async getAccountsWithBalance(userId: string) {
    const accounts = await prisma.account.findMany({
      where: { userId, isArchived: false },
      orderBy: { createdAt: 'asc' },
    });

    const accountsWithBalance = await Promise.all(
      accounts.map(async (account) => {
        const incomeAggregate = await prisma.transaction.aggregate({
          where: { accountId: account.id, type: 'INCOME' },
          _sum: { amount: true },
        });

        const expenseAggregate = await prisma.transaction.aggregate({
          where: { accountId: account.id, type: 'EXPENSE' },
          _sum: { amount: true },
        });

        const totalIncome = Number(incomeAggregate._sum.amount ?? 0);
        const totalExpense = Number(expenseAggregate._sum.amount ?? 0);
        const initial = Number(account.initialBalance);
        const currentBalance = initial + totalIncome - totalExpense;

        return {
          ...account,
          initialBalance: initial,
          totalIncome,
          totalExpense,
          currentBalance,
        };
      })
    );

    return accountsWithBalance;
  }

  public async createAccount(userId: string, input: CreateAccountInput) {
    const account = await prisma.account.create({
      data: {
        userId,
        name: input.name,
        accountType: input.accountType,
        initialBalance: new Decimal(input.initialBalance),
        currency: input.currency,
      },
    });

    return {
      ...account,
      initialBalance: Number(account.initialBalance),
      currentBalance: Number(account.initialBalance),
    };
  }

  public async getAccountById(userId: string, accountId: string) {
    const account = await prisma.account.findFirst({
      where: { id: accountId, userId },
    });

    if (!account) {
      throw new NotFoundError('Akun tidak ditemukan');
    }

    const incomeAggregate = await prisma.transaction.aggregate({
      where: { accountId: account.id, type: 'INCOME' },
      _sum: { amount: true },
    });

    const expenseAggregate = await prisma.transaction.aggregate({
      where: { accountId: account.id, type: 'EXPENSE' },
      _sum: { amount: true },
    });

    const totalIncome = Number(incomeAggregate._sum.amount ?? 0);
    const totalExpense = Number(expenseAggregate._sum.amount ?? 0);
    const initial = Number(account.initialBalance);

    return {
      ...account,
      initialBalance: initial,
      currentBalance: initial + totalIncome - totalExpense,
    };
  }

  public async updateAccount(userId: string, accountId: string, input: UpdateAccountInput) {
    const existing = await prisma.account.findFirst({
      where: { id: accountId, userId },
    });

    if (!existing) {
      throw new NotFoundError('Akun tidak ditemukan');
    }

    const updated = await prisma.account.update({
      where: { id: accountId },
      data: input,
    });

    return updated;
  }

  public async deleteAccount(userId: string, accountId: string) {
    const existing = await prisma.account.findFirst({
      where: { id: accountId, userId },
    });

    if (!existing) {
      throw new NotFoundError('Akun tidak ditemukan');
    }

    // Soft delete: arsipkan akun agar riwayat transaksi tetap terjaga
    const archived = await prisma.account.update({
      where: { id: accountId },
      data: { isArchived: true },
    });

    return archived;
  }
}

export const accountsService = new AccountsService();

