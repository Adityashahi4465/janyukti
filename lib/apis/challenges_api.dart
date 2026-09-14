import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/instance_providers.dart';
import '../models/challenge_model.dart';

// ============================================================
// API PROVIDER
// ============================================================

final challengesApiProvider = Provider<ChallengesApi>((ref) {
  return ChallengesApi(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

// ============================================================
// CHALLENGE API
// ============================================================

class ChallengesApi {
  ChallengesApi({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _db = firestore,
       _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _db.collection('challenges');

  // ============================================================
  // CURRENT USER
  // ============================================================

  User get currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated');
    }

    return user;
  }

  String get currentUserId => currentUser.uid;

  String get currentUserName {
    final user = currentUser;

    final displayName = user.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'User';
  }

  // ============================================================
  // GENERATE ID
  // ============================================================

  String generateChallengeId() {
    return _challenges.doc().id;
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<Challenge> createChallenge(Challenge challenge) async {
    final user = currentUser;

    final id = challenge.id.isNotEmpty ? challenge.id : generateChallengeId();

    final now = DateTime.now();

    final submittedByName = challenge.submittedBy.trim().isNotEmpty
        ? challenge.submittedBy.trim()
        : currentUserName;

    final initialStatus = challenge.status.trim().isEmpty
        ? 'Submitted'
        : challenge.status.trim();

    final initialHistory = challenge.statusHistory.isEmpty
        ? [
            ChallengeStatusEvent(
              status: initialStatus,
              at: now,
              updatedById: user.uid,
              updatedByName: submittedByName,
              note: 'Challenge submitted',
            ),
          ]
        : challenge.statusHistory;

    final challengeToSave = challenge.copyWith(
      id: id,

      status: initialStatus,

      submittedById: user.uid,

      submittedBy: submittedByName,

      statusHistory: initialHistory,

      lastUpdatedById: user.uid,

      lastUpdatedByName: submittedByName,

      createdAt: now,

      updatedAt: now,
    );

    final data = challengeToSave.toMap();

    // Server-authoritative top-level dates
    data['createdAt'] = FieldValue.serverTimestamp();

    data['updatedAt'] = FieldValue.serverTimestamp();

    await _challenges.doc(id).set(data);

    return challengeToSave;
  }

  // ============================================================
  // GET SINGLE
  // ============================================================

  Future<Challenge?> getChallenge(String challengeId) async {
    if (challengeId.trim().isEmpty) {
      throw Exception('Challenge ID is required');
    }

    final snapshot = await _challenges.doc(challengeId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return Challenge.fromMap(id: snapshot.id, map: data);
  }

  // ============================================================
  // WATCH SINGLE
  // ============================================================

  Stream<Challenge?> watchChallenge(String challengeId) {
    if (challengeId.trim().isEmpty) {
      throw Exception('Challenge ID is required');
    }

    return _challenges.doc(challengeId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      return Challenge.fromMap(id: snapshot.id, map: data);
    });
  }

  // ============================================================
  // WATCH ALL
  // ============================================================

  Stream<List<Challenge>> watchChallenges() {
    return _challenges.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Challenge.fromMap(id: doc.id, map: doc.data()))
          .toList();
    });
  }

  Stream<List<Challenge>> watchMyChallenges() {
    final userId = currentUserId;

    return _challenges
        .where('submittedById', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => Challenge.fromMap(id: doc.id, map: doc.data()))
              .toList();

          challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return challenges;
        });
  }
  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus({
    required String challengeId,
    required String status,
    String note = '',
  }) async {
    final normalizedId = challengeId.trim();

    final normalizedStatus = status.trim();

    if (normalizedId.isEmpty) {
      throw Exception('Challenge ID is required');
    }

    if (normalizedStatus.isEmpty) {
      throw Exception('Status is required');
    }

    final user = currentUser;
    final now = DateTime.now();

    final event = ChallengeStatusEvent(
      status: normalizedStatus,
      at: now,
      updatedById: user.uid,
      updatedByName: currentUserName,
      note: note,
    );

    final update = <String, dynamic>{
      'status': normalizedStatus,

      'updatedAt': FieldValue.serverTimestamp(),

      'lastUpdatedById': user.uid,

      'lastUpdatedByName': currentUserName,

      'statusHistory': FieldValue.arrayUnion([event.toMap()]),
    };

    final value = normalizedStatus.toLowerCase();

    // ==========================================================
    // UNDER REVIEW
    // ==========================================================

    if (value == 'under review') {
      update.addAll({
        'reviewedById': user.uid,

        'reviewedByName': currentUserName,

        'reviewedAt': FieldValue.serverTimestamp(),
      });
    }

    // ==========================================================
    // SOLUTION DEPLOYED
    // ==========================================================

    if (value == 'solution deployed' || value == 'deployed') {
      update['solutionDeployedAt'] = FieldValue.serverTimestamp();
    }

    // ==========================================================
    // RESOLVED
    // ==========================================================

    if (value == 'resolved' || value == 'completed') {
      update['resolvedAt'] = FieldValue.serverTimestamp();
    }

    await _challenges.doc(normalizedId).update(update);
  }

  // ============================================================
  // UPDATE PRIORITY
  // ============================================================

  Future<void> updatePriority({
    required String challengeId,
    required String priority,
  }) async {
    final id = challengeId.trim();

    final value = priority.trim();

    if (id.isEmpty) {
      throw Exception('Challenge ID is required');
    }

    if (value.isEmpty) {
      throw Exception('Priority is required');
    }

    final user = currentUser;

    await _challenges.doc(id).update({
      'priority': value,

      'updatedAt': FieldValue.serverTimestamp(),

      'lastUpdatedById': user.uid,

      'lastUpdatedByName': currentUserName,
    });
  }

  // ============================================================
  // ASSIGN UNIVERSITY
  // ============================================================

  Future<void> assignUniversity({
    required String challengeId,
    required String universityId,
    required String universityName,
  }) async {
    final challenge = challengeId.trim();

    final uniId = universityId.trim();

    final uniName = universityName.trim();

    if (challenge.isEmpty) {
      throw Exception('Challenge ID is required');
    }

    if (uniId.isEmpty) {
      throw Exception('University ID is required');
    }

    if (uniName.isEmpty) {
      throw Exception('University name is required');
    }

    final user = currentUser;

    final event = ChallengeStatusEvent(
      status: 'Assigned',
      at: DateTime.now(),
      updatedById: user.uid,
      updatedByName: currentUserName,
      note: 'Assigned to $uniName',
    );

    await _challenges.doc(challenge).update({
      // University
      'assignedUniversityId': uniId,

      'assignedUniversityName': uniName,

      // Who assigned it
      'assignedById': user.uid,

      'assignedByName': currentUserName,

      'assignedAt': FieldValue.serverTimestamp(),

      // Workflow
      'status': 'Assigned',

      'statusHistory': FieldValue.arrayUnion([event.toMap()]),

      // Audit
      'lastUpdatedById': user.uid,

      'lastUpdatedByName': currentUserName,

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
