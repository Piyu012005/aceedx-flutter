import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

import '../../app/config/app_config.dart';
import '../constants/api_timeouts.dart';
import '../errors/api_exception.dart';
import '../storage/session_storage.dart';
import '../storage/storage_value_parser.dart';

/// Reusable HTTP API client for all AceEdx modules.
///
/// Integrates with [SessionStorage] as the single source of truth for auth tokens.
///
/// Features:
/// - Automatic Bearer token normalization & injection (no double 'Bearer Bearer').
/// - Pure Flutter Web safe (zero `dart:io` dependencies).
/// - Safe request/response logging in debug mode (sensitive tokens and headers never logged).
/// - Clean status-code error mapping to typed [ApiException] subclasses.
class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  final SessionStorage? sessionStorage;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    this.sessionStorage,
  })  : baseUrl = baseUrl ?? AppConfig.current.apiBaseUrl,
        _httpClient = httpClient ?? http.Client();

  // ──────────────────────────────────────────────────────────────────────────
  // Token resolution
  // ──────────────────────────────────────────────────────────────────────────

  /// Resolves active Bearer token from [sessionStorage].
  /// Returns `null` when no authenticated session is present.
  String? get activeToken {
    if (sessionStorage != null) {
      return sessionStorage!.getToken();
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Header construction
  // ──────────────────────────────────────────────────────────────────────────

  /// Builds standard request headers.
  ///
  /// Always includes:
  ///   `Accept: application/json`
  ///   `Content-Type: application/json`
  ///
  /// When [requiresAuth] is `true` and a token is present:
  ///   `Authorization: Bearer <token>`
  ///
  /// Normalized token guarantees NEVER producing `Bearer Bearer <token>`.
  Map<String, String> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool requiresAuth = true,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = activeToken;
      final normalized = StorageValueParser.normalizeToken(token);
      if (normalized != null && normalized.isNotEmpty) {
        headers['Authorization'] = 'Bearer $normalized';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // URL construction
  // ──────────────────────────────────────────────────────────────────────────

  /// Resolves a full [Uri] by joining [baseUrl] with [path].
  Uri _resolveUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$normalizedBase$normalizedPath';

    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        ),
      );
    }
    return uri;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Response handling
  // ──────────────────────────────────────────────────────────────────────────

  dynamic _handleResponse(http.Response response, String endpoint) {
    _logResponse(response);

    dynamic body;
    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw InvalidResponseException(
        message: 'Server returned non-JSON response',
        statusCode: response.statusCode,
        endpoint: endpoint,
        rawBody: response.body.length > 500
            ? '${response.body.substring(0, 500)}…'
            : response.body,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = _extractMessage(body, response.statusCode);

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(
          message: message,
          statusCode: 400,
          endpoint: endpoint,
          data: body,
        );
      case 401:
        throw UnauthorizedException(
          message: message,
          statusCode: 401,
          endpoint: endpoint,
          data: body,
        );
      case 403:
        throw ForbiddenException(
          message: message,
          statusCode: 403,
          endpoint: endpoint,
          data: body,
        );
      case 404:
        throw NotFoundException(
          message: message,
          statusCode: 404,
          endpoint: endpoint,
          data: body,
        );
      case 422:
        final errors = body is Map ? body['errors'] : null;
        throw ValidationException(
          message: message,
          statusCode: 422,
          endpoint: endpoint,
          data: body,
          errors: errors is Map<String, dynamic> ? errors : null,
        );
      case 429:
        throw RateLimitException(
          message: message,
          statusCode: 429,
          endpoint: endpoint,
          data: body,
        );
      default:
        if (response.statusCode >= 500) {
          throw ServerException(
            message: message,
            statusCode: response.statusCode,
            endpoint: endpoint,
            data: body,
          );
        }
        throw ApiException(
          message: message,
          statusCode: response.statusCode,
          endpoint: endpoint,
          data: body,
        );
    }
  }

  String _extractMessage(dynamic body, int statusCode) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return 'Request failed with status $statusCode';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Safe request logging — NEVER logs auth headers or secret credentials
  // ──────────────────────────────────────────────────────────────────────────

  void _logRequest(String method, Uri uri) {
    if (!kDebugMode) return;
    final sanitized = '${uri.scheme}://${uri.host}${uri.path}';
    // ignore: avoid_print
    print('[ApiClient] $method $sanitized');
  }

  void _logResponse(http.Response response) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[ApiClient] ← ${response.statusCode} (${response.body.length} bytes)');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HTTP methods
  // ──────────────────────────────────────────────────────────────────────────

  /// Perform a GET request.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final uri = _resolveUri(path, queryParameters);
    _logRequest('GET', uri);
    try {
      final response = await _httpClient
          .get(
            uri,
            headers: _buildHeaders(
                extraHeaders: headers, requiresAuth: requiresAuth),
          )
          .timeout(timeout ?? ApiTimeouts.request);
      return _handleResponse(response, path);
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'HTTP client error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException(endpoint: path);
      }
      throw NetworkException(message: 'Network connection failed: $e');
    }
  }

  /// Perform a POST request.
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final uri = _resolveUri(path, queryParameters);
    _logRequest('POST', uri);
    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(
                extraHeaders: headers, requiresAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? ApiTimeouts.request);
      return _handleResponse(response, path);
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'HTTP client error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException(endpoint: path);
      }
      throw NetworkException(message: 'Network connection failed: $e');
    }
  }

  /// Perform a PUT request.
  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final uri = _resolveUri(path, queryParameters);
    _logRequest('PUT', uri);
    try {
      final response = await _httpClient
          .put(
            uri,
            headers: _buildHeaders(
                extraHeaders: headers, requiresAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? ApiTimeouts.request);
      return _handleResponse(response, path);
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'HTTP client error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException(endpoint: path);
      }
      throw NetworkException(message: 'Network connection failed: $e');
    }
  }

  /// Perform a PATCH request.
  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final uri = _resolveUri(path, queryParameters);
    _logRequest('PATCH', uri);
    try {
      final response = await _httpClient
          .patch(
            uri,
            headers: _buildHeaders(
                extraHeaders: headers, requiresAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? ApiTimeouts.request);
      return _handleResponse(response, path);
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'HTTP client error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException(endpoint: path);
      }
      throw NetworkException(message: 'Network connection failed: $e');
    }
  }

  /// Perform a DELETE request.
  Future<dynamic> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final uri = _resolveUri(path, queryParameters);
    _logRequest('DELETE', uri);
    try {
      final response = await _httpClient
          .delete(
            uri,
            headers: _buildHeaders(
                extraHeaders: headers, requiresAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? ApiTimeouts.request);
      return _handleResponse(response, path);
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'HTTP client error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException(endpoint: path);
      }
      throw NetworkException(message: 'Network connection failed: $e');
    }
  }

  /// Perform a multipart/form-data POST request.
  ///
  /// Used by the register endpoint because the old AceEdx Flutter app sent
  /// registration data as `multipart/form-data` to support the optional
  /// `profile_photo` file field.
  ///
  /// [fields] — string form fields (all values are coerced to String).
  /// [fileBytes] — optional raw bytes of the file to attach.
  /// [fileField] — multipart field name for the file (default: `profile_photo`).
  /// [fileName] — original filename sent in the Content-Disposition header.
  /// [mimeType] — MIME type of the file (default: `image/jpeg`).
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<int>? fileBytes,
    String fileField = 'profile_photo',
    String fileName = 'photo.jpg',
    String mimeType = 'image/jpeg',
    bool requiresAuth = false,
    Duration? timeout,
  }) async {
    final uri = _resolveUri(path);
    _logRequest('POST (multipart)', uri);

    final request = http.MultipartRequest('POST', uri);

    // Auth header only — do NOT set Content-Type (http package sets the
    // correct multipart/form-data boundary automatically).
    if (requiresAuth) {
      final token = activeToken;
      final normalized = StorageValueParser.normalizeToken(token);
      if (normalized != null && normalized.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $normalized';
      }
    }
    request.headers['Accept'] = 'application/json';

    // Add string fields.
    request.fields.addAll(fields);

    // Attach optional file.
    if (fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
        ),
      );
    }

    try {
      final streamedResponse =
          await request.send().timeout(timeout ?? ApiTimeouts.request);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, path);
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'HTTP client error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException(endpoint: path);
      }
      throw NetworkException(message: 'Network connection failed: $e');
    }
  }

  /// Returns the fully-resolved URL string for [path] (convenient for testing).
  String resolveUrl(String path, [Map<String, dynamic>? queryParameters]) {
    return _resolveUri(path, queryParameters).toString();
  }

  /// Disposes the underlying HTTP client.
  void close() => _httpClient.close();
}
