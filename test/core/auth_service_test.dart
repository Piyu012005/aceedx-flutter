import 'dart:convert';
import 'dart:io' as io show File;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aceedx_flutter/core/api/api_client.dart';
import 'package:aceedx_flutter/core/auth/auth_service.dart';
import 'package:aceedx_flutter/core/storage/session_storage.dart';
import 'package:aceedx_flutter/core/storage/storage_keys.dart';

const _testBase = 'https://deve.aceedx.com/api';

http.Response _ok(dynamic body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Response _err(int code, String message, {Map<String, dynamic>? errors}) {
  final body = <String, dynamic>{'message': message};
  if (errors != null) body['errors'] = errors;
  return http.Response(
    jsonEncode(body),
    code,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _NoNetworkClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw http.ClientException('Connection refused', request.url);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStorage storage;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SessionStorage(prefs);
  });

  AuthenticationService createService(http.Client mockClient) {
    final client = ApiClient(
      baseUrl: _testBase,
      httpClient: mockClient,
      sessionStorage: storage,
    );
    return AuthenticationService(
      apiClient: client,
      sessionStorage: storage,
    );
  }

  group('Day 1 Step 3E: Authentication Service Tests', () {
    // ─── 1. Successful teacher login ────────────────────────────────────────
    test('1. Successful teacher login', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'message': 'Login successful',
          'data': {
            'user': {
              'id': 42,
              'name': 'Teacher John',
              'email': 'teacher@example.com',
              'phone': '9876543210',
              'role': 'teacher',
              'roles': ['teacher'],
              'school_id': 87,
              'teacher_id': 12,
            },
            'token': 'auth_token_teacher_123',
            'token_type': 'Bearer',
          }
        });
      });

      final auth = createService(mock);
      final result = await auth.login(
        email: 'teacher@example.com',
        password: 'password123',
        role: 'teacher',
      );

      expect(result.success, isTrue);
      expect(result.isAuthenticated, isTrue);
      expect(result.selectedRole, equals('teacher'));
      expect(result.session!.userId, equals(42));
      expect(result.session!.schoolId, equals(87));
      expect(result.session!.teacherId, equals(12));
      expect(result.user!.name, equals('Teacher John'));
    });

    // ─── 2. Successful login for another role ───────────────────────────────
    test('2. Successful login for another role (school_admin)', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'message': 'Admin login successful',
          'data': {
            'user': {
              'id': 10,
              'name': 'Admin Jane',
              'email': 'admin@school.com',
              'role': 'school_admin',
              'roles': ['school_admin'],
              'school_id': 55,
            },
            'token': 'auth_token_admin_456',
          }
        });
      });

      final auth = createService(mock);
      final result = await auth.login(
        email: 'admin@school.com',
        password: 'adminPassword',
        role: 'school_admin',
      );

      expect(result.success, isTrue);
      expect(result.selectedRole, equals('school_admin'));
      expect(result.session!.userId, equals(10));
      expect(result.session!.schoolId, equals(55));
    });

    // ─── 3. Login sends email, password, role ───────────────────────────────
    test('3. Login request dispatches email, password, role in body', () async {
      Map<String, dynamic>? capturedBody;
      Uri? capturedUri;
      String? capturedMethod;

      final mock = MockClient((req) async {
        capturedUri = req.url;
        capturedMethod = req.method;
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _ok({
          'success': true,
          'data': {
            'user': {'id': 1, 'email': 'test@test.com'},
            'token': 'token123',
          }
        });
      });

      final auth = createService(mock);
      await auth.login(
        email: 'test@test.com',
        password: 'mySecretPassword',
        role: 'principal',
      );

      expect(capturedMethod, equals('POST'));
      expect(capturedUri.toString(), equals('https://deve.aceedx.com/api/auth/login'));
      expect(capturedBody!['email'], equals('test@test.com'));
      expect(capturedBody!['password'], equals('mySecretPassword'));
      expect(capturedBody!['role'], equals('principal'));
    });

    // ─── 4. Successful response token is stored ─────────────────────────────
    test('4. Successful response token is stored', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {'id': 1, 'email': 't@t.com'},
            'token': 'Bearer raw_jwt_token_999',
          }
        });
      });

      final auth = createService(mock);
      await auth.login(
        email: 't@t.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(auth.token, equals('raw_jwt_token_999'));
    });

    // ─── 5. Token is stored through SessionStorage ──────────────────────────
    test('5. Token is stored through SessionStorage', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {'id': 1, 'email': 't@t.com'},
            'token': 'session_storage_token_777',
          }
        });
      });

      final auth = createService(mock);
      await auth.login(
        email: 't@t.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(storage.getToken(), equals('session_storage_token_777'));
      expect(prefs.getString(StorageKeys.userToken), equals('session_storage_token_777'));
    });

    // ─── 6. selectedRole is stored ──────────────────────────────────────────
    test('6. selectedRole is stored in SessionStorage', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {'id': 1, 'email': 't@t.com'},
            'token': 'token123',
          }
        });
      });

      final auth = createService(mock);
      await auth.login(
        email: 't@t.com',
        password: 'pwd',
        role: 'super_admin',
      );

      expect(storage.getSelectedRole(), equals('super_admin'));
      expect(auth.currentRole, equals('super_admin'));
    });

    // ─── 7. isAuthenticated becomes true after login ────────────────────────
    test('7. isAuthenticated becomes true after successful login', () async {
      expect(storage.isAuthenticated(), isFalse);
      expect(storage.hasActiveSession(), isFalse);

      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {'id': 5, 'email': 'auth@test.com'},
            'token': 'tok_555',
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 'auth@test.com',
        password: 'pwd',
        role: 'student',
      );

      expect(res.isAuthenticated, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.hasActiveSession, isTrue);
    });

    // ─── 8. userId is extracted correctly ───────────────────────────────────
    test('8. userId is extracted correctly from response (string or int)', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {'id': '250', 'email': 'id@test.com'},
            'token': 'tok_id',
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 'id@test.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(res.session!.userId, equals(250));
      expect(auth.currentUserId, equals(250));
      expect(storage.getUserId(), equals(250));
    });

    // ─── 9. schoolId extracted from data.school_id ──────────────────────────
    test('9. schoolId is extracted from data.school_id', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'school_id': '87',
            'user': {'id': 1, 'email': 's@test.com'},
            'token': 'tok_s',
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 's@test.com',
        password: 'pwd',
        role: 'school_admin',
      );

      expect(res.session!.schoolId, equals(87));
      expect(auth.currentSchoolId, equals(87));
    });

    // ─── 10. schoolId falls back to data.user.school_id ─────────────────────
    test('10. schoolId falls back to data.user.school_id', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {'id': 1, 'email': 's@test.com', 'school_id': 99},
            'token': 'tok_s2',
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 's@test.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(res.session!.schoolId, equals(99));
      expect(auth.currentSchoolId, equals(99));
    });

    // ─── 11. Missing school_id results in null ──────────────────────────────
    test('11. Missing school_id results in null rather than a fabricated value', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {'id': 1, 'email': 'no_school@test.com'},
            'token': 'tok_noschool',
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 'no_school@test.com',
        password: 'pwd',
        role: 'super_admin',
      );

      expect(res.session!.schoolId, isNull);
      expect(auth.currentSchoolId, isNull);
    });

    // ─── 12. teacher_id extracted when available ────────────────────────────
    test('12. teacher_id is extracted when available', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {'id': 1, 'email': 't@test.com', 'teacher_id': '15'},
            'token': 'tok_t',
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 't@test.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(res.session!.teacherId, equals(15));
      expect(auth.currentTeacherId, equals(15));
    });

    // ─── 13. Backend roles are preserved/normalized ─────────────────────────
    test('13. Backend roles are preserved and normalized', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'user': {
              'id': 1,
              'email': 'roles@test.com',
              'roles': ['teacher', 'school_admin'],
            },
            'token': 'tok_r',
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 'roles@test.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(res.session!.userRoles, equals(['teacher', 'school_admin']));
      expect(storage.getRoles(), equals(['teacher', 'school_admin']));
    });

    // ─── 14. Missing token does NOT create authenticated session ────────────
    test('14. Missing token from successful response does NOT create authenticated session', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'message': 'OK',
          'data': {
            'user': {'id': 1, 'email': 'no_tok@test.com'},
            'token': '',
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 'no_tok@test.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(res.success, isFalse);
      expect(res.isAuthenticated, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(storage.getToken(), isNull);
    });

    // ─── 15. Invalid credentials (401) handled correctly ────────────────────
    test('15. Invalid credentials are handled correctly', () async {
      final mock = MockClient((req) async {
        return _err(401, 'Invalid credentials or role mismatch');
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 'wrong@test.com',
        password: 'wrongPassword',
        role: 'teacher',
      );

      expect(res.success, isFalse);
      expect(res.statusCode, equals(401));
      expect(res.message, contains('Invalid credentials'));
      expect(auth.isAuthenticated, isFalse);
    });

    // ─── 16. Validation errors (422) handled correctly ──────────────────────
    test('16. Validation errors are handled correctly', () async {
      final mock = MockClient((req) async {
        return _err(422, 'The given data was invalid.', errors: {
          'email': ['The email field is required.'],
          'password': ['The password must be at least 8 characters.'],
        });
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 'invalid',
        password: '123',
        role: 'teacher',
      );

      expect(res.success, isFalse);
      expect(res.statusCode, equals(422));
      expect(res.errorsFor('email'), contains('The email field is required.'));
      expect(res.errorsFor('password'), contains('The password must be at least 8 characters.'));
    });

    // ─── 17. Network error is handled correctly ─────────────────────────────
    test('17. Network error is handled correctly', () async {
      final auth = createService(_NoNetworkClient());
      final res = await auth.login(
        email: 'net@test.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(res.success, isFalse);
      expect(res.message, contains('client error'));
      expect(res.statusCode, equals(0));
      expect(auth.isAuthenticated, isFalse);
    });

    // ─── 18. Timeout handled correctly ──────────────────────────────────────
    test('18. Timeout is handled correctly', () async {
      final mock = MockClient((req) async {
        throw Exception('TimeoutException: connection timed out');
      });

      final auth = createService(mock);
      final res = await auth.login(
        email: 'time@test.com',
        password: 'pwd',
        role: 'teacher',
      );

      expect(res.success, isFalse);
      expect(res.message, contains('timed out'));
    });

    // ─── 19. Successful logout clears local session ─────────────────────────
    test('19. Successful logout clears local session', () async {
      // Setup active session
      await storage.setToken('logout_test_tok');
      await storage.setUserId(99);
      await storage.setIsAuthenticated(true);
      expect(storage.isAuthenticated(), isTrue);

      Uri? capturedUri;
      final mock = MockClient((req) async {
        capturedUri = req.url;
        return _ok({'success': true, 'message': 'Logged out'});
      });

      final auth = createService(mock);
      final res = await auth.logout();

      expect(res.success, isTrue);
      expect(capturedUri.toString(), equals('https://deve.aceedx.com/api/auth/logout'));
      expect(storage.getToken(), isNull);
      expect(storage.getUserId(), isNull);
      expect(storage.isAuthenticated(), isFalse);
    });

    // ─── 20. Logout API failure still clears local session ──────────────────
    test('20. Logout API failure still clears local session', () async {
      await storage.setToken('failed_api_logout_tok');
      await storage.setUserId(88);
      await storage.setIsAuthenticated(true);

      final mock = MockClient((req) async {
        return _err(500, 'Server Error during logout');
      });

      final auth = createService(mock);
      final res = await auth.logout();

      expect(res.success, isTrue);
      expect(storage.getToken(), isNull);
      expect(storage.getUserId(), isNull);
      expect(storage.isAuthenticated(), isFalse);
    });

    // ─── 21. restoreSession with no token returns unauthenticated ───────────
    test('21. restoreSession with no token returns unauthenticated', () async {
      final mock = MockClient((req) async => _ok({}));
      final auth = createService(mock);

      final res = await auth.restoreSession();

      expect(res.success, isFalse);
      expect(res.statusCode, equals(401));
      expect(res.isAuthenticated, isFalse);
    });

    // ─── 22. restoreSession with valid token uses profile endpoint ──────────
    test('22. restoreSession with valid token uses profile endpoint and updates user data', () async {
      await storage.setToken('restore_test_tok');
      await storage.setSelectedRole('teacher');

      final mock = MockClient((req) async {
        expect(req.url.path, contains('/auth/profile'));
        expect(req.headers['Authorization'], equals('Bearer restore_test_tok'));
        return _ok({
          'success': true,
          'data': {
            'id': 100,
            'name': 'Restored Name',
            'email': 'restored@example.com',
            'school_id': 33,
            'teacher_id': 7,
          }
        });
      });

      final auth = createService(mock);
      final res = await auth.restoreSession();

      expect(res.success, isTrue);
      expect(res.session!.userId, equals(100));
      expect(res.session!.userName, equals('Restored Name'));
      expect(res.session!.schoolId, equals(33));
      expect(res.session!.teacherId, equals(7));
      expect(res.session!.selectedRole, equals('teacher'));
    });

    // ─── 23. Unauthorized profile response clears the session ───────────────
    test('23. Unauthorized profile response clears the session', () async {
      await storage.setToken('expired_token_xyz');
      await storage.setUserId(50);
      await storage.setIsAuthenticated(true);

      final mock = MockClient((req) async {
        return _err(401, 'Unauthenticated.');
      });

      final auth = createService(mock);
      final res = await auth.restoreSession();

      expect(res.success, isFalse);
      expect(res.statusCode, equals(401));
      expect(storage.getToken(), isNull);
      expect(storage.getUserId(), isNull);
      expect(storage.isAuthenticated(), isFalse);
    });

    // ─── 24. No password or token written to logs ───────────────────────────
    test('24. No password or token written to source code logging', () {
      final authSrc = io.File('lib/core/auth/auth_service.dart').readAsStringSync();
      expect(authSrc.contains('print(password)'), isFalse);
      expect(authSrc.contains('print(token)'), isFalse);
      expect(authSrc.contains('print(rawToken)'), isFalse);
      expect(authSrc.contains("import 'dart:io'"), isFalse);

      final resultSrc = io.File('lib/core/auth/auth_result.dart').readAsStringSync();
      expect(resultSrc.contains("import 'dart:io'"), isFalse);
    });

    // ─── 25. getProfile convenience method ──────────────────────────────────
    test('25. getProfile returns parsed User or null when unauthenticated', () async {
      final mock = MockClient((req) async {
        return _ok({
          'success': true,
          'data': {
            'id': 12,
            'name': 'Profile User',
            'email': 'profile@test.com',
            'role': 'teacher',
          }
        });
      });

      final auth = createService(mock);
      // Unauthenticated
      expect(await auth.getProfile(), isNull);

      // Authenticated
      await storage.setToken('active_token');
      await storage.setIsAuthenticated(true);
      final user = await auth.getProfile();
      expect(user, isNotNull);
      expect(user!.id, equals(12));
      expect(user.name, equals('Profile User'));
    });
  });
}
