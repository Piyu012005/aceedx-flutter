import 'package:shared_preferences/shared_preferences.dart';

import '../session/session_data.dart';
import 'storage_keys.dart';
import 'storage_value_parser.dart';

/// Type-safe Session Storage layer for AceEdx Flutter Web.
///
/// Handles:
/// 1. Type conversion resilience (e.g. `String` `"250"` -> `int` `250`).
/// 2. Modern and legacy (`aceedx_user_token`) storage keys.
/// 3. Canonical Bearer token normalization.
/// 4. Safe session clearance (removes only AceEdx session keys).
/// 5. Single source of truth for authentication tokens.
class SessionStorage {
  final SharedPreferences _prefs;

  SessionStorage(this._prefs);

  /// Initializes SessionStorage asynchronously using [SharedPreferences.getInstance].
  static Future<SessionStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionStorage(prefs);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // High-Level Session API
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads and constructs a typed [SessionData] snapshot from storage.
  ///
  /// Safely converts all raw storage types and falls back to legacy keys
  /// when modern keys are not found. Never throws on corrupted data.
  SessionData readSession() {
    try {
      final token = getToken();
      final refresh = getRefreshToken();
      final userId = getUserId();
      final name = getUserName();
      final email = getUserEmail();
      final phone = getUserPhone();
      final roles = getRoles();
      final role = getSelectedRole();
      final schoolId = getSchoolId();
      final teacherId = getTeacherId();
      final schoolName = getSchoolName();
      final photo = getProfilePhotoUrl();
      final children = getChildrenName();
      final isAuth = _readIsAuthenticatedRaw();

      return SessionData(
        isAuthenticated: isAuth ?? (token != null && token.isNotEmpty ? true : null),
        userToken: token,
        refreshToken: refresh,
        userId: userId,
        userName: name,
        userEmail: email,
        userPhone: phone,
        userRoles: roles,
        selectedRole: role,
        schoolId: schoolId,
        teacherId: teacherId,
        schoolName: schoolName,
        profilePhotoUrl: photo,
        childrenName: children,
      );
    } catch (_) {
      return SessionData.empty;
    }
  }

  /// Saves complete session data into storage.
  Future<void> saveSession(SessionData session) async {
    if (session.userToken != null) {
      await setToken(session.userToken);
    }
    if (session.refreshToken != null) {
      await setRefreshToken(session.refreshToken);
    }
    if (session.userId != null) {
      await setUserId(session.userId);
    }
    if (session.userName != null) {
      await setUserName(session.userName);
    }
    if (session.userEmail != null) {
      await setUserEmail(session.userEmail);
    }
    if (session.userPhone != null) {
      await setUserPhone(session.userPhone);
    }
    if (session.userRoles != null) {
      await setRoles(session.userRoles);
    }
    if (session.selectedRole != null) {
      await setSelectedRole(session.selectedRole);
    }
    if (session.schoolId != null) {
      await setSchoolId(session.schoolId);
    }
    if (session.teacherId != null) {
      await setTeacherId(session.teacherId);
    }
    if (session.schoolName != null) {
      await setSchoolName(session.schoolName);
    }
    if (session.profilePhotoUrl != null) {
      await setProfilePhotoUrl(session.profilePhotoUrl);
    }
    if (session.childrenName != null) {
      await setChildrenName(session.childrenName);
    }
    if (session.isAuthenticated != null) {
      await setIsAuthenticated(session.isAuthenticated!);
    } else {
      await setIsAuthenticated(session.hasToken);
    }
  }

  /// Updates existing session state via a transform callback.
  Future<SessionData> updateSession(
    SessionData Function(SessionData current) updater,
  ) async {
    final current = readSession();
    final updated = updater(current);
    await saveSession(updated);
    return updated;
  }

  /// Removes ONLY AceEdx session and authentication keys from storage.
  ///
  /// Unrelated application or browser localStorage keys remain untouched.
  Future<void> clearSession() async {
    for (final key in StorageKeys.allSessionKeys) {
      await _prefs.remove(key);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Token Management & Normalization
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads and normalizes the active Bearer token.
  ///
  /// 1. Checks modern [StorageKeys.userToken].
  /// 2. If absent, falls back to legacy [StorageKeys.legacyUserToken].
  /// 3. Normalizes token (stripping any `Bearer ` prefix).
  ///
  /// Returns `null` if no valid token exists.
  String? getToken() {
    try {
      final modernVal = _prefs.get(StorageKeys.userToken);
      final normalizedModern = StorageValueParser.normalizeToken(modernVal);
      if (normalizedModern != null) {
        return normalizedModern;
      }

      final legacyVal = _prefs.get(StorageKeys.legacyUserToken);
      final normalizedLegacy = StorageValueParser.normalizeToken(legacyVal);
      if (normalizedLegacy != null) {
        return normalizedLegacy;
      }
    } catch (_) {}
    return null;
  }

  /// Saves the active authentication token (automatically normalized).
  ///
  /// If [token] is `null` or empty, removes the token key.
  Future<bool> setToken(String? token) async {
    final normalized = StorageValueParser.normalizeToken(token);
    if (normalized == null) {
      return _prefs.remove(StorageKeys.userToken);
    }
    return _prefs.setString(StorageKeys.userToken, normalized);
  }

  /// Gets the refresh token if stored.
  String? getRefreshToken() {
    try {
      final val = _prefs.get(StorageKeys.refreshToken);
      return StorageValueParser.parseString(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears the refresh token.
  Future<bool> setRefreshToken(String? token) async {
    final parsed = StorageValueParser.parseString(token);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.refreshToken);
    }
    return _prefs.setString(StorageKeys.refreshToken, parsed);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Authentication & Identity Getters/Setters
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns whether the user is currently authenticated.
  ///
  /// Checks explicit [StorageKeys.isAuthenticated] flag, or falls back to
  /// checking whether a valid non-empty token is present.
  bool isAuthenticated() {
    final token = getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    try {
      final val = _prefs.get(StorageKeys.isAuthenticated);
      final parsed = StorageValueParser.parseBool(val);
      if (parsed != null) return parsed;
    } catch (_) {}
    return true;
  }

  bool? _readIsAuthenticatedRaw() {
    try {
      final val = _prefs.get(StorageKeys.isAuthenticated);
      return StorageValueParser.parseBool(val);
    } catch (_) {}
    return null;
  }

  /// Sets the authentication status flag.
  Future<bool> setIsAuthenticated(bool authenticated) {
    return _prefs.setBool(StorageKeys.isAuthenticated, authenticated);
  }

  /// Gets user ID safely handling type variations (`int`, `String`, etc.).
  int? getUserId() {
    try {
      final val = _prefs.get(StorageKeys.userId) ??
          _prefs.get(StorageKeys.legacyUserId);
      return StorageValueParser.parseInt(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears the user ID.
  Future<bool> setUserId(int? userId) {
    if (userId == null) {
      return _prefs.remove(StorageKeys.userId);
    }
    return _prefs.setInt(StorageKeys.userId, userId);
  }

  /// Gets school ID safely handling type variations.
  int? getSchoolId() {
    try {
      final val = _prefs.get(StorageKeys.schoolId);
      return StorageValueParser.parseInt(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears the school ID.
  Future<bool> setSchoolId(int? schoolId) {
    if (schoolId == null) {
      return _prefs.remove(StorageKeys.schoolId);
    }
    return _prefs.setInt(StorageKeys.schoolId, schoolId);
  }

  /// Gets teacher ID safely handling type variations.
  int? getTeacherId() {
    try {
      final val = _prefs.get(StorageKeys.teacherId);
      return StorageValueParser.parseInt(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears the teacher ID.
  Future<bool> setTeacherId(int? teacherId) {
    if (teacherId == null) {
      return _prefs.remove(StorageKeys.teacherId);
    }
    return _prefs.setInt(StorageKeys.teacherId, teacherId);
  }

  /// Gets selected user role (e.g. `'teacher'`, `'school_admin'`).
  String? getSelectedRole() {
    try {
      final val = _prefs.get(StorageKeys.selectedRole) ??
          _prefs.get(StorageKeys.legacySelectedRole);
      return StorageValueParser.parseString(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears selected user role.
  Future<bool> setSelectedRole(String? role) {
    final parsed = StorageValueParser.parseString(role);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.selectedRole);
    }
    return _prefs.setString(StorageKeys.selectedRole, parsed);
  }

  /// Gets assigned user roles safely.
  List<String>? getRoles() {
    try {
      final val = _prefs.get(StorageKeys.userRoles) ??
          _prefs.get(StorageKeys.legacyUserRoles);
      return StorageValueParser.parseStringList(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears assigned user roles.
  Future<bool> setRoles(List<String>? roles) {
    final parsed = StorageValueParser.parseStringList(roles);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.userRoles);
    }
    return _prefs.setStringList(StorageKeys.userRoles, parsed);
  }

  /// Gets user display name.
  String? getUserName() {
    try {
      final val = _prefs.get(StorageKeys.userName);
      return StorageValueParser.parseString(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears user display name.
  Future<bool> setUserName(String? name) {
    final parsed = StorageValueParser.parseString(name);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.userName);
    }
    return _prefs.setString(StorageKeys.userName, parsed);
  }

  /// Gets user email.
  String? getUserEmail() {
    try {
      final val = _prefs.get(StorageKeys.userEmail) ??
          _prefs.get(StorageKeys.legacyUserEmail);
      return StorageValueParser.parseString(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears user email.
  Future<bool> setUserEmail(String? email) {
    final parsed = StorageValueParser.parseString(email);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.userEmail);
    }
    return _prefs.setString(StorageKeys.userEmail, parsed);
  }

  /// Gets user phone number.
  String? getUserPhone() {
    try {
      final val = _prefs.get(StorageKeys.userPhone);
      return StorageValueParser.parseString(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears user phone number.
  Future<bool> setUserPhone(String? phone) {
    final parsed = StorageValueParser.parseString(phone);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.userPhone);
    }
    return _prefs.setString(StorageKeys.userPhone, parsed);
  }

  /// Gets school name.
  String? getSchoolName() {
    try {
      final val = _prefs.get(StorageKeys.schoolName);
      return StorageValueParser.parseString(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears school name.
  Future<bool> setSchoolName(String? name) {
    final parsed = StorageValueParser.parseString(name);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.schoolName);
    }
    return _prefs.setString(StorageKeys.schoolName, parsed);
  }

  /// Gets profile photo URL.
  String? getProfilePhotoUrl() {
    try {
      final val = _prefs.get(StorageKeys.profilePhotoUrl);
      return StorageValueParser.parseString(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears profile photo URL.
  Future<bool> setProfilePhotoUrl(String? url) {
    final parsed = StorageValueParser.parseString(url);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.profilePhotoUrl);
    }
    return _prefs.setString(StorageKeys.profilePhotoUrl, parsed);
  }

  /// Gets children name (for parent accounts).
  String? getChildrenName() {
    try {
      final val = _prefs.get(StorageKeys.childrenName);
      return StorageValueParser.parseString(val);
    } catch (_) {}
    return null;
  }

  /// Sets or clears children name.
  Future<bool> setChildrenName(String? name) {
    final parsed = StorageValueParser.parseString(name);
    if (parsed == null) {
      return _prefs.remove(StorageKeys.childrenName);
    }
    return _prefs.setString(StorageKeys.childrenName, parsed);
  }

  /// Convenience check if an active session exists with both a valid token and user ID.
  bool hasActiveSession() {
    final token = getToken();
    final userId = getUserId();
    return token != null && token.isNotEmpty && userId != null;
  }
}
