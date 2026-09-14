import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/instance_providers.dart';
import '../models/challenge_model.dart';
import '../models/project_model.dart';
import '../models/university_model.dart';
import '../models/university_recommendation.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'auth_api.dart';
import '../models/project_update_model.dart';

final universitiesApiProvider = Provider<UniversityApi>((ref) {
  return UniversityApi(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

class UniversityApi {
  UniversityApi({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _db = firestore,
       _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _universities =>
      _db.collection('universities');

  // ============================================================
  // CURRENT UNIVERSITY USER
  // ============================================================

  Future<UserModel> requireUniversityUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      throw const AccountException('Please sign in again.');
    }

    final snapshot = await _db.collection('users').doc(firebaseUser.uid).get();

    if (!snapshot.exists) {
      throw const AccountException('University profile not found.');
    }

    final user = UserModel.fromMap(snapshot.id, snapshot.data()!);

    if (user.role != UserRole.university || !user.isActive) {
      throw const AccountException(
        'Only an approved university account can access this workspace.',
      );
    }

    if (user.universityId == null || user.universityId!.trim().isEmpty) {
      throw const AccountException(
        'This university account is not linked to a canonical university.',
      );
    }

    return user;
  }

  // ============================================================
  // ASSIGNED CHALLENGES
  // ============================================================

  Stream<List<Challenge>> watchAssignedChallenges(String universityId) {
    return _db
        .collection('challenges')
        .where('assignedUniversityId', isEqualTo: universityId)
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => Challenge.fromMap(id: doc.id, map: doc.data()))
              .toList();

          challenges.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return challenges;
        });
  }

  Stream<Challenge?> watchChallenge(String challengeId) {
    return _db.collection('challenges').doc(challengeId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();

      if (data == null) {
        return null;
      }

      return Challenge.fromMap(id: doc.id, map: data);
    });
  }

  // ============================================================
  // PROJECTS
  // ============================================================

  Stream<List<Project>> watchProjects(String universityId) {
    return _db
        .collection('projects')
        .where('universityId', isEqualTo: universityId)
        .snapshots()
        .map((snapshot) {
          final projects = snapshot.docs
              .map((doc) => Project.fromMap(doc.id, doc.data()))
              .toList();

          projects.sort(
            (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
              a.updatedAt ?? DateTime(1970),
            ),
          );

          return projects;
        });
  }

  Stream<Project?> watchProject(String challengeId) {
    return _db
        .collection('projects')
        .doc(challengeId)
        .snapshots()
        .map((doc) => doc.exists ? Project.fromMap(doc.id, doc.data()!) : null);
  }

  // ============================================================
  // CREATE PROJECT + START CHALLENGE
  // ============================================================

  Future<void> createProject({
    required String challengeId,
    required String name,
    required String mentor,
    required List<String> teamMembers,
  }) async {
    final user = await requireUniversityUser();

    final universityId = user.universityId!;

    final challengeRef = _db.collection('challenges').doc(challengeId);

    final projectRef = _db.collection('projects').doc(challengeId);

    await _db.runTransaction((transaction) async {
      final challengeSnapshot = await transaction.get(challengeRef);

      if (!challengeSnapshot.exists) {
        throw Exception('Challenge not found.');
      }

      final challenge = Challenge.fromMap(
        id: challengeSnapshot.id,
        map: challengeSnapshot.data()!,
      );

      if (challenge.assignedUniversityId != universityId) {
        throw Exception('This challenge is not assigned to your university.');
      }

      final existingProject = await transaction.get(projectRef);

      if (existingProject.exists) {
        throw Exception('A project already exists for this challenge.');
      }

      final now = FieldValue.serverTimestamp();

      final milestones = [
        'Initial Assessment',
        'Research & Planning',
        'Prototype / Solution Development',
        'Field Implementation',
        'Solution Validation',
      ];

      transaction.set(projectRef, {
        'id': challengeId,

        'challengeId': challengeId,

        'universityId': universityId,

        'universityName': challenge.assignedUniversityName ?? '',

        'name': name.trim(),

        'mentor': mentor.trim(),

        'teamMembers': teamMembers,

        'status': 'active',

        'progress': 0,

        'milestones': milestones
            .map(
              (title) => {
                'title': title,
                'completed': false,
                'completedAt': null,
              },
            )
            .toList(),

        'createdById': user.uid,

        'createdByName': user.fullName,

        'createdAt': now,

        'updatedAt': now,
      });

      final event = ChallengeStatusEvent(
        status: 'In Progress',
        at: DateTime.now(),
        updatedById: user.uid,
        updatedByName: user.fullName,
        note: 'University project created and work started.',
      );

      transaction.update(challengeRef, {
        'status': 'In Progress',

        'projectStartedAt': now,

        'updatedAt': now,

        'lastUpdatedById': user.uid,

        'lastUpdatedByName': user.fullName,

        'statusHistory': FieldValue.arrayUnion([event.toMap()]),
      });
    });
  }
  // ============================================================
  // PROJECT UPDATES
  // ============================================================

  Stream<List<ProjectUpdate>> watchProjectUpdates(String challengeId) {
    return _db
        .collection('challenges')
        .doc(challengeId)
        .collection('updates')
        .snapshots()
        .map((snapshot) {
          final updates = snapshot.docs
              .map((doc) => ProjectUpdate.fromMap(doc.id, doc.data()))
              .toList();

          updates.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return updates;
        });
  }

  // ============================================================
  // POST PROGRESS UPDATE
  // ============================================================

  Future<void> postProgressUpdate({
    required String challengeId,
    required String title,
    required String description,
    required int progress,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception('Update title is required.');
    }

    if (description.trim().isEmpty) {
      throw Exception('Update description is required.');
    }

    if (progress < 0 || progress > 100) {
      throw Exception('Progress must be between 0 and 100.');
    }

    final user = await requireUniversityUser();

    final universityId = user.universityId!;

    final challengeRef = _db.collection('challenges').doc(challengeId);

    final projectRef = _db.collection('projects').doc(challengeId);

    final updateRef = challengeRef.collection('updates').doc();

    await _db.runTransaction((transaction) async {
      final challengeSnapshot = await transaction.get(challengeRef);

      final projectSnapshot = await transaction.get(projectRef);

      if (!challengeSnapshot.exists) {
        throw Exception('Challenge not found.');
      }

      if (!projectSnapshot.exists) {
        throw Exception('Project not found.');
      }

      final challenge = Challenge.fromMap(
        id: challengeSnapshot.id,
        map: challengeSnapshot.data()!,
      );

      final project = Project.fromMap(
        projectSnapshot.id,
        projectSnapshot.data()!,
      );

      if (challenge.assignedUniversityId != universityId ||
          project.universityId != universityId) {
        throw Exception('You cannot update this project.');
      }

      if (challenge.status.trim().toLowerCase() != 'in progress') {
        throw Exception(
          'Progress updates are only allowed while the challenge is in progress.',
        );
      }

      if (progress < project.progress) {
        throw Exception('Progress cannot be lower than the current progress.');
      }

      final timestamp = FieldValue.serverTimestamp();

      transaction.set(updateRef, {
        'id': updateRef.id,

        'challengeId': challengeId,

        'type': 'progress',

        'title': title.trim(),

        'description': description.trim(),

        'progressPercent': progress,

        'universityId': universityId,

        'universityName': challenge.assignedUniversityName ?? '',

        'createdById': user.uid,

        'createdByName': user.fullName,

        'createdAt': timestamp,
      });

      transaction.update(projectRef, {
        'progress': progress,

        'updatedAt': timestamp,
      });

      transaction.update(challengeRef, {
        'progressPercent': progress,

        'lastUniversityUpdateText': description.trim(),

        'lastUniversityUpdateAt': timestamp,

        'lastUpdatedById': user.uid,

        'lastUpdatedByName': user.fullName,

        'updatedAt': timestamp,
      });
    });
  }

  // ============================================================
  // SUBMIT SOLUTION
  // ============================================================

  Future<void> submitSolution({
    required String challengeId,
    required String title,
    required String description,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception('Solution title is required.');
    }

    if (description.trim().isEmpty) {
      throw Exception('Solution description is required.');
    }

    final user = await requireUniversityUser();

    final universityId = user.universityId!;

    final challengeRef = _db.collection('challenges').doc(challengeId);

    final projectRef = _db.collection('projects').doc(challengeId);

    final updateRef = challengeRef.collection('updates').doc();

    await _db.runTransaction((transaction) async {
      final challengeSnapshot = await transaction.get(challengeRef);

      final projectSnapshot = await transaction.get(projectRef);

      if (!challengeSnapshot.exists || !projectSnapshot.exists) {
        throw Exception('Project information could not be found.');
      }

      final challenge = Challenge.fromMap(
        id: challengeSnapshot.id,
        map: challengeSnapshot.data()!,
      );

      final project = Project.fromMap(
        projectSnapshot.id,
        projectSnapshot.data()!,
      );

      if (challenge.assignedUniversityId != universityId ||
          project.universityId != universityId) {
        throw Exception('You cannot submit a solution for this project.');
      }

      if (challenge.status.trim().toLowerCase() != 'in progress') {
        throw Exception('This project is not currently in progress.');
      }

      final timestamp = FieldValue.serverTimestamp();

      transaction.set(updateRef, {
        'id': updateRef.id,

        'challengeId': challengeId,

        'type': 'solution',

        'title': title.trim(),

        'description': description.trim(),

        'progressPercent': 100,

        'universityId': universityId,

        'universityName': challenge.assignedUniversityName ?? '',

        'createdById': user.uid,

        'createdByName': user.fullName,

        'createdAt': timestamp,
      });

      transaction.update(projectRef, {
        'status': 'solution_deployed',

        'progress': 100,

        'updatedAt': timestamp,
      });

      final event = ChallengeStatusEvent(
        status: 'Solution Deployed',
        at: DateTime.now(),
        updatedById: user.uid,
        updatedByName: user.fullName,
        note: description.trim(),
      );

      transaction.update(challengeRef, {
        'status': 'Solution Deployed',

        'progressPercent': 100,

        'solutionDeployedAt': timestamp,

        'lastUniversityUpdateText': description.trim(),

        'lastUniversityUpdateAt': timestamp,

        'lastUpdatedById': user.uid,

        'lastUpdatedByName': user.fullName,

        'updatedAt': timestamp,

        'statusHistory': FieldValue.arrayUnion([event.toMap()]),
      });
    });
  }

  // ============================================================
  // UPDATE PROJECT PROGRESS
  // ============================================================

  Future<void> updateProgress({
    required String challengeId,
    required int progress,
    required String note,
  }) async {
    if (progress < 0 || progress > 100) {
      throw Exception('Progress must be between 0 and 100.');
    }

    final user = await requireUniversityUser();

    final projectRef = _db.collection('projects').doc(challengeId);

    final challengeRef = _db.collection('challenges').doc(challengeId);

    final updateRef = challengeRef.collection('updates').doc();

    await _db.runTransaction((transaction) async {
      final projectSnapshot = await transaction.get(projectRef);

      if (!projectSnapshot.exists) {
        throw Exception('Project not found.');
      }

      final project = Project.fromMap(
        projectSnapshot.id,
        projectSnapshot.data()!,
      );

      if (project.universityId != user.universityId) {
        throw Exception('You cannot update this project.');
      }

      final timestamp = FieldValue.serverTimestamp();

      transaction.update(projectRef, {
        'progress': progress,
        'updatedAt': timestamp,
      });

      transaction.set(updateRef, {
        'id': updateRef.id,

        'challengeId': challengeId,

        'type': 'progress',

        'description': note.trim(),

        'progressPercent': progress,

        'createdById': user.uid,

        'createdByName': user.fullName,

        'universityId': user.universityId,

        'createdAt': timestamp,
      });

      transaction.update(challengeRef, {
        'progressPercent': progress,

        'lastUniversityUpdateText': note.trim(),

        'lastUniversityUpdateAt': timestamp,

        'updatedAt': timestamp,

        'lastUpdatedById': user.uid,

        'lastUpdatedByName': user.fullName,
      });
    });
  }

  // ============================================================
  // SUBMIT SOLUTION
  // ============================================================

  Future<void> markSolutionDeployed({
    required String challengeId,
    required String note,
  }) async {
    final user = await requireUniversityUser();

    if (note.trim().isEmpty) {
      throw Exception('Solution summary is required.');
    }

    final challengeRef = _db.collection('challenges').doc(challengeId);

    final projectRef = _db.collection('projects').doc(challengeId);

    await _db.runTransaction((transaction) async {
      final projectSnapshot = await transaction.get(projectRef);

      if (!projectSnapshot.exists) {
        throw Exception('Project not found.');
      }

      final project = Project.fromMap(
        projectSnapshot.id,
        projectSnapshot.data()!,
      );

      if (project.universityId != user.universityId) {
        throw Exception('You cannot update this project.');
      }

      final timestamp = FieldValue.serverTimestamp();

      final event = ChallengeStatusEvent(
        status: 'Solution Deployed',
        at: DateTime.now(),
        updatedById: user.uid,
        updatedByName: user.fullName,
        note: note.trim(),
      );

      transaction.update(projectRef, {
        'status': 'solution_deployed',
        'progress': 100,
        'updatedAt': timestamp,
      });

      transaction.update(challengeRef, {
        'status': 'Solution Deployed',

        'progressPercent': 100,

        'solutionDeployedAt': timestamp,

        'lastUniversityUpdateAt': timestamp,

        'lastUniversityUpdateText': note.trim(),

        'updatedAt': timestamp,

        'lastUpdatedById': user.uid,

        'lastUpdatedByName': user.fullName,

        'statusHistory': FieldValue.arrayUnion([event.toMap()]),
      });
    });
  }

  // ============================================================
  // GET REAL ELIGIBLE UNIVERSITIES + RANK THEM
  // ============================================================

  Future<List<UniversityRecommendation>> getBestUniversitiesForChallenge(
    Challenge challenge, {
    int limit = 10,
  }) async {
    // Single-field query avoids unnecessary composite-index issues.
    final snapshot = await _universities.where('active', isEqualTo: true).get();

    final universities = snapshot.docs
        .map((doc) => UniversityModel.fromMap(id: doc.id, map: doc.data()))
        // ML recommendations should only use ML-ready universities.
        .where((university) => university.mlEligible)
        .toList();

    final recommendations = universities.map((university) {
      return _calculateRecommendation(challenge, university);
    }).toList();

    recommendations.sort((a, b) => b.score.compareTo(a.score));

    if (recommendations.length > limit) {
      return recommendations.take(limit).toList();
    }

    return recommendations;
  }

  // ============================================================
  // CURRENT TEMPORARY RANKING
  //
  // This uses REAL capability scores imported from ML dataset.
  // Replace this method later with your ML HTTP endpoint.
  // ============================================================

  UniversityRecommendation _calculateRecommendation(
    Challenge challenge,
    UniversityModel university,
  ) {
    var score = 0.0;

    final reasons = <String>[];

    // ----------------------------------------------------------
    // CATEGORY / CAPABILITY
    // ----------------------------------------------------------

    final challengeCategory = _normaliseKey(challenge.category);

    var capabilityScore = 0.0;

    for (final entry in university.capabilities.entries) {
      if (_normaliseKey(entry.key) == challengeCategory) {
        capabilityScore = max(capabilityScore, entry.value);
      }
    }

    // Capability contributes 90%
    score += capabilityScore * 0.90;

    if (capabilityScore >= .80) {
      reasons.add('Very strong expertise in ${challenge.category}');
    } else if (capabilityScore >= .60) {
      reasons.add('Strong expertise in ${challenge.category}');
    } else if (capabilityScore > 0) {
      reasons.add('Relevant expertise in ${challenge.category}');
    }

    // ----------------------------------------------------------
    // LOCATION
    // ----------------------------------------------------------

    final challengeLocation = _normaliseText(challenge.location);

    final city = _normaliseText(university.city);

    final state = _normaliseText(university.state);

    // Geographic relevance contributes remaining 10%.
    if (city.isNotEmpty && challengeLocation.contains(city)) {
      score += .06;

      reasons.add('Located near the reported challenge');
    }

    if (state.isNotEmpty && challengeLocation.contains(state)) {
      score += .04;

      if (!reasons.contains('Located near the reported challenge')) {
        reasons.add('Located in the same region');
      }
    }

    score = score.clamp(0.0, 1.0);

    if (reasons.isEmpty) {
      reasons.add('ML-eligible university');
    }

    return UniversityRecommendation(
      university: university,
      score: score,
      reasons: reasons,
    );
  }

  String _normaliseKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _normaliseText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
