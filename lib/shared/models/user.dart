import 'package:flutter/foundation.dart';

import '../../core/storage/storage_value_parser.dart';

/// User model representing an authenticated AceEdx user profile.
@immutable
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final List<String> roles;
  final List<String> permissions;
  final int? schoolId;
  final int? teacherId;
  final String? schoolName;
  final String? profilePhotoUrl;
  final String? childrenName;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.roles = const [],
    this.permissions = const [],
    this.schoolId,
    this.teacherId,
    this.schoolName,
    this.profilePhotoUrl,
    this.childrenName,
  });

  /// Factory constructor to safely parse user data from JSON maps.
  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = StorageValueParser.parseInt(rawId) ?? 0;

    final name = StorageValueParser.parseString(json['name'] ?? json['user_name']) ?? '';
    final email = StorageValueParser.parseString(json['email']) ?? '';
    final phone = StorageValueParser.parseString(json['phone']);
    final role = StorageValueParser.parseString(json['role']) ?? 'teacher';

    final roles = StorageValueParser.parseStringList(json['roles']) ?? [role];
    final permissions = StorageValueParser.parseStringList(json['permissions']) ?? const [];

    final schoolId = StorageValueParser.parseInt(json['school_id']);
    final teacherId = StorageValueParser.parseInt(json['teacher_id']);
    final schoolName = StorageValueParser.parseString(json['school_name']);
    final profilePhotoUrl = StorageValueParser.parseString(
      json['profile_photo_url'] ?? json['avatar'] ?? json['profile_photo'],
    );
    final childrenName = StorageValueParser.parseString(json['children_name']);

    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      roles: roles,
      permissions: permissions,
      schoolId: schoolId,
      teacherId: teacherId,
      schoolName: schoolName,
      profilePhotoUrl: profilePhotoUrl,
      childrenName: childrenName,
    );
  }

  /// Serializes user to a map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'roles': roles,
      'permissions': permissions,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'school_name': schoolName,
      'profile_photo_url': profilePhotoUrl,
      'children_name': childrenName,
    };
  }

  /// Creates a copy of this [User] with updated fields.
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    List<String>? roles,
    List<String>? permissions,
    int? schoolId,
    int? teacherId,
    String? schoolName,
    String? profilePhotoUrl,
    String? childrenName,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      schoolName: schoolName ?? this.schoolName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      childrenName: childrenName ?? this.childrenName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.role == role &&
        listEquals(other.roles, roles) &&
        listEquals(other.permissions, permissions) &&
        other.schoolId == schoolId &&
        other.teacherId == teacherId &&
        other.schoolName == schoolName &&
        other.profilePhotoUrl == profilePhotoUrl &&
        other.childrenName == childrenName;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        email,
        phone,
        role,
        Object.hashAll(roles),
        Object.hashAll(permissions),
        schoolId,
        teacherId,
        schoolName,
        profilePhotoUrl,
        childrenName,
      );

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role, '
        'roles: $roles, schoolId: $schoolId, teacherId: $teacherId)';
  }
}
