import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/university_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/organization_model.dart';
import 'auth_api.dart';

class RegistrationRequest {
  const RegistrationRequest(this.user, this.organization);
  final UserModel user;
  final OrganizationModel? organization;
  String get name => organization?.name ?? user.fullName;
}

class AdminApi {
  AdminApi({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  Stream<List<UserModel>> watchPendingRegistrations() => _db
      .collection('users')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) {
        final users = s.docs
            .map((d) => UserModel.fromMap(d.id, d.data()))
            .where((u) => u.role != UserRole.citizen)
            .toList();
        users.sort(
          (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
            a.createdAt ?? DateTime(1970),
          ),
        );
        return users;
      });
  Stream<List<UserModel>> watchPendingRegistrationsByRole(UserRole role) =>
      watchPendingRegistrations().map(
        (users) => users.where((u) => u.role == role).toList(),
      );
  Stream<Map<String, int>> watchOrganizationCounts() => _db
      .collection('organizations')
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map(
        (snapshot) => {
          for (final type in ['university', 'industry'])
            type: snapshot.docs.where((d) => d.data()['type'] == type).length,
        },
      );
  Future<RegistrationRequest> getRequest(UserModel user) async {
    final id = user.organizationId;
    if (id == null) return RegistrationRequest(user, null);
    final doc = await _db
        .collection('organizations')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) {
      throw const AccountException(
        'The linked organization could not be found.',
      );
    }
    return RegistrationRequest(
      user,
      OrganizationModel.fromMap(doc.id, doc.data()!),
    );
  }

  Future<void> approveRegistration({required String uid}) async {
    final target = await _db.collection('users').doc(uid).get();

    if (!target.exists) {
      throw const AccountException('Registration not found.');
    }

    final profile = UserModel.fromMap(uid, target.data()!);

    if (profile.role == UserRole.university) {
      throw const AccountException(
        'A university must be linked to a canonical university before approval.',
      );
    }

    await _transition(uid, 'active', expected: 'pending');
  }

  Future<void> rejectRegistration({
    required String uid,
    required String reason,
    String? organizationId,
  }) {
    if (reason.trim().isEmpty) {
      throw const AccountException('A rejection reason is required.');
    }
    return _transition(
      uid,
      'rejected',
      expected: 'pending',
      reason: reason.trim(),
    );
  }

  Future<void> suspendUser(String uid) =>
      _transition(uid, 'suspended', expected: 'active');
  Future<void> reactivateUser(String uid) =>
      _transition(uid, 'active', expected: 'suspended');
  Future<void> _transition(
    String uid,
    String status, {
    required String expected,
    String? reason,
  }) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null || adminUid == uid) {
      throw const AccountException(
        'An existing approved administrator must perform this action.',
      );
    }
    await _db.runTransaction((tx) async {
      final admin = await tx.get(_db.collection('users').doc(adminUid));
      if (admin.data()?['role'] != 'admin' ||
          admin.data()?['status'] != 'active') {
        throw const AccountException(
          'Only an approved administrator may manage registrations.',
        );
      }
      final targetRef = _db.collection('users').doc(uid);
      final target = await tx.get(targetRef);
      if (!target.exists) {
        throw const AccountException('This registration no longer exists.');
      }
      final profile = UserModel.fromMap(uid, target.data()!);
      if (profile.status != expected) {
        throw const AccountException(
          'This account status has changed. Refresh and try again.',
        );
      }
      final orgRef = profile.organizationId == null
          ? null
          : _db.collection('organizations').doc(profile.organizationId);
      if (orgRef != null) {
        final org = await tx.get(orgRef);
        if (!org.exists || org.data()?['createdBy'] != uid) {
          throw const AccountException(
            'The organization link is invalid. Contact support.',
          );
        }
      }
      final timestamp = FieldValue.serverTimestamp();
      final audit = <String, dynamic>{
        'updatedAt': timestamp,
        if (status == 'active') ...{
          'approvedBy': adminUid,
          'approvedAt': timestamp,
        },
        if (status == 'rejected') ...{
          'rejectionReason': reason,
          'rejectedBy': adminUid,
          'rejectedAt': timestamp,
        },
        if (status == 'suspended') ...{
          'suspendedBy': adminUid,
          'suspendedAt': timestamp,
        },
      };
      tx.update(targetRef, {'status': status, ...audit});
      if (orgRef != null) {
        tx.update(orgRef, {
          'status': status == 'active' ? 'approved' : status,
          ...audit,
        });
      }
    });
  }

  Future<List<UniversityModel>> findUniversityCandidates(
    OrganizationModel organization,
  ) async {
    final normalized = _normalizeUniversityName(organization.name);

    final domain = _emailDomain(organization.officialEmail);

    final matches = <String, UniversityModel>{};

    if (normalized.isNotEmpty) {
      final byName = await _db
          .collection('universities')
          .where('normalizedName', isEqualTo: normalized)
          .limit(10)
          .get();

      for (final doc in byName.docs) {
        matches[doc.id] = UniversityModel.fromMap(id: doc.id, map: doc.data());
      }
    }

    if (domain.isNotEmpty) {
      final byDomain = await _db
          .collection('universities')
          .where('domain', isEqualTo: domain)
          .limit(10)
          .get();

      for (final doc in byDomain.docs) {
        matches[doc.id] = UniversityModel.fromMap(id: doc.id, map: doc.data());
      }
    }

    return matches.values.where((university) => university.active).toList();
  }

  Future<void> approveUniversityRegistration({
    required String uid,

    /// Existing canonical university.
    String? universityId,

    /// Use true only when admin confirms
    /// this is a genuinely new university.
    bool createNewUniversity = false,
  }) async {
    final adminUid = _auth.currentUser?.uid;

    if (adminUid == null || adminUid == uid) {
      throw const AccountException(
        'An existing approved administrator must perform this action.',
      );
    }

    // Exactly one mode is required.
    if ((universityId != null && universityId.trim().isNotEmpty) ==
        createNewUniversity) {
      throw const AccountException(
        'Choose an existing university or create a new university.',
      );
    }

    final newUniversityId = createNewUniversity
        ? _generateUniversityId()
        : null;

    await _db.runTransaction((tx) async {
      // ========================================================
      // ADMIN
      // ========================================================

      final admin = await tx.get(_db.collection('users').doc(adminUid));

      if (admin.data()?['role'] != 'admin' ||
          admin.data()?['status'] != 'active') {
        throw const AccountException(
          'Only an approved administrator may manage registrations.',
        );
      }

      // ========================================================
      // USER
      // ========================================================

      final userRef = _db.collection('users').doc(uid);

      final userSnapshot = await tx.get(userRef);

      if (!userSnapshot.exists) {
        throw const AccountException('This registration no longer exists.');
      }

      final profile = UserModel.fromMap(uid, userSnapshot.data()!);

      if (profile.role != UserRole.university) {
        throw const AccountException(
          'This registration is not a university account.',
        );
      }

      if (profile.status != 'pending') {
        throw const AccountException(
          'This account status has changed. Refresh and try again.',
        );
      }

      if (profile.organizationId == null) {
        throw const AccountException(
          'University registration has no organization profile.',
        );
      }

      // ========================================================
      // REGISTRATION ORGANIZATION
      // ========================================================

      final organizationRef = _db
          .collection('organizations')
          .doc(profile.organizationId);

      final organizationSnapshot = await tx.get(organizationRef);

      if (!organizationSnapshot.exists) {
        throw const AccountException(
          'The registration organization could not be found.',
        );
      }

      final organizationData = organizationSnapshot.data()!;

      if (organizationData['createdBy'] != uid) {
        throw const AccountException('The organization link is invalid.');
      }

      // ========================================================
      // CANONICAL UNIVERSITY
      // ========================================================

      late final String resolvedUniversityId;

      if (createNewUniversity) {
        resolvedUniversityId = newUniversityId!;

        final universityRef = _db
            .collection('universities')
            .doc(resolvedUniversityId);

        final canonicalUniversity = {
          'id': resolvedUniversityId,

          'name': organizationData['name']?.toString() ?? '',

          'normalizedName':
              organizationData['normalizedName']?.toString() ??
              _normalizeUniversityName(
                organizationData['name']?.toString() ?? '',
              ),

          'domain': organizationData['emailDomain']?.toString() ?? '',

          'website': organizationData['website']?.toString() ?? '',

          'type': organizationData['organizationCategory']?.toString() ?? '',

          'city': organizationData['city']?.toString() ?? '',

          'state': organizationData['state']?.toString() ?? '',

          'address': organizationData['address']?.toString() ?? '',

          'active': true,

          // New registrations are NOT
          // automatically sent to the ML
          // candidate pool.
          'mlEligible': false,

          'source': 'registration',

          'aliases': <String>[],

          'departments': <String>[],

          'capabilities': <String, double>{},

          'createdAt': FieldValue.serverTimestamp(),

          'updatedAt': FieldValue.serverTimestamp(),

          'createdBy': adminUid,
        };

        tx.set(universityRef, canonicalUniversity);
      } else {
        resolvedUniversityId = universityId!.trim();

        final universityRef = _db
            .collection('universities')
            .doc(resolvedUniversityId);

        final universitySnapshot = await tx.get(universityRef);

        if (!universitySnapshot.exists) {
          throw const AccountException(
            'The selected university no longer exists.',
          );
        }

        if (universitySnapshot.data()?['active'] == false) {
          throw const AccountException('The selected university is inactive.');
        }
      }

      // ========================================================
      // APPROVE + LINK
      // ========================================================

      final timestamp = FieldValue.serverTimestamp();

      tx.update(userRef, {
        'status': 'active',

        'universityId': resolvedUniversityId,

        'universityRole': 'university_admin',

        'approvedBy': adminUid,

        'approvedAt': timestamp,

        'updatedAt': timestamp,
      });

      tx.update(organizationRef, {
        'status': 'approved',

        'universityId': resolvedUniversityId,

        'approvedBy': adminUid,

        'approvedAt': timestamp,

        'updatedAt': timestamp,
      });
    });
  }

  String _generateUniversityId() {
    final randomId = _db.collection('universities').doc().id;

    return 'UNI_$randomId';
  }

  String _normalizeUniversityName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _emailDomain(String email) {
    final parts = email.trim().toLowerCase().split('@');

    return parts.length == 2 ? parts.last : '';
  }
}
