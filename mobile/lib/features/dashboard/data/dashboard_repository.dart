import 'package:dio/dio.dart';

import '../../../core/constants/api_routes.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/dashboard_summary_model.dart';

class DashboardRepository {
  DashboardRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DashboardSummaryModel> getSummary() async {
    try {
      final response = await _apiClient.dio.get(ApiRoutes.dashboardSummary);
      final data = response.data['data'] as Map<String, dynamic>;
      return DashboardSummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }
}

