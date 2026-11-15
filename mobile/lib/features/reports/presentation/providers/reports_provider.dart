import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reports_repository.dart';
import '../../domain/models/report_model.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

final reportPeriodProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

class ReportsNotifier extends AsyncNotifier<MonthlyReportModel> {
  @override
  Future<MonthlyReportModel> build() async {
    final period = ref.watch(reportPeriodProvider);
    return _fetchReport(period.year, period.month);
  }

  Future<MonthlyReportModel> _fetchReport(int year, int month) async {
    final repo = ref.read(reportsRepositoryProvider);
    return repo.getMonthlyReport(year, month);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final period = ref.read(reportPeriodProvider);
    state = await AsyncValue.guard(() => _fetchReport(period.year, period.month));
  }

  /// Silently re-fetches latest monthly report without showing a loading spinner
  Future<void> silentRefresh() async {
    try {
      final period = ref.read(reportPeriodProvider);
      final report = await _fetchReport(period.year, period.month);
      state = AsyncValue.data(report);
    } catch (_) {
      // Ignored in background
    }
  }

  void previousMonth() {
    final current = ref.read(reportPeriodProvider);
    ref.read(reportPeriodProvider.notifier).state =
        DateTime(current.year, current.month - 1);
  }

  void nextMonth() {
    final current = ref.read(reportPeriodProvider);
    ref.read(reportPeriodProvider.notifier).state =
        DateTime(current.year, current.month + 1);
  }
}

final reportsNotifierProvider =
    AsyncNotifierProvider<ReportsNotifier, MonthlyReportModel>(() {
  return ReportsNotifier();
});

