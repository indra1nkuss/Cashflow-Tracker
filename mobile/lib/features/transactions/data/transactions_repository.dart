import 'package:dio/dio.dart';

import '../../../core/constants/api_routes.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/transaction_model.dart';

class TransactionsRepository {
  TransactionsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<TransactionModel>> getTransactions({
    String? type,
    String? accountId,
    String? categoryId,
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiRoutes.transactions,
        queryParameters: {
          if (type != null) 'type': type,
          if (accountId != null) 'accountId': accountId,
          if (categoryId != null) 'categoryId': categoryId,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          'limit': limit,
          'offset': offset,
        },
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }

  Future<TransactionModel> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String accountId,
    required String categoryId,
    DateTime? transactionDate,
    String? notes,
    String source = 'MOBILE',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiRoutes.transactions,
        data: {
          'type': type,
          'amount': amount,
          'description': description.trim(),
          'accountId': accountId,
          'categoryId': categoryId,
          'transactionDate': (transactionDate ?? DateTime.now()).toIso8601String(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          'source': source,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return TransactionModel.fromJson(data);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _apiClient.dio.delete(ApiRoutes.transactionById(id));
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }
}

