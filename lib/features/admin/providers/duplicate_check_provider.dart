import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apis/ai_api.dart';
import '../../../apis/challenges_api.dart';

final duplicateCheckProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, challengeId) async {
      final api = ref.watch(challengesApiProvider);
      final ai = ref.watch(aiApiProvider);
      final challenge = await api.getChallenge(challengeId);
      if (challenge == null) throw const AiException('Challenge not found.');
      final existing = await api.watchChallenges().first;
      final result = await ai.checkDuplicates(challenge, existing);
      final ids = existing.map((item) => item.id).toSet();
      // A non-pruning index may retain deleted documents; never show those as matches.
      final candidates =
          List<Map<String, dynamic>>.from(result['candidates'] as List)
              .where(
                (item) =>
                    item['challengeId'] != challengeId &&
                    ids.contains(item['challengeId']),
              )
              .toList();
      return {...result, 'candidates': candidates};
    });
