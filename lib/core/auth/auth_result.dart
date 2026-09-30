import 'package:flutter/foundation.dart';

import '../../shared/models/user.dart';
import '../session/session_data.dart';

/// Typed result returned by authentication operations.
///
/// Encapsulates success state, user-friendly messages, session snapshots,
/// and structured error details without leaking raw HTTP transport details.
@immutable
class AuthResult {
  final bool success;
  final String message;
  final SessionData? session;
  final User? user;
  final String? selectedRole;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const AuthResult({
    required this.success,
    required this.message,
    this.session,
    this.user,
    this.selectedRole,
    this.statusCode,
    this.errors,
  });

  /// Factory for a successful authentication outcome.
  factory AuthResult.success({
    required SessionData session,
    User? user,
    String? selectedRole,
    String message = 'Authentication successful',
    int statusCode = 200,
  }) {
    return AuthResult(
      success: true,
      message: message,
      session: session,
      user: user,
      selectedRole: selectedRole ?? session.selectedRole,
      statusCode: statusCode,
    );
  }

  /// Factory for a failed authentication outcome.
  factory AuthResult.failure({
    required String message,
    int? statusCode,
    Map<String, dynamic>? errors,
    SessionData? session,
    String? selectedRole,
  }) {
    return AuthResult(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
      session: session,
      selectedRole: selectedRole,
    );
  }

  /// Whether the result contains an active authenticated session.
  bool get isAuthenticated => success && session != null && session!.hasToken;

  /// Returns error messages for a specific field name if present.
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.success == success &&
        other.message == message &&
        other.session == session &&
        other.user == user &&
        other.selectedRole == selectedRole &&
        other.statusCode == statusCode;
  }

  @override
  int get hashCode => Object.hash(
        success,
        message,
        session,
        user,
        selectedRole,
        statusCode,
      );

  @override
  String toString() {
    return 'AuthResult(success: $success, message: $message, '
        'selectedRole: $selectedRole, statusCode: $statusCode, '
        'isAuthenticated: $isAuthenticated)';
  }
}
