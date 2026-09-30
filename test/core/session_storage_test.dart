import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aceedx_flutter/core/session/session_data.dart';
import 'package:aceedx_flutter/core/storage/session_storage.dart';
import 'package:aceedx_flutter/core/storage/storage_keys.dart';
import 'package:aceedx_flutter/core/storage/storage_value_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Day 1 Step 3D: Session Storage Foundation Tests', () {
    // ─── 1. Empty storage ───────────────────────────────────────────────────
    test('1. Empty storage returns empty SessionData', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      final session = storage.readSession();
      expect(session.isEmpty, isTrue);
      expect(session.hasToken, isFalse);
      expect(session.hasActiveSession, isFalse);
      expect(session.userId, isNull);
      expect(session.userToken, isNull);
      expect(storage.isAuthenticated(), isFalse);
    });

    // ─── 2. Save and read complete session ──────────────────────────────────
    test('2. Save and read a complete session', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      const completeSession = SessionData(
        isAuthenticated: true,
        userToken: 'token_xyz_123',
        refreshToken: 'refresh_xyz_456',
        userId: 101,
        userName: 'Piyush Sharma',
        userEmail: 'piyush@example.com',
        userPhone: '+919876543210',
        userRoles: ['teacher', 'school_admin'],
        selectedRole: 'teacher',
        schoolId: 87,
        teacherId: 12,
        schoolName: 'Delhi Public School',
        profilePhotoUrl: 'https://example.com/photo.jpg',
        childrenName: 'Aarav Sharma',
      );

      await storage.saveSession(completeSession);
      final retrieved = storage.readSession();

      expect(retrieved.isAuthenticated, isTrue);
      expect(retrieved.userToken, equals('token_xyz_123'));
      expect(retrieved.refreshToken, equals('refresh_xyz_456'));
      expect(retrieved.userId, equals(101));
      expect(retrieved.userName, equals('Piyush Sharma'));
      expect(retrieved.userEmail, equals('piyush@example.com'));
      expect(retrieved.userPhone, equals('+919876543210'));
      expect(retrieved.userRoles, equals(['teacher', 'school_admin']));
      expect(retrieved.selectedRole, equals('teacher'));
      expect(retrieved.schoolId, equals(87));
      expect(retrieved.teacherId, equals(12));
      expect(retrieved.schoolName, equals('Delhi Public School'));
      expect(retrieved.profilePhotoUrl, equals('https://example.com/photo.jpg'));
      expect(retrieved.childrenName, equals('Aarav Sharma'));
      expect(retrieved.hasToken, isTrue);
      expect(retrieved.hasActiveSession, isTrue);
      expect(storage.isAuthenticated(), isTrue);
    });

    // ─── 3. String numeric values converted to integers ─────────────────────
    test('3. String numeric values: userId="250", schoolId="87", teacherId="123" correctly become integers', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userId: '250',
        StorageKeys.schoolId: '87',
        StorageKeys.teacherId: ' 123 ',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      expect(storage.getUserId(), equals(250));
      expect(storage.getSchoolId(), equals(87));
      expect(storage.getTeacherId(), equals(123));

      final session = storage.readSession();
      expect(session.userId, equals(250));
      expect(session.schoolId, equals(87));
      expect(session.teacherId, equals(123));
    });

    // ─── 4. Actual integer values remain integers ───────────────────────────
    test('4. Actual integer values remain integers', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userId: 42,
        StorageKeys.schoolId: 99,
        StorageKeys.teacherId: 10,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      expect(storage.getUserId(), equals(42));
      expect(storage.getSchoolId(), equals(99));
      expect(storage.getTeacherId(), equals(10));
    });

    // ─── 5. Invalid numeric values return null instead of throwing ──────────
    test('5. Invalid numeric values return null instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userId: 'not_a_number',
        StorageKeys.schoolId: 'xyz#%',
        StorageKeys.teacherId: '',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      expect(storage.getUserId(), isNull);
      expect(storage.getSchoolId(), isNull);
      expect(storage.getTeacherId(), isNull);

      final session = storage.readSession();
      expect(session.userId, isNull);
      expect(session.schoolId, isNull);
      expect(session.teacherId, isNull);
    });

    // ─── 6. Boolean conversions work safely ─────────────────────────────────
    test('6. Boolean conversions work safely for bool, string, and number representations', () {
      expect(StorageValueParser.parseBool(true), isTrue);
      expect(StorageValueParser.parseBool(false), isFalse);
      expect(StorageValueParser.parseBool('true'), isTrue);
      expect(StorageValueParser.parseBool('TRUE'), isTrue);
      expect(StorageValueParser.parseBool('True'), isTrue);
      expect(StorageValueParser.parseBool('false'), isFalse);
      expect(StorageValueParser.parseBool('FALSE'), isFalse);
      expect(StorageValueParser.parseBool('1'), isTrue);
      expect(StorageValueParser.parseBool(1), isTrue);
      expect(StorageValueParser.parseBool('0'), isFalse);
      expect(StorageValueParser.parseBool(0), isFalse);
      expect(StorageValueParser.parseBool('yes'), isTrue);
      expect(StorageValueParser.parseBool('no'), isFalse);
      expect(StorageValueParser.parseBool('invalid_bool'), isNull);
      expect(StorageValueParser.parseBool(null), isNull);
      expect(StorageValueParser.parseBool(123), isNull);
    });

    // ─── 7. userRoles can be saved/read correctly ───────────────────────────
    test('7. userRoles can be saved/read correctly from List, JSON, and CSV', () async {
      // Direct list
      SharedPreferences.setMockInitialValues({
        StorageKeys.userRoles: ['teacher', 'principal'],
      });
      var prefs = await SharedPreferences.getInstance();
      var storage = SessionStorage(prefs);
      expect(storage.getRoles(), equals(['teacher', 'principal']));

      // JSON string
      SharedPreferences.setMockInitialValues({
        StorageKeys.userRoles: '["super_admin", "school_admin"]',
      });
      prefs = await SharedPreferences.getInstance();
      storage = SessionStorage(prefs);
      expect(storage.getRoles(), equals(['super_admin', 'school_admin']));

      // Comma-separated string
      SharedPreferences.setMockInitialValues({
        StorageKeys.userRoles: 'student, parent',
      });
      prefs = await SharedPreferences.getInstance();
      storage = SessionStorage(prefs);
      expect(storage.getRoles(), equals(['student', 'parent']));
    });

    // ─── 8. Empty/missing optional values handled correctly ─────────────────
    test('8. Empty/missing optional values are handled correctly', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userToken: 'token_abc',
        StorageKeys.userId: 5,
        StorageKeys.userName: '   ',
        StorageKeys.userEmail: 'null',
        StorageKeys.childrenName: 'undefined',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      final session = storage.readSession();
      expect(session.userToken, equals('token_abc'));
      expect(session.userId, equals(5));
      expect(session.userName, isNull);
      expect(session.userEmail, isNull);
      expect(session.childrenName, isNull);
      expect(session.schoolName, isNull);
      expect(session.profilePhotoUrl, isNull);
    });

    // ─── 9. Token: "abc123" remains "abc123" ────────────────────────────────
    test('9. Token: "abc123" remains "abc123"', () {
      expect(StorageValueParser.normalizeToken('abc123'), equals('abc123'));
    });

    // ─── 10. Token: "Bearer abc123" becomes "abc123" ────────────────────────
    test('10. Token: "Bearer abc123" becomes "abc123"', () {
      expect(
          StorageValueParser.normalizeToken('Bearer abc123'), equals('abc123'));
    });

    // ─── 11. Token: "bearer abc123" becomes "abc123" ────────────────────────
    test('11. Token: "bearer abc123" becomes "abc123"', () {
      expect(
          StorageValueParser.normalizeToken('bearer abc123'), equals('abc123'));
    });

    // ─── 12. Token with surrounding whitespace is normalized ────────────────
    test('12. Token with surrounding whitespace is normalized', () {
      expect(StorageValueParser.normalizeToken('   Bearer   abc123   '),
          equals('abc123'));
      expect(StorageValueParser.normalizeToken('  abc123  '), equals('abc123'));
      expect(StorageValueParser.normalizeToken('Bearer Bearer abc123'),
          equals('abc123'));
    });

    // ─── 13. Empty token becomes null ───────────────────────────────────────
    test('13. Empty token becomes null', () {
      expect(StorageValueParser.normalizeToken(''), isNull);
      expect(StorageValueParser.normalizeToken('   '), isNull);
      expect(StorageValueParser.normalizeToken('null'), isNull);
      expect(StorageValueParser.normalizeToken('undefined'), isNull);
      expect(StorageValueParser.normalizeToken(null), isNull);
    });

    // ─── 14. Modern userToken is preferred ──────────────────────────────────
    test('14. Modern userToken is preferred over legacy token', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userToken: 'modern_token_999',
        StorageKeys.legacyUserToken: 'legacy_token_111',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      expect(storage.getToken(), equals('modern_token_999'));
    });

    // ─── 15. Legacy aceedx_user_token works when userToken is absent ────────
    test('15. Legacy aceedx_user_token works when modern userToken is absent', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.legacyUserToken: 'Bearer legacy_token_111',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      expect(storage.getToken(), equals('legacy_token_111'));
      // Verifies reading legacy token does NOT delete the legacy key
      expect(prefs.getString(StorageKeys.legacyUserToken),
          equals('Bearer legacy_token_111'));
    });

    // ─── 16. clearSession removes all AceEdx session keys ───────────────────
    test('16. clearSession removes all AceEdx session keys', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.isAuthenticated: true,
        StorageKeys.userToken: 'token123',
        StorageKeys.refreshToken: 'refresh123',
        StorageKeys.userId: 50,
        StorageKeys.userName: 'Test User',
        StorageKeys.userEmail: 'test@example.com',
        StorageKeys.userPhone: '1234567890',
        StorageKeys.userRoles: ['teacher'],
        StorageKeys.selectedRole: 'teacher',
        StorageKeys.schoolId: 10,
        StorageKeys.teacherId: 2,
        StorageKeys.schoolName: 'Test School',
        StorageKeys.profilePhotoUrl: 'https://example.com/p.png',
        StorageKeys.childrenName: 'Test Child',
        StorageKeys.legacyUserToken: 'legacy123',
        StorageKeys.legacyUserId: '50',
        StorageKeys.legacyUserEmail: 'test@example.com',
        StorageKeys.legacySelectedRole: 'teacher',
        StorageKeys.legacyUserRoles: 'teacher',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      await storage.clearSession();

      for (final key in StorageKeys.allSessionKeys) {
        expect(prefs.containsKey(key), isFalse,
            reason: 'Key $key should have been removed by clearSession');
      }

      final session = storage.readSession();
      expect(session.isEmpty, isTrue);
    });

    // ─── 17. clearSession does NOT remove unrelated test key ────────────────
    test('17. clearSession does NOT remove an unrelated test key', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userToken: 'token123',
        StorageKeys.userId: 1,
        'app_theme_mode': 'dark',
        'custom_analytics_id': 'analytics_9988',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      await storage.clearSession();

      expect(prefs.containsKey(StorageKeys.userToken), isFalse);
      expect(prefs.containsKey(StorageKeys.userId), isFalse);
      // Unrelated keys MUST remain untouched
      expect(prefs.getString('app_theme_mode'), equals('dark'));
      expect(prefs.getString('custom_analytics_id'), equals('analytics_9988'));
    });

    // ─── 18. Corrupted storage does not throw ───────────────────────────────
    test('18. Corrupted storage does not throw during session read', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.userRoles: '{{{corrupted json',
        StorageKeys.userId: 'corrupted_id',
        StorageKeys.schoolId: 'corrupted_school',
        StorageKeys.isAuthenticated: 'unknown_state',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      expect(() => storage.readSession(), returnsNormally);
      final session = storage.readSession();
      expect(session.userId, isNull);
      expect(session.schoolId, isNull);
      expect(session.userRoles, isNull);
    });

    // ─── 19. No sensitive values are written to logs ────────────────────────
    test('19. SessionData.toString masks token and does not leak full credentials', () {
      const session = SessionData(
        userToken: 'secret_jwt_token_1234567890_abcdef',
        userId: 77,
        selectedRole: 'teacher',
      );

      final str = session.toString();
      expect(str, contains('secr...cdef'));
      expect(str.contains('secret_jwt_token_1234567890_abcdef'), isFalse);
    });

    // ─── 20. Token requirement for isAuthenticated ─────────────────────────
    test('20. isAuthenticated requires non-empty token even if isAuthenticated flag is true in storage', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.isAuthenticated: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      expect(storage.isAuthenticated(), isFalse);
    });
  });
}
