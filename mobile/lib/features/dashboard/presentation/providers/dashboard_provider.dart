import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dashboard_repository.dart';
import '../../domain/models/dashboard_summary_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

class DashboardNotifier extends AsyncNotifier<DashboardSummaryModel> {
  @override
  Future<DashboardSummaryModel> build() async {
    return _fetchSummary();
  }

  Future<DashboardSummaryModel> _fetchSummary() async {
    final repo = ref.read(dashboardRepositoryProvider);
    return repo.getSummary();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSummary());
  }
}

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardSummaryModel>(() {
  return DashboardNotifier();
});
