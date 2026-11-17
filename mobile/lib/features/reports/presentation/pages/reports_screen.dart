import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../../../shared/widgets/bubble_background.dart';
import '../../domain/models/report_model.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static const List<Color> _chartPalette = [
    Color(0xFFE11D48), // Rose Red
    Color(0xFFF97316), // Sunset Orange
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFFFB7185), // Soft Crimson
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Purple
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final period = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(reportsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Keuangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(reportsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B24) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF332D3C) : const Color(0xFFFFECE5),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primaryColor),
                  tooltip: 'Bulan Sebelumnya',
                  onPressed: () =>
                      ref.read(reportsNotifierProvider.notifier).previousMonth(),
                ),
                Text(
                  DateFormatter.formatMonthYear(period),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1C1917),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor),
                  tooltip: 'Bulan Berikutnya',
                  onPressed: () =>
                      ref.read(reportsNotifierProvider.notifier).nextMonth(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Content
          Expanded(
            child: reportAsync.when(
              loading: () => const AppLoadingWidget(message: 'Memuat laporan...'),
              error: (err, _) => AppErrorWidget(
                message: 'Gagal memuat laporan: $err',
                onRetry: () =>
                    ref.read(reportsNotifierProvider.notifier).refresh(),
              ),
              data: (report) {
                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () =>
                      ref.read(reportsNotifierProvider.notifier).refresh(),
                  child: ListView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Cashflow Summary Card
                      _buildCashflowCard(context, report),
                      const SizedBox(height: 24),

                      // Expense Category Distribution Header
                      Text(
                        'Distribusi Pengeluaran',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (report.expenseBreakdown.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1B24) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF332D3C) : const Color(0xFFFFECE5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF331D24) : const Color(0xFFFFF1F2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 40,
                                  color: isDark ? const Color(0xFFFB7185) : AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Belum ada pengeluaran di bulan ini',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF78716C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Donut Chart
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1B24) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF332D3C) : const Color(0xFFFFECE5),
                            ),
                          ),
                          height: 240,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 48,
                              sections: _buildChartSections(report),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Breakdown Items
                        ...report.expenseBreakdown.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final color = _chartPalette[index % _chartPalette.length];
                          final percentage = report.totalExpense > 0
                              ? (item.total / report.totalExpense) * 100
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : const Color(0xFF1C1917),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(item.total)} (${percentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF292524),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: isDark ? const Color(0xFF332D3C) : const Color(0xFFFFECE5),
                                    color: color,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowCard(BuildContext context, MonthlyReportModel report) {
    final isPositive = report.netCashflow >= 0;
    final colors = AppTheme.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        gradient: colors.sunsetGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            const AmbientBubbles(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insert_chart_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Ringkasan Cashflow',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Income & Expense pills
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34D399),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Pemasukan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.format(report.totalIncome),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFCA5A5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.format(report.totalExpense),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Net cashflow row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Net Cashflow',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: isPositive
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFFCA5A5),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isPositive ? "+" : ""}${CurrencyFormatter.format(report.netCashflow)}',
                              style: TextStyle(
                                color: isPositive
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFFCA5A5),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(MonthlyReportModel report) {
    final total = report.totalExpense;
    if (total == 0) return [];

    return report.expenseBreakdown.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = (item.total / total) * 100;
      final color = _chartPalette[index % _chartPalette.length];

      return PieChartSectionData(
        color: color,
        value: item.total,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 46,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
