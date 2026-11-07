abstract class AppError {
  const AppError({required this.message});
  final String message;
}

class NetworkError extends AppError {
  const NetworkError({required super.message, this.statusCode});
  final int? statusCode;
}

class UnauthorizedError extends AppError {
  const UnauthorizedError() : super(message: 'Sesi Anda telah berakhir. Silakan login kembali.');
}

class ServerError extends AppError {
  const ServerError({required super.message, this.statusCode});
  final int? statusCode;
}

class ValidationError extends AppError {
  const ValidationError({required super.message, this.fieldErrors});
  final Map<String, String>? fieldErrors;
}

class NotFoundError extends AppError {
  const NotFoundError({super.message = 'Data tidak ditemukan'});
}

class UnknownError extends AppError {
  const UnknownError() : super(message: 'Terjadi kesalahan. Mohon coba lagi.');
}

