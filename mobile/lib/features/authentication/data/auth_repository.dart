import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/user_model.dart';

class AuthResponse {
  const AuthResponse({required this.user, required this.token});
  final UserModel user;
  final String token;
}

class AuthRepository {
  AuthRepository({
    ApiClient? apiClient,
    FlutterSecureStorage? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiRoutes.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      await _persistAuth(token: token, user: user);

      return AuthResponse(user: user, token: token);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiRoutes.register,
        data: {
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      await _persistAuth(token: token, user: user);

      return AuthResponse(user: user, token: token);
    } on DioException catch (e) {
      throw _apiClient.handleDioError(e);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: kTokenKey);
      if (token == null || token.isEmpty) return null;

      final response = await _apiClient.dio.get(ApiRoutes.me);
      final data = response.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data);

      await _storage.write(key: kUserKey, value: jsonEncode(user.toJson()));
      return user;
    } catch (_) {
      // Fallback to locally cached user if network fails
      final cachedJson = await _storage.read(key: kUserKey);
      if (cachedJson != null) {
        try {
          return UserModel.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
        } catch (_) {}
      }
      return null;
    }
  }

  Future<String?> getToken() async {
    return _storage.read(key: kTokenKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: kTokenKey);
    await _storage.delete(key: kUserKey);
  }

  Future<void> _persistAuth({required String token, required UserModel user}) async {
    await _storage.write(key: kTokenKey, value: token);
    await _storage.write(key: kUserKey, value: jsonEncode(user.toJson()));
  }
}
