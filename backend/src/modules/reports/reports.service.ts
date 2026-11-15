import { prisma } from '../../config/database.js';

export type ReportPeriod = 'day' | 'week' | 'month' | 'year';

export interface ReportSummaryResult {
  periodType: ReportPeriod;
  periodLabel: string;
  startDate: Date;
  endDate: Date;
  totalIncome: number;
  totalExpense: number;
  netCashflow: number;
  transactionCount: number;
  incomeCategories: { name: string; total: number }[];
  expenseCategories: { name: string; total: number }[];
}

export class ReportsService {
  public async getPeriodSummary(
    userId: string,
    period: ReportPeriod = 'month'
  ): Promise<ReportSummaryResult> {
    const now = new Date();
    let startDate: Date;
    let endDate: Date;
    let periodLabel: string;

    const indonesianMonths = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    if (period === 'day') {
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
      endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      periodLabel = `Hari Ini (${now.getDate()} ${indonesianMonths[now.getMonth()]} ${now.getFullYear()})`;
    } else if (period === 'week') {
      const day = now.getDay();
      const diffToMonday = day === 0 ? -6 : 1 - day;
      const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() + diffToMonday, 0, 0, 0, 0);
      const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6, 23, 59, 59, 999);
      startDate = monday;
      endDate = sunday;
      periodLabel = `Minggu Ini (${monday.getDate()} ${indonesianMonths[monday.getMonth()]} - ${sunday.getDate()} ${indonesianMonths[sunday.getMonth()]} ${sunday.getFullYear()})`;
    } else if (period === 'year') {
      startDate = new Date(now.getFullYear(), 0, 1, 0, 0, 0, 0);
      endDate = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);
      periodLabel = `Tahun Ini (${now.getFullYear()})`;
    } else {
      // Month
      startDate = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
      periodLabel = `Bulan Ini (${indonesianMonths[now.getMonth()]} ${now.getFullYear()})`;
    }

    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        transactionDate: { gte: startDate, lte: endDate },
      },
      include: {
        category: true,
      },
      orderBy: { transactionDate: 'desc' },
    });

    let totalIncome = 0;
    let totalExpense = 0;
    const incomeMap = new Map<string, number>();
    const expenseMap = new Map<string, number>();

    for (const t of transactions) {
      const amt = Number(t.amount);
      const catName = t.category.name;
      if (t.type === 'INCOME') {
        totalIncome += amt;
        incomeMap.set(catName, (incomeMap.get(catName) || 0) + amt);
      } else {
        totalExpense += amt;
        expenseMap.set(catName, (expenseMap.get(catName) || 0) + amt);
      }
    }

    const incomeCategories = Array.from(incomeMap.entries())
      .map(([name, total]) => ({ name, total }))
      .sort((a, b) => b.total - a.total);

    const expenseCategories = Array.from(expenseMap.entries())
      .map(([name, total]) => ({ name, total }))
      .sort((a, b) => b.total - a.total);

    return {
      periodType: period,
      periodLabel,
      startDate,
      endDate,
      totalIncome,
      totalExpense,
      netCashflow: totalIncome - totalExpense,
      transactionCount: transactions.length,
      incomeCategories,
      expenseCategories,
    };
  }

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

