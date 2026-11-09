import 'package:dio/dio.dart';

import '../../../core/constants/api_routes.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/telegram_status_model.dart';

class TelegramRepository {
  TelegramRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<TelegramStatusModel> getLinkStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiRoutes.telegramLinkStatus);
      final data = response.data['data'] as Map<String, dynamic>;
      return TelegramStatusModel.fromJson(data);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }

  Future<TelegramLinkCodeModel> generateLinkCode() async {
    try {
      final response = await _apiClient.dio.post('/telegram/generate-code');
      final data = response.data['data'] as Map<String, dynamic>;
      return TelegramLinkCodeModel.fromJson(data);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }

  Future<void> unlink() async {
    try {
      await _apiClient.dio.delete('/telegram/unlink');
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }
}
