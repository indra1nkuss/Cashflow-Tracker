import 'package:dio/dio.dart';

import '../../../core/constants/api_routes.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/category_model.dart';

class CategoriesRepository {
  CategoriesRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CategoryModel>> getCategories({String? type}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiRoutes.categories,
        queryParameters: type != null ? {'type': type} : null,
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiRoutes.categories,
        data: {
          'name': name.trim(),
          'type': type,
          if (icon != null) 'icon': icon,
          if (color != null) 'color': color,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return CategoryModel.fromJson(data);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }
}

