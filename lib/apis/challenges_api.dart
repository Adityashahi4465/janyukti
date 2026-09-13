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
// CHALLENGES API
// Pure Firebase / Firestore layer
// No UI state providers here.
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

    return 'Citizen';
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

    final challengeToSave = challenge.copyWith(
      id: id,
      submittedById: user.uid,
      submittedBy: challenge.submittedBy.trim().isNotEmpty
          ? challenge.submittedBy.trim()
          : currentUserName,
      createdAt: now,
      updatedAt: now,
    );

    final data = challengeToSave.toMap();

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
  // WATCH ALL
  // ============================================================

  Stream<List<Challenge>> watchChallenges() {
    return _challenges
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromMap(id: doc.id, map: doc.data()))
              .toList(),
        );
  }

  // ============================================================
  // WATCH CURRENT USER
  // ============================================================

  Stream<List<Challenge>> watchMyChallenges() {
    final userId = currentUserId;

    return _challenges
        .where('submittedById', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromMap(id: doc.id, map: doc.data()))
              .toList(),
        );
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus({
    required String challengeId,
    required String status,
  }) async {
    if (challengeId.trim().isEmpty) {
      throw Exception('Challenge ID is required');
    }

    if (status.trim().isEmpty) {
      throw Exception('Status is required');
    }

    await _challenges.doc(challengeId).update({
      'status': status.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // UPDATE PRIORITY
  // ============================================================

  Future<void> updatePriority({
    required String challengeId,
    required String priority,
  }) async {
    if (challengeId.trim().isEmpty) {
      throw Exception('Challenge ID is required');
    }

    if (priority.trim().isEmpty) {
      throw Exception('Priority is required');
    }

    await _challenges.doc(challengeId).update({
      'priority': priority.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
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
    if (challengeId.trim().isEmpty) {
      throw Exception('Challenge ID is required');
    }

    if (universityId.trim().isEmpty) {
      throw Exception('University ID is required');
    }

    if (universityName.trim().isEmpty) {
      throw Exception('University name is required');
    }

    await _challenges.doc(challengeId).update({
      'assignedUniversityId': universityId.trim(),
      'assignedUniversityName': universityName.trim(),
      'status': 'Assigned',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
