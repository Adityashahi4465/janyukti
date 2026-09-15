import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/providers/instance_providers.dart';
import '../models/challenge_model.dart';
import '../models/university_model.dart';
import '../models/university_recommendation.dart';

final aiApiProvider = Provider<AiApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  final auth = ref.watch(firebaseAuthProvider);
  return AiApi(
    client: client,
    token: () async => auth.currentUser?.getIdToken(),
  );
});

class AiException implements Exception {
  const AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AiAnalysis {
  AiAnalysis(this.data) {
    if (!categories.contains(category) ||
        !['Low', 'Medium', 'High', 'Critical'].contains(priority)) {
      throw const AiException('AI returned an invalid category or priority.');
    }
  }
  static const categories = [
    'Water Management',
    'Waste Management',
    'Agriculture',
    'Infrastructure',
    'Healthcare',
    'Education',
    'Other',
  ];
  final Map<String, dynamic> data;
  String get category => data['appCategory'] as String? ?? '';
  String get priority => data['priority'] as String? ?? '';
  String get rationale => data['rationale'] as String? ?? '';
  bool get needsReview => data['needsReview'] == true;
}

class AiApi {
  AiApi({
    required this.client,
    required this.token,
    String? baseUrl,
    this.timeout = const Duration(seconds: 45),
  }) : baseUrl = (baseUrl ?? defaultBaseUrl).replaceFirst(RegExp(r'/+$'), '');

  static String get defaultBaseUrl {
    const configured = String.fromEnvironment('AI_API_URL');
    if (configured.isNotEmpty) return configured;
    if (kReleaseMode) return '';
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  final http.Client client;
  final Future<String?> Function() token;
  final String baseUrl;
  final Duration timeout;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (baseUrl.isEmpty) {
      throw const AiException('AI service is not configured.');
    }
    try {
      final idToken = await token().timeout(timeout);
      final response = await client
          .post(
            Uri.parse('$baseUrl/ai/$path'),
            headers: {
              'Content-Type': 'application/json',
              if (idToken != null) 'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(data),
          )
          .timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AiException('Please sign in again to use AI suggestions.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiException(
          'AI request failed (${response.statusCode}). Please retry.',
        );
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on AiException {
      rethrow;
    } on TimeoutException {
      throw const AiException('AI is taking too long. Please retry.');
    } catch (_) {
      throw const AiException('Unable to reach the AI service. Please retry.');
    }
  }

  Future<AiAnalysis> analyze(Map<String, dynamic> draft) async =>
      AiAnalysis(await post('analyze', {...draft, 'index': false}));

  static Map<String, dynamic> challengeText(Challenge challenge) => {
    'title': challenge.title,
    'description': challenge.description,
    'additionalInfo': challenge.additionalInfo,
    'category': challenge.category,
    'location': challenge.location,
  };

  Future<Map<String, dynamic>> checkDuplicates(
    Challenge challenge,
    List<Challenge> existing,
  ) async {
    // Non-pruning batches also backfill challenges submitted while AI was offline.
    for (var offset = 0; offset < existing.length; offset += 2000) {
      await post('index/sync', {
        'prune': false,
        'challenges': existing
            .skip(offset)
            .take(2000)
            .map(
              (item) => {
                ...challengeText(item),
                'id': item.id,
                'status': item.status,
                'submittedByUid': item.submittedById,
              },
            )
            .toList(),
      });
    }
    return post('duplicates', {
      ...challengeText(challenge),
      'excludeChallengeId': challenge.id,
    });
  }

  Future<List<UniversityRecommendation>> match(
    Challenge challenge,
    List<UniversityModel> universities, {
    int limit = 10,
  }) async {
    if (universities.isEmpty) return [];
    if (universities.length > 500) {
      throw const AiException(
        'Too many universities for one matching request.',
      );
    }
    final result = await post('match', {
      ...challengeText(challenge),
      'challengeId': challenge.id,
      'topK': limit.clamp(1, 20),
      'directoryK': 0,
      'organizations': universities
          .map(
            (u) => {
              'id': u.id,
              'name': u.name,
              'city': u.city,
              'state': u.state,
              'type': u.type,
            },
          )
          .toList(),
    });
    final byId = {
      for (final university in universities) university.id: university,
    };
    return (result['registered'] as List).map((raw) {
      final data = raw as Map<String, dynamic>;
      final university = byId[data['organizationId']];
      if (university == null) {
        throw const AiException(
          'AI returned an unknown university. Please retry.',
        );
      }
      return UniversityRecommendation(
        university: university,
        score: (data['score'] as num).toDouble(),
        reasons: List<String>.from(data['reasons'] as List? ?? []),
      );
    }).toList();
  }
}
