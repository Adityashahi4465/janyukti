import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.role,
    this.fullName = '',
    this.email = '',
    this.phone,
    this.status = 'pending',

    // Registration / organization profile document
    this.organizationId,

    // Canonical university identity
    this.universityId,

    // university_admin / coordinator / faculty etc.
    this.universityRole,

    this.designation,
    this.city,
    this.state,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
  });

  final String uid;
  final String fullName;
  final String email;
  final String status;

  final UserRole role;

  final String? phone;

  /// Registration organization record.
  ///
  /// Example:
  /// organizations/abc123
  final String? organizationId;

  /// Canonical university id used by:
  /// - ML
  /// - challenge assignment
  /// - university dashboard
  ///
  /// Example:
  /// UNI_00017
  final String? universityId;

  /// university_admin / coordinator / faculty
  final String? universityRole;

  final String? designation;
  final String? city;
  final String? state;
  final String? rejectionReason;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get phoneNumber => phone;

  bool get isActive => status == 'active';

  bool get isApprovedUniversity =>
      role == UserRole.university &&
      status == 'active' &&
      universityId != null &&
      universityId!.trim().isNotEmpty;

  static DateTime? date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    final role = UserRoleX.fromStorageKey(data['role'] as String?);

    if (role == null) {
      throw const FormatException('Invalid account role.');
    }

    return UserModel(
      uid: uid,
      role: role,

      fullName: data['fullName']?.toString() ?? '',

      email: data['email']?.toString() ?? '',

      phone: (data['phone'] ?? data['phoneNumber'])?.toString(),

      status: data['status']?.toString() ?? 'pending',

      organizationId: data['organizationId']?.toString(),

      universityId: data['universityId']?.toString(),

      universityRole: data['universityRole']?.toString(),

      designation: data['designation']?.toString(),

      city: data['city']?.toString(),

      state: data['state']?.toString(),

      createdAt: date(data['createdAt']),

      updatedAt: date(data['updatedAt']),

      rejectionReason: data['rejectionReason']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,

      'role': role.storageKey,
      'status': status,

      'organizationId': organizationId,

      'universityId': universityId,

      'universityRole': universityRole,

      'designation': designation,

      'city': city,
      'state': state,

      'createdAt': createdAt,

      'updatedAt': updatedAt,

      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? status,
    String? designation,
    String? organizationId,
    String? universityId,
    String? universityRole,
  }) {
    return UserModel(
      uid: uid,
      role: role,

      fullName: fullName ?? this.fullName,

      email: email,

      phone: phone ?? this.phone,

      status: status ?? this.status,

      organizationId: organizationId ?? this.organizationId,

      universityId: universityId ?? this.universityId,

      universityRole: universityRole ?? this.universityRole,

      designation: designation ?? this.designation,

      city: city,
      state: state,

      createdAt: createdAt,

      updatedAt: updatedAt,

      rejectionReason: rejectionReason,
    );
  }
}
