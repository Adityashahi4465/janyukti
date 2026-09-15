import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apis/industry_api.dart';
import '../../../models/challenge_model.dart';
import '../../../models/industry_models.dart';
import '../../../models/project_model.dart';

// ============================================================
// CURRENT INDUSTRY
// ============================================================

final currentIndustryIdentityProvider =
    FutureProvider.autoDispose<IndustryIdentity>((ref) async {
      return ref.watch(industryApiProvider).requireIndustryIdentity();
    });

// ============================================================
// AVAILABLE PROJECTS
// ============================================================

final industryProjectsProvider = StreamProvider.autoDispose<List<Project>>((
  ref,
) async* {
  await ref.watch(currentIndustryIdentityProvider.future);

  yield* ref.watch(industryApiProvider).watchAvailableProjects();
});

// ============================================================
// SINGLE PROJECT
// ============================================================

final industryProjectProvider = StreamProvider.autoDispose
    .family<Project?, String>((ref, projectId) async* {
      await ref.watch(currentIndustryIdentityProvider.future);

      yield* ref.watch(industryApiProvider).watchProject(projectId);
    });

// ============================================================
// CHALLENGE
// ============================================================

final industryChallengeProvider = StreamProvider.autoDispose
    .family<Challenge?, String>((ref, challengeId) async* {
      await ref.watch(currentIndustryIdentityProvider.future);

      yield* ref.watch(industryApiProvider).watchChallenge(challengeId);
    });

// ============================================================
// MY INTERESTS
// ============================================================

final industryInterestsProvider =
    StreamProvider.autoDispose<List<CollaborationInterest>>((ref) async* {
      final identity = await ref.watch(currentIndustryIdentityProvider.future);

      yield* ref
          .watch(industryApiProvider)
          .watchMyInterests(identity.organizationId);
    });

// ============================================================
// ACTIVE COLLABORATIONS
// ============================================================

final industryCollaborationsProvider =
    StreamProvider.autoDispose<List<CollaborationInterest>>((ref) async* {
      final identity = await ref.watch(currentIndustryIdentityProvider.future);

      yield* ref
          .watch(industryApiProvider)
          .watchMyCollaborations(identity.organizationId);
    });

// ============================================================
// INTEREST FOR PROJECT
// ============================================================

final industryProjectInterestProvider = StreamProvider.autoDispose
    .family<CollaborationInterest?, String>((ref, projectId) async* {
      final identity = await ref.watch(currentIndustryIdentityProvider.future);

      yield* ref
          .watch(industryApiProvider)
          .watchInterestForProject(
            projectId: projectId,
            organizationId: identity.organizationId,
          );
    });

// ============================================================
// CHAT MESSAGES
// ============================================================

final collaborationMessagesProvider = StreamProvider.autoDispose
    .family<List<CollaborationMessage>, String>((ref, collaborationId) {
      return ref.watch(industryApiProvider).watchMessages(collaborationId);
    });

// ============================================================
// ACTION CONTROLLER
// ============================================================

final industryControllerProvider =
    NotifierProvider<IndustryController, AsyncValue<void>>(
      IndustryController.new,
    );

// ============================================================
// INDUSTRY CONTROLLER
// ============================================================

class IndustryController extends Notifier<AsyncValue<void>> {
  IndustryApi get _api => ref.read(industryApiProvider);

  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  // ==========================================================
  // EXPRESS INTEREST
  // ==========================================================

  Future<void> expressInterest({
    required String projectId,
    required String contributionType,
    required String message,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _api.expressInterest(
        projectId: projectId,
        contributionType: contributionType,
        message: message,
      ),
    );
  }

  // ==========================================================
  // WITHDRAW INTEREST
  // ==========================================================

  Future<void> withdrawInterest(String interestId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() => _api.withdrawInterest(interestId));
  }

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================

  Future<void> sendMessage({
    required String collaborationId,
    required String text,
  }) async {
    await _api.sendMessage(collaborationId: collaborationId, text: text);
  }
}
