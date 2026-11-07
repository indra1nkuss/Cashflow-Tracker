import { prisma } from '../../config/database.js';
import { accountsService } from '../accounts/accounts.service.js';

export class DashboardService {
  public async getSummary(userId: string) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);

    // Get accounts and calculate total balance
    const accounts = await accountsService.getAccountsWithBalance(userId);
    const totalBalance = accounts.reduce((acc, curr) => acc + curr.currentBalance, 0);

    // Monthly income aggregate
    const incomeAggregate = await prisma.transaction.aggregate({
      where: {
        userId,
        type: 'INCOME',
        transactionDate: { gte: startOfMonth, lte: endOfMonth },
      },
      _sum: { amount: true },
    });

    // Monthly expense aggregate
    const expenseAggregate = await prisma.transaction.aggregate({
      where: {
        userId,
        type: 'EXPENSE',
        transactionDate: { gte: startOfMonth, lte: endOfMonth },
      },
      _sum: { amount: true },
    });

    const monthlyIncome = Number(incomeAggregate._sum.amount ?? 0);
    const monthlyExpense = Number(expenseAggregate._sum.amount ?? 0);
    const netSavings = monthlyIncome - monthlyExpense;

    // Recent 5 transactions
    const recentTransactions = await prisma.transaction.findMany({
      where: { userId },
      orderBy: { transactionDate: 'desc' },
      take: 5,
      include: {
        account: { select: { id: true, name: true } },
        category: { select: { id: true, name: true, icon: true, color: true } },
      },
    });

    return {
      period: {
        month: now.getMonth() + 1,
        year: now.getFullYear(),
      },
      totalBalance,
      monthlyIncome,
      monthlyExpense,
      netSavings,
      accountsSummary: accounts.map((a) => ({
        id: a.id,
        name: a.name,
        type: a.accountType,
        balance: a.currentBalance,
      })),
      recentTransactions: recentTransactions.map((t) => ({
        ...t,
        amount: Number(t.amount),
      })),
    };
  }
}

export const dashboardService = new DashboardService();

