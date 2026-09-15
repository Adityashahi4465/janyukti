import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/instance_providers.dart';
import '../models/challenge_model.dart';
import '../models/industry_models.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

// ============================================================
// PROVIDER
// ============================================================

final industryApiProvider = Provider<IndustryApi>((ref) {
  return IndustryApi(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

// ============================================================
// API
// ============================================================

class IndustryApi {
  IndustryApi({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _db = firestore,
       _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _db.collection('projects');

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _db.collection('challenges');

  CollectionReference<Map<String, dynamic>> get _interests =>
      _db.collection('collaboration_interests');

  // ============================================================
  // CURRENT INDUSTRY
  // ============================================================

  Future<IndustryIdentity> requireIndustryIdentity() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      throw Exception('Please sign in again.');
    }

    final userSnapshot = await _db
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!userSnapshot.exists || userSnapshot.data() == null) {
      throw Exception('Industry user profile not found.');
    }

    final user = UserModel.fromMap(userSnapshot.id, userSnapshot.data()!);

    if (user.role != UserRole.industry) {
      throw Exception('Only industry accounts can access this area.');
    }

    if (!user.isActive) {
      throw Exception('Your industry account is not active.');
    }

    final organizationId = user.organizationId?.trim();

    if (organizationId == null || organizationId.isEmpty) {
      throw Exception('Industry organization is not linked to this account.');
    }

    final organizationSnapshot = await _db
        .collection('organizations')
        .doc(organizationId)
        .get();

    if (!organizationSnapshot.exists || organizationSnapshot.data() == null) {
      throw Exception('Industry organization could not be found.');
    }

    final organization = organizationSnapshot.data()!;

    final organizationName = organization['name']?.toString().trim() ?? '';

    if (organizationName.isEmpty) {
      throw Exception('Industry organization name is missing.');
    }

    return IndustryIdentity(
      uid: user.uid,
      fullName: user.fullName,
      organizationId: organizationId,
      organizationName: organizationName,
    );
  }

  // ============================================================
  // PROJECTS AVAILABLE TO INDUSTRY
  // ============================================================

  Stream<List<Project>> watchAvailableProjects() {
    return _projects.snapshots().map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .where((project) {
            final status = project.status.trim().toLowerCase();

            return status == 'active' || status == 'solution_deployed';
          })
          .toList();

      projects.sort(
        (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
          a.updatedAt ?? DateTime(1970),
        ),
      );

      return projects;
    });
  }

  // ============================================================
  // SINGLE PROJECT
  // ============================================================

  Stream<Project?> watchProject(String projectId) {
    return _projects.doc(projectId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      return Project.fromMap(snapshot.id, data);
    });
  }

  // ============================================================
  // CHALLENGE FOR PROJECT
  // ============================================================

  Stream<Challenge?> watchChallenge(String challengeId) {
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
  // MY INTERESTS
  // ============================================================

  Stream<List<CollaborationInterest>> watchMyInterests(String organizationId) {
    return _interests
        .where('industryOrganizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
          final interests = snapshot.docs
              .map(
                (doc) =>
                    CollaborationInterest.fromMap(id: doc.id, map: doc.data()),
              )
              .toList();

          interests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return interests;
        });
  }

  // ============================================================
  // ACCEPTED COLLABORATIONS
  // ============================================================

  Stream<List<CollaborationInterest>> watchMyCollaborations(
    String organizationId,
  ) {
    return watchMyInterests(
      organizationId,
    ).map((items) => items.where((item) => item.isAccepted).toList());
  }

  // ============================================================
  // INTEREST FOR ONE PROJECT
  // ============================================================

  Stream<CollaborationInterest?> watchInterestForProject({
    required String projectId,
    required String organizationId,
  }) {
    final interestId = _interestId(
      projectId: projectId,
      organizationId: organizationId,
    );

    return _interests.doc(interestId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return CollaborationInterest.fromMap(
        id: snapshot.id,
        map: snapshot.data()!,
      );
    });
  }

  // ============================================================
  // EXPRESS INTEREST
  // ============================================================

  Future<void> expressInterest({
    required String projectId,
    required String contributionType,
    required String message,
  }) async {
    final identity = await requireIndustryIdentity();

    if (contributionType.trim().isEmpty) {
      throw Exception('Please select how your organization can contribute.');
    }

    if (message.trim().isEmpty) {
      throw Exception('Please provide a short collaboration message.');
    }

    final projectRef = _projects.doc(projectId);

    final projectSnapshot = await projectRef.get();

    if (!projectSnapshot.exists || projectSnapshot.data() == null) {
      throw Exception('Project not found.');
    }

    final project = Project.fromMap(
      projectSnapshot.id,
      projectSnapshot.data()!,
    );

    final projectStatus = project.status.trim().toLowerCase();

    if (projectStatus != 'active' && projectStatus != 'solution_deployed') {
      throw Exception(
        'This project is not currently available for collaboration.',
      );
    }

    final interestId = _interestId(
      projectId: project.id,
      organizationId: identity.organizationId,
    );

    final interestRef = _interests.doc(interestId);

    await _db.runTransaction((transaction) async {
      final current = await transaction.get(interestRef);

      if (current.exists && current.data() != null) {
        final existing = CollaborationInterest.fromMap(
          id: current.id,
          map: current.data()!,
        );

        if (existing.isPending) {
          throw Exception(
            'Interest has already been submitted for this project.',
          );
        }

        if (existing.isAccepted) {
          throw Exception(
            'Your organization is already collaborating on this project.',
          );
        }
      }

      final timestamp = FieldValue.serverTimestamp();

      transaction.set(interestRef, {
        'id': interestId,

        'projectId': project.id,

        'challengeId': project.challengeId,

        'universityId': project.universityId,

        'universityName': project.universityName,

        'industryOrganizationId': identity.organizationId,

        'industryName': identity.organizationName,

        'submittedById': identity.uid,

        'submittedByName': identity.fullName,

        'contributionType': contributionType.trim(),

        'message': message.trim(),

        'status': 'pending',

        'createdAt': timestamp,

        'updatedAt': timestamp,

        'acceptedAt': null,

        'rejectedAt': null,

        'decisionById': null,

        'decisionByName': null,
      }, SetOptions(merge: false));
    });
  }

  // ============================================================
  // WITHDRAW INTEREST
  // ============================================================

  Future<void> withdrawInterest(String interestId) async {
    final identity = await requireIndustryIdentity();

    final ref = _interests.doc(interestId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Interest request not found.');
      }

      final interest = CollaborationInterest.fromMap(
        id: snapshot.id,
        map: snapshot.data()!,
      );

      if (interest.industryOrganizationId != identity.organizationId) {
        throw Exception('You cannot modify this request.');
      }

      if (!interest.isPending) {
        throw Exception('Only pending requests can be withdrawn.');
      }

      transaction.update(ref, {
        'status': 'withdrawn',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ============================================================
  // CHAT
  // ============================================================

  Stream<List<CollaborationMessage>> watchMessages(String collaborationId) {
    return _interests
        .doc(collaborationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    CollaborationMessage.fromMap(id: doc.id, map: doc.data()),
              )
              .toList(),
        );
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage({
    required String collaborationId,
    required String text,
  }) async {
    final message = text.trim();

    if (message.isEmpty) {
      return;
    }

    final identity = await requireIndustryIdentity();

    final interestRef = _interests.doc(collaborationId);

    final interestSnapshot = await interestRef.get();

    if (!interestSnapshot.exists || interestSnapshot.data() == null) {
      throw Exception('Collaboration not found.');
    }

    final collaboration = CollaborationInterest.fromMap(
      id: interestSnapshot.id,
      map: interestSnapshot.data()!,
    );

    if (collaboration.industryOrganizationId != identity.organizationId) {
      throw Exception('You cannot access this collaboration.');
    }

    if (!collaboration.isAccepted) {
      throw Exception(
        'Chat becomes available after the university accepts the collaboration.',
      );
    }

    final messageRef = interestRef.collection('messages').doc();

    final batch = _db.batch();

    batch.set(messageRef, {
      'id': messageRef.id,

      'senderId': identity.uid,

      'senderName': identity.fullName,

      'senderRole': 'industry',

      'text': message,

      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(interestRef, {
      'lastMessage': message,

      'lastMessageAt': FieldValue.serverTimestamp(),

      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ============================================================
  // ID
  // ============================================================

  String _interestId({
    required String projectId,
    required String organizationId,
  }) {
    return '${projectId}_$organizationId';
  }
}
