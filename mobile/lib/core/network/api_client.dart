import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../errors/app_error.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: kConnectTimeout,
        receiveTimeout: kReceiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _debugLog(obj.toString()),
      ),
    ]);
  }

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get dio => _dio;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: kTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) {
        if (err.response?.statusCode == 401) {
          // Clear storage and redirect to login (handled via router redirect)
          _storage.deleteAll();
        }
        handler.next(err);
      },
    );
  }

  AppError handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkError(message: 'Koneksi timeout. Periksa jaringan Anda.');
      case DioExceptionType.connectionError:
        return const NetworkError(message: 'Tidak dapat terhubung ke server.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?['message'] as String? ?? 'Terjadi kesalahan pada server';
        if (statusCode == 401) return const UnauthorizedError();
        if (statusCode == 404) return NotFoundError(message: message);
        if (statusCode == 422) {
          return ValidationError(message: message);
        }
        return ServerError(message: message, statusCode: statusCode);
      default:
        return const UnknownError();
    }
  }

  void _debugLog(String message) {
    // Only print in debug mode
    assert(() {
      // ignore: avoid_print
      print('[ApiClient] $message');
      return true;
    }());
  }
}

