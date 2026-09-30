import '../../shared/models/user.dart';
import '../api/api_client.dart';
import '../errors/api_exception.dart';
import '../session/session_data.dart';
import '../storage/session_storage.dart';
import '../storage/storage_value_parser.dart';
import 'auth_result.dart';

/// Clean Authentication Service managing login, logout, profile retrieval,
/// and persistent session state restoration against the AceEdx Laravel API.
///
/// Responsibilities:
/// 1. `POST /api/auth/login` dispatcher & response parsing.
/// 2. Seamless persistence through [SessionStorage].
/// 3. `POST /api/auth/logout` and guaranteed local session clearance.
/// 4. `GET /api/auth/profile` and session restoration.
/// 5. Type-safe error translation without leaking transport/credential details.
class AuthenticationService {
  final ApiClient apiClient;
  final SessionStorage sessionStorage;

  AuthenticationService({
    required this.apiClient,
    required this.sessionStorage,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Current Session State Getters (Source of truth: SessionStorage)
  // ──────────────────────────────────────────────────────────────────────────

  /// Whether there is currently an authenticated session.
  bool get isAuthenticated => sessionStorage.isAuthenticated();

  /// Gets the latest [SessionData] snapshot.
  SessionData get currentSession => sessionStorage.readSession();

  /// Gets the currently active/selected user role.
  String? get currentRole => sessionStorage.getSelectedRole();

  /// Gets the current authenticated user ID.
  int? get currentUserId => sessionStorage.getUserId();

  /// Gets the current school ID.
  int? get currentSchoolId => sessionStorage.getSchoolId();

  /// Gets the current teacher ID.
  int? get currentTeacherId => sessionStorage.getTeacherId();

  /// Gets the active Bearer token.
  String? get token => sessionStorage.getToken();

  /// Whether an active session exists with both a valid token and user ID.
  bool get hasActiveSession => sessionStorage.hasActiveSession();

  // ──────────────────────────────────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────────────────────────────────

  /// Authenticates a user with their [email], [password], and selected [role].
  ///
  /// Dispatches `POST /api/auth/login`.
  /// On success:
  /// - Extracts token and user data.
  /// - Normalizes and persists state via [SessionStorage].
  /// - Returns a typed [AuthResult.success].
  ///
  /// On error:
  /// - Returns a typed [AuthResult.failure] with human-readable error messages.
  Future<AuthResult> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final cleanEmail = email.trim();
    final cleanRole = role.trim();

    // 1. Local validation
    if (cleanEmail.isEmpty) {
      return AuthResult.failure(
        message: 'Email is required',
        statusCode: 422,
        errors: {
          'email': ['The email field is required.']
        },
        selectedRole: cleanRole,
      );
    }
    if (password.isEmpty) {
      return AuthResult.failure(
        message: 'Password is required',
        statusCode: 422,
        errors: {
          'password': ['The password field is required.']
        },
        selectedRole: cleanRole,
      );
    }
    if (cleanRole.isEmpty) {
      return AuthResult.failure(
        message: 'Role is required',
        statusCode: 422,
        errors: {
          'role': ['The role field is required.']
        },
      );
    }

    try {
      // 2. Call backend login endpoint
      final response = await apiClient.post(
        '/auth/login',
        body: {
          'email': cleanEmail,
          'password': password,
          'role': cleanRole,
        },
        requiresAuth: false,
      );

      // 3. Parse response
      if (response is! Map<String, dynamic>) {
        return AuthResult.failure(
          message: 'Invalid response format received from authentication server',
          statusCode: 500,
          selectedRole: cleanRole,
        );
      }

      final message = response['message']?.toString() ?? 'Login successful';
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;

      // 4. Extract token
      final rawToken = data['token'] ?? data['access_token'] ?? response['token'];
      final token = StorageValueParser.normalizeToken(rawToken);

      if (token == null || token.isEmpty) {
        return AuthResult.failure(
          message: 'Authentication token not found in server response',
          statusCode: 500,
          selectedRole: cleanRole,
        );
      }

      // 5. Extract user fields
      final rawUser = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : (response['user'] is Map<String, dynamic>
              ? response['user'] as Map<String, dynamic>
              : <String, dynamic>{});

      final userId = StorageValueParser.parseInt(rawUser['id']) ??
          StorageValueParser.parseInt(data['user_id']);
      final userName = StorageValueParser.parseString(rawUser['name'] ?? rawUser['user_name']) ??
          cleanEmail.split('@').first;
      final userEmail = StorageValueParser.parseString(rawUser['email']) ?? cleanEmail;
      final userPhone = StorageValueParser.parseString(rawUser['phone']);
      final userRole = StorageValueParser.parseString(rawUser['role']) ?? cleanRole;

      final rolesList = StorageValueParser.parseStringList(rawUser['roles']) ??
          [userRole];

      // School ID resolution: check data.school_id first, then data.user.school_id
      final schoolId = StorageValueParser.parseInt(data['school_id']) ??
          StorageValueParser.parseInt(rawUser['school_id']);

      // Teacher ID resolution: check data.teacher_id first, then data.user.teacher_id
      final teacherId = StorageValueParser.parseInt(data['teacher_id']) ??
          StorageValueParser.parseInt(rawUser['teacher_id']);

      final schoolName = StorageValueParser.parseString(data['school_name'] ?? rawUser['school_name']);
      final photoUrl = StorageValueParser.parseString(
        rawUser['profile_photo_url'] ?? rawUser['avatar'] ?? rawUser['profile_photo'],
      );
      final childrenName = StorageValueParser.parseString(rawUser['children_name'] ?? data['children_name']);
      final refreshToken = StorageValueParser.parseString(data['refresh_token']);

      // 6. Build and save SessionData
      final session = SessionData(
        isAuthenticated: true,
        userToken: token,
        refreshToken: refreshToken,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        userRoles: rolesList,
        selectedRole: cleanRole,
        schoolId: schoolId,
        teacherId: teacherId,
        schoolName: schoolName,
        profilePhotoUrl: photoUrl,
        childrenName: childrenName,
      );

      await sessionStorage.saveSession(session);
      await sessionStorage.setIsAuthenticated(true);

      final user = User(
        id: userId ?? 0,
        name: userName,
        email: userEmail,
        phone: userPhone,
        role: userRole,
        roles: rolesList,
        schoolId: schoolId,
        teacherId: teacherId,
        schoolName: schoolName,
        profilePhotoUrl: photoUrl,
        childrenName: childrenName,
      );

      return AuthResult.success(
        session: session,
        user: user,
        selectedRole: cleanRole,
        message: message,
      );
    } on ValidationException catch (e) {
      return AuthResult.failure(
        message: e.message,
        statusCode: 422,
        errors: e.errors,
        selectedRole: cleanRole,
      );
    } on UnauthorizedException catch (e) {
      return AuthResult.failure(
        message: e.message,
        statusCode: 401,
        selectedRole: cleanRole,
      );
    } on ForbiddenException catch (e) {
      return AuthResult.failure(
        message: e.message,
        statusCode: 403,
        selectedRole: cleanRole,
      );
    } on RateLimitException catch (e) {
      return AuthResult.failure(
        message: e.message,
        statusCode: 429,
        selectedRole: cleanRole,
      );
    } on TimeoutException catch (e) {
      return AuthResult.failure(
        message: e.message,
        statusCode: 408,
        selectedRole: cleanRole,
      );
    } on NetworkException catch (e) {
      return AuthResult.failure(
        message: e.message,
        statusCode: 0,
        selectedRole: cleanRole,
      );
    } on ApiException catch (e) {
      return AuthResult.failure(
        message: e.message,
        statusCode: e.statusCode ?? 500,
        errors: e.data is Map ? (e.data as Map)['errors'] : null,
        selectedRole: cleanRole,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Authentication failed: $e',
        statusCode: 500,
        selectedRole: cleanRole,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────────────────────────────────────

  /// Logs out the user from the backend and clears local session storage.
  ///
  /// Calls `POST /api/auth/logout`.
  /// Guaranteed to clear local session even if the API call fails or encounters
  /// network errors.
  Future<AuthResult> logout() async {
    try {
      final token = sessionStorage.getToken();
      if (token != null && token.isNotEmpty) {
        await apiClient.post(
          '/auth/logout',
          requiresAuth: true,
        );
      }
    } catch (_) {
      // Ignored: network failure or expired token must not block local logout
    } finally {
      await sessionStorage.clearSession();
    }

    return AuthResult.success(
      session: SessionData.empty,
      message: 'Logged out successfully',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Profile & Session Restoration
  // ──────────────────────────────────────────────────────────────────────────

  /// Validates and restores an existing active session.
  ///
  /// Dispatches `GET /api/auth/profile` when a token is present.
  /// - If unauthenticated (no token): returns unauthenticated result.
  /// - If profile succeeds: updates available user info without clearing active roles.
  /// - If profile returns 401/403 (expired/revoked token): clears local session.
  Future<AuthResult> restoreSession() async {
    final token = sessionStorage.getToken();
    if (token == null || token.isEmpty) {
      return AuthResult.failure(
        message: 'No active authentication session',
        statusCode: 401,
      );
    }

    try {
      final response = await apiClient.get(
        '/auth/profile',
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final userData = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : (response['user'] is Map<String, dynamic>
                ? response['user'] as Map<String, dynamic>
                : response);

        final current = sessionStorage.readSession();
        final updatedUserId = StorageValueParser.parseInt(userData['id']) ?? current.userId;
        final updatedName = StorageValueParser.parseString(userData['name'] ?? userData['user_name']) ?? current.userName;
        final updatedEmail = StorageValueParser.parseString(userData['email']) ?? current.userEmail;
        final updatedPhone = StorageValueParser.parseString(userData['phone']) ?? current.userPhone;
        final updatedSchoolId = StorageValueParser.parseInt(userData['school_id']) ?? current.schoolId;
        final updatedTeacherId = StorageValueParser.parseInt(userData['teacher_id']) ?? current.teacherId;
        final updatedSchoolName = StorageValueParser.parseString(userData['school_name']) ?? current.schoolName;
        final updatedPhoto = StorageValueParser.parseString(
          userData['profile_photo_url'] ?? userData['avatar'] ?? userData['profile_photo'],
        ) ?? current.profilePhotoUrl;
        final updatedChildren = StorageValueParser.parseString(userData['children_name']) ?? current.childrenName;
        final updatedRoles = StorageValueParser.parseStringList(userData['roles']) ?? current.userRoles;

        final updatedSession = current.copyWith(
          userId: updatedUserId,
          userName: updatedName,
          userEmail: updatedEmail,
          userPhone: updatedPhone,
          schoolId: updatedSchoolId,
          teacherId: updatedTeacherId,
          schoolName: updatedSchoolName,
          profilePhotoUrl: updatedPhoto,
          childrenName: updatedChildren,
          userRoles: updatedRoles,
          isAuthenticated: true,
        );

        await sessionStorage.saveSession(updatedSession);

        final user = User(
          id: updatedUserId ?? 0,
          name: updatedName ?? '',
          email: updatedEmail ?? '',
          phone: updatedPhone,
          role: current.selectedRole ?? 'teacher',
          roles: updatedRoles ?? const [],
          schoolId: updatedSchoolId,
          teacherId: updatedTeacherId,
          schoolName: updatedSchoolName,
          profilePhotoUrl: updatedPhoto,
          childrenName: updatedChildren,
        );

        return AuthResult.success(
          session: updatedSession,
          user: user,
          selectedRole: current.selectedRole,
          message: 'Session restored successfully',
        );
      }

      return AuthResult.failure(
        message: 'Unexpected profile response format',
        statusCode: 500,
      );
    } on UnauthorizedException {
      // Token is invalid/expired — clear local session
      await sessionStorage.clearSession();
      return AuthResult.failure(
        message: 'Session expired. Please login again.',
        statusCode: 401,
      );
    } on ForbiddenException {
      await sessionStorage.clearSession();
      return AuthResult.failure(
        message: 'Access forbidden for current session.',
        statusCode: 403,
      );
    } on NetworkException catch (e) {
      // For network failure during restore, return failure without deleting session
      return AuthResult.failure(
        message: e.message,
        statusCode: 0,
        session: sessionStorage.readSession(),
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Failed to restore session: $e',
        statusCode: 500,
      );
    }
  }

  /// Fetches the authenticated user's profile.
  Future<User?> getProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await apiClient.get(
        '/auth/profile',
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        final userData = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : (response['user'] is Map<String, dynamic>
                ? response['user'] as Map<String, dynamic>
                : response);

        return User.fromJson(userData);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
