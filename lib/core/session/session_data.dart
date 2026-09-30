import 'package:flutter/foundation.dart';

/// Immutable snapshot representing an active or restored user session.
///
/// Designed to be resilient against partial, absent, or legacy browser storage values.
/// All fields are nullable to avoid forcing non-null assumptions when data is absent.
@immutable
class SessionData {
  final bool? isAuthenticated;
  final String? userToken;
  final String? refreshToken;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final List<String>? userRoles;
  final String? selectedRole;
  final int? schoolId;
  final int? teacherId;
  final String? schoolName;
  final String? profilePhotoUrl;
  final String? childrenName;

  const SessionData({
    this.isAuthenticated,
    this.userToken,
    this.refreshToken,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userRoles,
    this.selectedRole,
    this.schoolId,
    this.teacherId,
    this.schoolName,
    this.profilePhotoUrl,
    this.childrenName,
  });

  /// Empty session snapshot.
  static const SessionData empty = SessionData();

  /// Whether a valid non-empty userToken exists in the session.
  bool get hasToken => userToken != null && userToken!.trim().isNotEmpty;

  /// Whether the session represents an active authenticated user.
  bool get hasActiveSession =>
      (isAuthenticated == true || hasToken) && userId != null;

  /// Whether the session has no stored attributes.
  bool get isEmpty =>
      isAuthenticated == null &&
      userToken == null &&
      refreshToken == null &&
      userId == null &&
      userName == null &&
      userEmail == null &&
      userPhone == null &&
      (userRoles == null || userRoles!.isEmpty) &&
      selectedRole == null &&
      schoolId == null &&
      teacherId == null &&
      schoolName == null &&
      profilePhotoUrl == null &&
      childrenName == null;

  /// Creates a copy of this [SessionData] with replaced values.
  SessionData copyWith({
    bool? isAuthenticated,
    String? userToken,
    String? refreshToken,
    int? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    List<String>? userRoles,
    String? selectedRole,
    int? schoolId,
    int? teacherId,
    String? schoolName,
    String? profilePhotoUrl,
    String? childrenName,
  }) {
    return SessionData(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userToken: userToken ?? this.userToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userRoles: userRoles ?? (this.userRoles != null ? List.unmodifiable(this.userRoles!) : null),
      selectedRole: selectedRole ?? this.selectedRole,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      schoolName: schoolName ?? this.schoolName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      childrenName: childrenName ?? this.childrenName,
    );
  }

  /// Serializes session state to a map.
  Map<String, dynamic> toMap() {
    return {
      'isAuthenticated': isAuthenticated,
      'userToken': userToken,
      'refreshToken': refreshToken,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userRoles': userRoles,
      'selectedRole': selectedRole,
      'schoolId': schoolId,
      'teacherId': teacherId,
      'schoolName': schoolName,
      'profilePhotoUrl': profilePhotoUrl,
      'childrenName': childrenName,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionData &&
        other.isAuthenticated == isAuthenticated &&
        other.userToken == userToken &&
        other.refreshToken == refreshToken &&
        other.userId == userId &&
        other.userName == userName &&
        other.userEmail == userEmail &&
        other.userPhone == userPhone &&
        listEquals(other.userRoles, userRoles) &&
        other.selectedRole == selectedRole &&
        other.schoolId == schoolId &&
        other.teacherId == teacherId &&
        other.schoolName == schoolName &&
        other.profilePhotoUrl == profilePhotoUrl &&
        other.childrenName == childrenName;
  }

  @override
  int get hashCode => Object.hash(
        isAuthenticated,
        userToken,
        refreshToken,
        userId,
        userName,
        userEmail,
        userPhone,
        userRoles == null ? null : Object.hashAll(userRoles!),
        selectedRole,
        schoolId,
        teacherId,
        schoolName,
        profilePhotoUrl,
        childrenName,
      );

  @override
  String toString() {
    // Mask sensitive tokens in logs to prevent secret leakage
    final maskedToken = userToken != null
        ? (userToken!.length > 8
            ? '${userToken!.substring(0, 4)}...${userToken!.substring(userToken!.length - 4)}'
            : '***')
        : 'null';
    return 'SessionData(isAuthenticated: $isAuthenticated, userId: $userId, '
        'selectedRole: $selectedRole, schoolId: $schoolId, teacherId: $teacherId, '
        'userName: $userName, userEmail: $userEmail, userRoles: $userRoles, '
        'userToken: $maskedToken)';
  }
}
