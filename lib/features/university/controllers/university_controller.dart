import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apis/universites_api.dart';
import '../../../models/challenge_model.dart';
import '../../../models/project_model.dart';
import '../../../models/project_update_model.dart';
import '../../../models/university_recommendation.dart';

import '../../citizen/controllers/citizen_controller.dart';

// ============================================================
// CURRENT UNIVERSITY ID
// ============================================================

final currentUniversityIdProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final api = ref.watch(universitiesApiProvider);

  final user = await api.requireUniversityUser();

  final universityId = user.universityId?.trim();

  if (universityId == null || universityId.isEmpty) {
    throw Exception('University account is not linked to a university.');
  }

  return universityId;
});

// ============================================================
// ASSIGNED CHALLENGES
// ============================================================

final assignedUniversityChallengesProvider =
    StreamProvider.autoDispose<List<Challenge>>((ref) async* {
      final universityId = await ref.watch(currentUniversityIdProvider.future);

      final api = ref.watch(universitiesApiProvider);

      yield* api.watchAssignedChallenges(universityId);
    });

// ============================================================
// UNIVERSITY PROJECTS
// ============================================================

final universityProjectsProvider = StreamProvider.autoDispose<List<Project>>((
  ref,
) async* {
  final universityId = await ref.watch(currentUniversityIdProvider.future);

  final api = ref.watch(universitiesApiProvider);

  yield* api.watchProjects(universityId);
});

// ============================================================
// SINGLE CHALLENGE
// ============================================================

final universityChallengeProvider = StreamProvider.autoDispose
    .family<Challenge?, String>((ref, challengeId) {
      return ref.watch(universitiesApiProvider).watchChallenge(challengeId);
    });

// ============================================================
// SINGLE PROJECT
// ============================================================

final universityProjectProvider = StreamProvider.autoDispose
    .family<Project?, String>((ref, challengeId) {
      return ref.watch(universitiesApiProvider).watchProject(challengeId);
    });

// ============================================================
// PROJECT UPDATES
// ============================================================

final universityProjectUpdatesProvider = StreamProvider.autoDispose
    .family<List<ProjectUpdate>, String>((ref, challengeId) {
      return ref
          .watch(universitiesApiProvider)
          .watchProjectUpdates(challengeId);
    });

// ============================================================
// UNIVERSITY RECOMMENDATIONS FOR ADMIN
// ============================================================

final universityRecommendationsProvider = FutureProvider.autoDispose
    .family<List<UniversityRecommendation>, String>((ref, challengeId) async {
      final challenge = await ref.watch(challengeProvider(challengeId).future);

      if (challenge == null) {
        throw Exception('Challenge not found.');
      }

      final api = ref.watch(universitiesApiProvider);

      return api.getBestUniversitiesForChallenge(challenge, limit: 10);
    });
