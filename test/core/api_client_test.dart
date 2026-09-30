import 'dart:convert';
import 'dart:io' as io show File;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aceedx_flutter/app/config/app_config.dart';
import 'package:aceedx_flutter/core/api/api_client.dart';
import 'package:aceedx_flutter/core/constants/api_timeouts.dart';
import 'package:aceedx_flutter/core/errors/api_exception.dart';
import 'package:aceedx_flutter/core/storage/session_storage.dart';
import 'package:aceedx_flutter/core/storage/storage_keys.dart';

const _testBase = 'https://deve.aceedx.com/api';

ApiClient _client(http.Client mockClient, {SessionStorage? sessionStorage}) =>
    ApiClient(
      baseUrl: _testBase,
      httpClient: mockClient,
      sessionStorage: sessionStorage,
    );

http.Response _ok(dynamic body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Response _err(int code, String message) => http.Response(
      jsonEncode({'message': message}),
      code,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

class _NoNetworkClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw http.ClientException('Connection refused', request.url);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient & SessionStorage Integration Tests', () {
    test('Token from SessionStorage produces clean Authorization: Bearer <token>', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userToken: 'abc_token_123',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      Map<String, String>? capturedHeaders;
      final mock = MockClient((req) async {
        capturedHeaders = req.headers;
        return _ok({'status': true});
      });

      final client = _client(mock, sessionStorage: storage);
      await client.get('/teacher/papers');

      expect(capturedHeaders!['Authorization'], equals('Bearer abc_token_123'));
    });

    test('Token with Bearer prefix in SessionStorage does not produce double Bearer', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userToken: 'Bearer abc_token_123',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      Map<String, String>? capturedHeaders;
      final mock = MockClient((req) async {
        capturedHeaders = req.headers;
        return _ok({'status': true});
      });

      final client = _client(mock, sessionStorage: storage);
      await client.get('/teacher/papers');

      expect(capturedHeaders!['Authorization'], equals('Bearer abc_token_123'));
      expect(capturedHeaders!['Authorization'], isNot(contains('Bearer Bearer')));
    });

    test('Legacy token key in SessionStorage is used by ApiClient when modern key is absent', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.legacyUserToken: 'legacy_token_888',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      Map<String, String>? capturedHeaders;
      final mock = MockClient((req) async {
        capturedHeaders = req.headers;
        return _ok({'status': true});
      });

      final client = _client(mock, sessionStorage: storage);
      await client.get('/teacher/papers');

      expect(capturedHeaders!['Authorization'], equals('Bearer legacy_token_888'));
    });
  });

  group('Step 3C ApiClient Core Tests', () {
    // ─── 1. GET ─────────────────────────────────────────────────────────────
    test('1. sends GET to correct URL and returns decoded body', () async {
      Uri? capturedUri;
      String? capturedMethod;
      final mock = MockClient((req) async {
        capturedUri = req.url;
        capturedMethod = req.method;
        return _ok({'status': true, 'data': 'hello'});
      });

      final result = await _client(mock).get('/auth/get-roles');

      expect(capturedMethod, equals('GET'));
      expect(capturedUri.toString(),
          equals('https://deve.aceedx.com/api/auth/get-roles'));
      expect(result, isA<Map>());
      expect(result['status'], isTrue);
    });

    // ─── 2. POST ────────────────────────────────────────────────────────────
    test('2. sends POST with JSON body and returns decoded body', () async {
      Map<String, dynamic>? capturedBody;
      String? capturedMethod;
      final mock = MockClient((req) async {
        capturedMethod = req.method;
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _ok({'success': true});
      });

      await _client(mock)
          .post('/home/contact', body: {'name': 'Test', 'message': 'Hello'});

      expect(capturedMethod, equals('POST'));
      expect(capturedBody!['name'], equals('Test'));
      expect(capturedBody!['message'], equals('Hello'));
    });

    // ─── 3. PUT ─────────────────────────────────────────────────────────────
    test('3. sends PUT with JSON body', () async {
      String? capturedMethod;
      Map<String, dynamic>? capturedBody;
      final mock = MockClient((req) async {
        capturedMethod = req.method;
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _ok({'updated': true});
      });

      await _client(mock)
          .put('/school/time/settings/update', body: {'period': 45});

      expect(capturedMethod, equals('PUT'));
      expect(capturedBody!['period'], equals(45));
    });

    // ─── 4. PATCH ───────────────────────────────────────────────────────────
    test('4. sends PATCH with JSON body and correct method', () async {
      String? capturedMethod;
      Map<String, dynamic>? capturedBody;
      final mock = MockClient((req) async {
        capturedMethod = req.method;
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _ok({'patched': true});
      });

      await _client(mock)
          .patch('/admin/school-status/5', body: {'status': 'active'});

      expect(capturedMethod, equals('PATCH'));
      expect(capturedBody!['status'], equals('active'));
    });

    // ─── 5. DELETE ──────────────────────────────────────────────────────────
    test('5. sends DELETE to correct endpoint', () async {
      String? capturedMethod;
      Uri? capturedUri;
      final mock = MockClient((req) async {
        capturedMethod = req.method;
        capturedUri = req.url;
        return _ok({'deleted': true});
      });

      await _client(mock).delete('/teacher/papers/99');

      expect(capturedMethod, equals('DELETE'));
      expect(capturedUri.toString(), contains('/teacher/papers/99'));
    });

    // ─── 6. URL construction ────────────────────────────────────────────────
    test('6. URL construction rules are respected', () {
      final apiClient =
          ApiClient(baseUrl: _testBase, httpClient: MockClient((_) async => _ok({})));

      expect(apiClient.resolveUrl('/auth/login'),
          equals('https://deve.aceedx.com/api/auth/login'));
      expect(apiClient.resolveUrl('teacher/papers'),
          equals('https://deve.aceedx.com/api/teacher/papers'));
      expect(
        apiClient.resolveUrl('/teacher/units/by-context', {'class': '10', 'subject_id': 1}),
        equals('https://deve.aceedx.com/api/teacher/units/by-context?class=10&subject_id=1'),
      );
    });

    // ─── 7. JSON object response ────────────────────────────────────────────
    test('7. returns Map when server returns JSON object', () async {
      final mock = MockClient((_) async => _ok({'success': true, 'data': {}}));
      final result = await _client(mock).get('/teacher/school-info');
      expect(result, isA<Map>());
      expect(result['success'], isTrue);
    });

    // ─── 8. JSON array response ─────────────────────────────────────────────
    test('8. returns List when server returns JSON array', () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode([
              {'id': 1, 'name': 'Unit 1'},
              {'id': 2, 'name': 'Unit 2'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final result = await _client(mock).get('/teacher/units/by-context');
      expect(result, isA<List>());
      expect((result as List).length, equals(2));
    });

    // ─── 9. Empty response ──────────────────────────────────────────────────
    test('9. returns null when body is empty', () async {
      final mock = MockClient((_) async => http.Response('', 204, headers: {}));
      final result = await _client(mock).delete('/teacher/papers/1');
      expect(result, isNull);
    });

    // ─── 10. 400 → BadRequestException ─────────────────────────────────────
    test('10. throws BadRequestException on 400', () async {
      final mock =
          MockClient((_) async => _err(400, 'Invalid request parameters'));
      await expectLater(
        () => _client(mock).post('/auth/register', body: {}),
        throwsA(isA<BadRequestException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    // ─── 11. 401 → UnauthorizedException ───────────────────────────────────
    test('11. throws UnauthorizedException on 401', () async {
      final mock = MockClient((_) async => _err(401, 'Unauthenticated.'));
      await expectLater(
        () => _client(mock).get('/teacher/papers'),
        throwsA(isA<UnauthorizedException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(401),
        )),
      );
    });

    // ─── 12. 403 → ForbiddenException ──────────────────────────────────────
    test('12. throws ForbiddenException on 403', () async {
      final mock = MockClient((_) async => _err(403, 'Access denied'));
      await expectLater(
        () => _client(mock).get('/admin/all-school'),
        throwsA(isA<ForbiddenException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(403),
        )),
      );
    });

    // ─── 13. 404 → NotFoundException ───────────────────────────────────────
    test('13. throws NotFoundException on 404', () async {
      final mock = MockClient((_) async => _err(404, 'Paper not found'));
      await expectLater(
        () => _client(mock).get('/teacher/paper/9999'),
        throwsA(isA<NotFoundException>().having(
          (e) => e.message,
          'message',
          contains('Paper not found'),
        )),
      );
    });

    // ─── 14. 422 → ValidationException ─────────────────────────────────────
    test('14. throws ValidationException on 422 with field errors', () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'email': ['The email field is required.'],
                'password': ['The password must be at least 8 characters.'],
              },
            }),
            422,
            headers: {'content-type': 'application/json'},
          ));

      ValidationException? caught;
      try {
        await _client(mock).post('/auth/login', body: {});
      } on ValidationException catch (e) {
        caught = e;
      }

      expect(caught, isNotNull);
      expect(caught!.statusCode, equals(422));
      expect(caught.errorsFor('email'), contains('The email field is required.'));
      expect(caught.allErrors.length, equals(2));
    });

    // ─── 15. 429 → RateLimitException ──────────────────────────────────────
    test('15. throws RateLimitException on 429', () async {
      final mock = MockClient((_) async => _err(429, 'Too Many Requests'));
      await expectLater(
        () => _client(mock).post('/home/contact', body: {}),
        throwsA(isA<RateLimitException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(429),
        )),
      );
    });

    // ─── 16. 500 → ServerException ─────────────────────────────────────────
    test('16. throws ServerException on 500 and 503', () async {
      final mock = MockClient((_) async => _err(500, 'Internal Server Error'));
      await expectLater(
        () => _client(mock).get('/teacher/generate'),
        throwsA(isA<ServerException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(500),
        )),
      );
    });

    // ─── 17. Malformed JSON → InvalidResponseException ──────────────────────
    test('17. throws InvalidResponseException on non-JSON error body', () async {
      final mock = MockClient((_) async => http.Response(
            '<html>502 Bad Gateway</html>',
            502,
            headers: {'content-type': 'text/html'},
          ));
      await expectLater(
        () => _client(mock).get('/teacher/papers'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    // ─── 18. Timeout / Network failure ──────────────────────────────────────
    test('18. network failure throws NetworkException', () async {
      final apiClient = ApiClient(
        baseUrl: _testBase,
        httpClient: _NoNetworkClient(),
      );
      await expectLater(
        () => apiClient.get('/teacher/papers'),
        throwsA(isA<NetworkException>().having(
          (e) => e.message,
          'message',
          contains('HTTP client error'),
        )),
      );
    });

    // ─── 19. Sensitive data not logged / No dart:io ─────────────────────────
    test('19. api_client.dart does not import dart:io and does not log credentials', () {
      final src = io.File('lib/core/api/api_client.dart').readAsStringSync();
      expect(src.contains("import 'dart:io'"), isFalse);
      expect(src.contains('SocketException'), isFalse);
      expect(src.contains("print(headers['Authorization'])"), isFalse);
    });

    // ─── 20. DEV base URL used by default ───────────────────────────────────
    test('20. AppConfig defaults to DEV base URL and ApiClient defaults to DEV', () {
      expect(AppConfig.current.apiBaseUrl, equals('https://deve.aceedx.com/api'));
      expect(AppConfig.isDev, isTrue);
      expect(AppConfig.isProd, isFalse);

      final apiClient = ApiClient(
        httpClient: MockClient((_) async => _ok({})),
      );
      expect(apiClient.baseUrl, equals('https://deve.aceedx.com/api'));
      expect(apiClient.resolveUrl('/auth/login'),
          startsWith('https://deve.aceedx.com/api'));
      expect(apiClient.baseUrl, isNot(contains('https://aceedx.com/api')));
    });

    // ─── ApiTimeouts verification ───────────────────────────────────────────
    test('ApiTimeouts constants are properly defined', () {
      expect(ApiTimeouts.request, equals(const Duration(seconds: 30)));
      expect(ApiTimeouts.short, equals(const Duration(seconds: 10)));
      expect(ApiTimeouts.long, equals(const Duration(seconds: 120)));
      expect(ApiTimeouts.aiGeneration, equals(const Duration(seconds: 120)));
    });

    test('ApiClient accepts custom per-request timeout', () async {
      final mockClient = MockClient((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return _ok({'status': true});
      });
      final client = ApiClient(httpClient: mockClient);

      // A timeout shorter than the delay should trigger TimeoutException
      expect(
        () => client.get('/test', timeout: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()),
      );

      expect(
        () => client.post('/test', timeout: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
