import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../domain/models/report_model.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static const List<Color> _chartPalette = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF6B7280),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final period = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(reportsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Bulan Sebelumnya',
                  onPressed: () =>
                      ref.read(reportsNotifierProvider.notifier).previousMonth(),
                ),
                Text(
                  DateFormatter.formatMonthYear(period),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Bulan Berikutnya',
                  onPressed: () =>
                      ref.read(reportsNotifierProvider.notifier).nextMonth(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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
                  onRefresh: () =>
                      ref.read(reportsNotifierProvider.notifier).refresh(),
                  child: ListView(
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
                            color: theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.pie_chart_outline_rounded,
                                  size: 48,
                                  color: theme.colorScheme.outlineVariant),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada pengeluaran di bulan ini',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Donut Chart
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 44,
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(item.total)} (${percentage.toStringAsFixed(1)}%)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHigh,
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
    final theme = Theme.of(context);
    final isPositive = report.netCashflow >= 0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pemasukan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(report.totalIncome),
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pengeluaran',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(report.totalExpense),
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selisih / Net Cashflow',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${isPositive ? "+" : ""}${CurrencyFormatter.format(report.netCashflow)}',
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
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
