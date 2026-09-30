/// Centralized storage keys for AceEdx session and local persistence.
///
/// Ensures all storage key names are defined in a single location,
/// preventing typos and scattering of string literals.
abstract final class StorageKeys {
  // Modern AceEdx session keys
  static const String isAuthenticated = 'isAuthenticated';
  static const String userToken = 'userToken';
  static const String refreshToken = 'refreshToken';
  static const String userId = 'userId';
  static const String userName = 'userName';
  static const String userEmail = 'userEmail';
  static const String userPhone = 'userPhone';
  static const String userRoles = 'userRoles';
  static const String selectedRole = 'selectedRole';
  static const String schoolId = 'schoolId';
  static const String teacherId = 'teacherId';
  static const String schoolName = 'schoolName';
  static const String profilePhotoUrl = 'profilePhotoUrl';
  static const String childrenName = 'childrenName';

  // Legacy keys for backward compatibility with older Flutter/Web storage
  static const String legacyUserToken = 'aceedx_user_token';
  static const String legacyUserId = 'aceedx_user_id';
  static const String legacyUserEmail = 'aceedx_user_email';
  static const String legacySelectedRole = 'aceedx_selected_role';
  static const String legacyUserRoles = 'aceedx_user_roles';

  /// Complete set of AceEdx authentication & session storage keys.
  /// Used by [clearSession] to safely remove only AceEdx session data
  /// without resetting or clearing unrelated browser localStorage keys.
  static const Set<String> allSessionKeys = {
    isAuthenticated,
    userToken,
    refreshToken,
    userId,
    userName,
    userEmail,
    userPhone,
    userRoles,
    selectedRole,
    schoolId,
    teacherId,
    schoolName,
    profilePhotoUrl,
    childrenName,
    legacyUserToken,
    legacyUserId,
    legacyUserEmail,
    legacySelectedRole,
    legacyUserRoles,
  };
}
