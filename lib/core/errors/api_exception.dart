/// Base exception for all AceEdx HTTP API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.endpoint,
    this.data,
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, endpoint: $endpoint, message: $message)';
}

/// HTTP 400 Bad Request
class BadRequestException extends ApiException {
  const BadRequestException({
    required super.message,
    super.statusCode = 400,
    super.endpoint,
    super.data,
  });
}

/// HTTP 401 Unauthorized (invalid or expired token)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    required super.message,
    super.statusCode = 401,
    super.endpoint,
    super.data,
  });
}

/// HTTP 403 Forbidden (insufficient permissions / role restriction)
class ForbiddenException extends ApiException {
  const ForbiddenException({
    required super.message,
    super.statusCode = 403,
    super.endpoint,
    super.data,
  });
}

/// HTTP 404 Not Found
class NotFoundException extends ApiException {
  const NotFoundException({
    required super.message,
    super.statusCode = 404,
    super.endpoint,
    super.data,
  });
}

/// HTTP 422 Unprocessable Entity (validation error from Laravel API)
class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  const ValidationException({
    super.message = 'The given data was invalid.',
    super.statusCode = 422,
    super.endpoint,
    super.data,
    this.errors,
  });

  /// Returns error messages for a specific field name.
  List<String> errorsFor(String field) {
    if (errors == null) return const [];
    final fieldErrors = errors![field];
    if (fieldErrors is List) {
      return fieldErrors.map((e) => e.toString()).toList();
    }
    if (fieldErrors is String) {
      return [fieldErrors];
    }
    return const [];
  }

  /// Returns all flattened error messages.
  List<String> get allErrors {
    if (errors == null) return const [];
    final result = <String>[];
    for (final entry in errors!.values) {
      if (entry is List) {
        result.addAll(entry.map((e) => e.toString()));
      } else if (entry is String) {
        result.add(entry);
      }
    }
    return result;
  }
}

/// HTTP 429 Too Many Requests (rate limiting)
class RateLimitException extends ApiException {
  const RateLimitException({
    required super.message,
    super.statusCode = 429,
    super.endpoint,
    super.data,
  });
}

/// HTTP 5xx Server Error
class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.statusCode = 500,
    super.endpoint,
    super.data,
  });
}

/// Thrown when server response cannot be decoded as valid JSON
class InvalidResponseException extends ApiException {
  final String? rawBody;

  const InvalidResponseException({
    required super.message,
    super.statusCode,
    super.endpoint,
    this.rawBody,
  });
}

/// Network connectivity / client failure (pure web-safe, no dart:io)
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Network connection failed. Please check your internet connection.',
    super.statusCode,
    super.endpoint,
    super.data,
  });
}

/// Request timeout exception
class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Request timed out. The server took too long to respond.',
    super.endpoint,
  }) : super(statusCode: 408);
}
