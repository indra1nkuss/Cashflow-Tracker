import 'package:dio/dio.dart';

import '../../../core/constants/api_routes.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/report_model.dart';

class ReportsRepository {
  ReportsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<MonthlyReportModel> getMonthlyReport(int year, int month) async {
    try {
      final response = await _apiClient.dio.get(
        ApiRoutes.monthlyReport,
        queryParameters: {'year': year, 'month': month},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return MonthlyReportModel.fromJson(data);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }
}
