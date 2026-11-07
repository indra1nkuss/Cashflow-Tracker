import { prisma } from '../../config/database.js';

export class ReportsService {
  public async getMonthlyBreakdown(userId: string, year: number, month: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999);

    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        transactionDate: { gte: startDate, lte: endDate },
      },
      include: {
        category: true,
      },
    });

    const categoryMap = new Map<string, { name: string; type: string; total: number; color?: string }>();

    let totalIncome = 0;
    let totalExpense = 0;

    for (const t of transactions) {
      const amt = Number(t.amount);
      if (t.type === 'INCOME') totalIncome += amt;
      else totalExpense += amt;

      const catName = t.category.name;
      const existing = categoryMap.get(catName) || {
        name: catName,
        type: t.type,
        total: 0,
        color: t.category.color ?? undefined,
      };
      existing.total += amt;
      categoryMap.set(catName, existing);
    }

    return {
      period: { year, month },
      totalIncome,
      totalExpense,
      netCashflow: totalIncome - totalExpense,
      categoryBreakdown: Array.from(categoryMap.values()).sort((a, b) => b.total - a.total),
    };
  }
}

export const reportsService = new ReportsService();

