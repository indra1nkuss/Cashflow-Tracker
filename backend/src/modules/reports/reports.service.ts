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
    // Fix timezone: server runs UTC, user is in WIB (UTC+7)
    // We compute "now" in WIB so date boundaries are correct for Indonesian users
    const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;
    const nowUTC = new Date();
    const nowWIB = new Date(nowUTC.getTime() + WIB_OFFSET_MS);

    // Helper: build a WIB wall-clock Date, then shift back to UTC for DB queries
    const wibToUTC = (year: number, month: number, day: number, h: number, m: number, s: number, ms: number): Date => {
      // Date.UTC gives UTC timestamp for a given wall-clock date in UTC,
      // but we want to treat it as WIB wall-clock, so subtract WIB offset
      return new Date(Date.UTC(year, month, day, h, m, s, ms) - WIB_OFFSET_MS);
    };

    let startDate: Date;
    let endDate: Date;
    let periodLabel: string;

    const yr  = nowWIB.getUTCFullYear();
    const mo  = nowWIB.getUTCMonth();
    const day = nowWIB.getUTCDate();
    const dow = nowWIB.getUTCDay(); // 0=Sun..6=Sat

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
      startDate = wibToUTC(yr, mo, day, 0, 0, 0, 0);
      endDate   = wibToUTC(yr, mo, day, 23, 59, 59, 999);
      periodLabel = `Hari Ini (${day} ${indonesianMonths[mo]} ${yr})`;
    } else if (period === 'week') {
      const diffToMonday = dow === 0 ? -6 : 1 - dow;
      const monDay = day + diffToMonday;
      const monday = new Date(Date.UTC(yr, mo, monDay) - WIB_OFFSET_MS);
      const sunday = new Date(Date.UTC(yr, mo, monDay + 6, 23, 59, 59, 999) - WIB_OFFSET_MS);
      startDate = monday;
      endDate   = sunday;
      // Labels: convert back to WIB for display
      const monWIB = new Date(monday.getTime() + WIB_OFFSET_MS);
      const sunWIB = new Date(sunday.getTime() + WIB_OFFSET_MS);
      periodLabel = `Minggu Ini (${monWIB.getUTCDate()} ${indonesianMonths[monWIB.getUTCMonth()]} - ${sunWIB.getUTCDate()} ${indonesianMonths[sunWIB.getUTCMonth()]} ${sunWIB.getUTCFullYear()})`;
    } else if (period === 'year') {
      startDate = wibToUTC(yr, 0, 1, 0, 0, 0, 0);
      endDate   = wibToUTC(yr, 11, 31, 23, 59, 59, 999);
      periodLabel = `Tahun Ini (${yr})`;
    } else {
      // Month
      const lastDayOfMonth = new Date(Date.UTC(yr, mo + 1, 0)).getUTCDate();
      startDate = wibToUTC(yr, mo, 1, 0, 0, 0, 0);
      endDate   = wibToUTC(yr, mo, lastDayOfMonth, 23, 59, 59, 999);
      periodLabel = `Bulan Ini (${indonesianMonths[mo]} ${yr})`;
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

