/// Normalized HTTP / network failure for the data layer.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  final String message;
  final int? statusCode;
  final Object? originalError;

  factory ApiException.fromDio(Object error) {
    if (error is ApiException) return error;

    return ApiException(
      message: 'An unexpected network error occurred.',
      originalError: error,
    );
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}
