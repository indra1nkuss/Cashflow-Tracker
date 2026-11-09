import 'package:dio/dio.dart';

import '../../../core/constants/api_routes.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/account_model.dart';

class AccountsRepository {
  AccountsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AccountModel>> getAccounts() async {
    try {
      final response = await _apiClient.dio.get(ApiRoutes.accounts);
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => AccountModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }

  Future<AccountModel> createAccount({
    required String name,
    required String accountType,
    required double initialBalance,
    String currency = 'IDR',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiRoutes.accounts,
        data: {
          'name': name.trim(),
          'accountType': accountType,
          'initialBalance': initialBalance,
          'currency': currency,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return AccountModel.fromJson(data);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }
}

