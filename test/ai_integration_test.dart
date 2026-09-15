import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:janyukti/core/localization/app_localizations.dart';
import 'package:janyukti/features/admin/views/challange_review.dart';
import 'package:janyukti/features/admin/providers/duplicate_check_provider.dart';
import 'package:janyukti/features/university/controllers/university_controller.dart';
import 'package:janyukti/models/university_recommendation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:janyukti/apis/ai_api.dart';
import 'package:janyukti/apis/challenges_api.dart';
import 'package:janyukti/core/utils/cloudinary_service.dart';
import 'package:janyukti/features/citizen/controllers/citizen_controller.dart';
import 'package:janyukti/models/challenge_model.dart';
import 'package:janyukti/models/university_model.dart';

Challenge challenge(String id) => Challenge(
  id: id,
  title: 'Contaminated drinking water',
  category: 'Water Management',
  location: 'Ranchi, Jharkhand',
  description: 'Residents are ill after drinking tap water.',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

AiApi apiWith(http.Client client, {Duration? timeout}) => AiApi(
  client: client,
  token: () async => 'firebase-token',
  baseUrl: 'http://localhost:8000/',
  timeout: timeout ?? const Duration(seconds: 1),
);

class SavingApi implements ChallengesApi {
  Challenge? saved;
  @override
  String get currentUserId => 'citizen';
  @override
  String get currentUserName => 'Citizen';
  @override
  String generateChallengeId() => 'saved-id';
  @override
  Future<Challenge> createChallenge(Challenge value) async {
    saved = value;
    return value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'admin waits for duplicate review and displays matches before assignment',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final duplicates = Completer<Map<String, dynamic>>();
      final language = LanguageController();
      addTearDown(language.dispose);
      final item = challenge('current');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            challengeStreamProvider(
              'current',
            ).overrideWith((ref) => Stream.value(item)),
            duplicateCheckProvider(
              'current',
            ).overrideWith((ref) => duplicates.future),
            universityRecommendationsProvider('current').overrideWith(
              (ref) async => [
                const UniversityRecommendation(
                  university: UniversityModel(
                    id: 'u',
                    name: 'University',
                    normalizedName: 'university',
                  ),
                  score: .87,
                  reasons: ['Water expertise'],
                ),
              ],
            ),
          ],
          child: LanguageScope(
            controller: language,
            child: MaterialApp(home: ChallengeReview(x: item)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final button = find.ancestor(
        of: find.text('Assign University'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      duplicates.complete({
        'candidates': [
          {
            'challengeId': 'other',
            'title': 'Existing water issue',
            'score': .91,
            'status': 'Assigned',
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text('Existing water issue'), findsOneWidget);
      expect(find.text('87% match'), findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Assign Challenge?'), findsOneWidget);
      expect(
        find.textContaining('reviewed the duplicate check'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'draft analysis authenticates, uses camelCase and never indexes a draft',
    () async {
      final api = apiWith(
        MockClient((request) async {
          expect(request.url.path, '/ai/analyze');
          expect(request.headers['Authorization'], 'Bearer firebase-token');
          final body = jsonDecode(request.body) as Map;
          expect(body['index'], false);
          expect(body['additionalInfo'], 'Urgent');
          return http.Response(
            jsonEncode({
              'appCategory': 'Healthcare',
              'priority': 'High',
              'needsReview': true,
              'rationale': 'Health risk',
            }),
            200,
          );
        }),
      );
      final result = await api.analyze({
        ...AiApi.challengeText(challenge('draft')),
        'additionalInfo': 'Urgent',
      });
      expect(result.category, 'Healthcare');
      expect(result.priority, 'High');
      expect(result.needsReview, true);
    },
  );

  test('invalid AI classifications are rejected', () async {
    final api = apiWith(
      MockClient(
        (_) async => http.Response(
          '{"appCategory":"Unsupported","priority":"High"}',
          200,
        ),
      ),
    );
    await expectLater(api.analyze({}), throwsA(isA<AiException>()));
  });

  test(
    'authentication, malformed response and network errors are actionable',
    () async {
      for (final status in [401, 403, 422, 500]) {
        final api = apiWith(
          MockClient((_) async => http.Response('private detail', status)),
        );
        await expectLater(api.analyze({}), throwsA(isA<AiException>()));
      }
      final malformed = apiWith(
        MockClient((_) async => http.Response('not json', 200)),
      );
      await expectLater(malformed.analyze({}), throwsA(isA<AiException>()));
      final offline = apiWith(
        MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(offline.analyze({}), throwsA(isA<AiException>()));
    },
  );

  test('AI requests time out', () async {
    final api = apiWith(
      MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 5),
    );
    await expectLater(api.analyze({}), throwsA(isA<AiException>()));
  });

  test(
    'admin syncs all batches without pruning before excluding the current challenge',
    () async {
      final paths = <String>[];
      final sizes = <int>[];
      final api = apiWith(
        MockClient((request) async {
          paths.add(request.url.path);
          final body = jsonDecode(request.body) as Map;
          if (request.url.path.endsWith('/sync')) {
            expect(body['prune'], false);
            sizes.add((body['challenges'] as List).length);
            expect(body['challenges'][0]['status'], 'Submitted');
            return http.Response('{}', 200);
          }
          expect(body['excludeChallengeId'], 'current');
          return http.Response('{"candidates":[],"isDuplicate":false}', 200);
        }),
      );
      await api.checkDuplicates(
        challenge('current'),
        List.generate(2001, (i) => challenge('$i')),
      );
      expect(sizes, [2000, 1]);
      expect(paths, ['/ai/index/sync', '/ai/index/sync', '/ai/duplicates']);
    },
  );

  test(
    'matching keeps canonical Firestore IDs and backend scores/reasons',
    () async {
      const university = UniversityModel(
        id: 'firestore-id',
        name: 'University',
        normalizedName: 'university',
      );
      final api = apiWith(
        MockClient((request) async {
          expect(request.url.path, '/ai/match');
          final body = jsonDecode(request.body) as Map;
          expect(body['organizations'][0]['id'], 'firestore-id');
          expect(body['directoryK'], 0);
          return http.Response(
            jsonEncode({
              'registered': [
                {
                  'organizationId': 'firestore-id',
                  'score': .87,
                  'reasons': ['Water research expertise'],
                },
              ],
            }),
            200,
          );
        }),
      );
      final matches = await api.match(challenge('current'), [university]);
      expect(matches.single.university, same(university));
      expect(matches.single.percentage, 87);
      expect(matches.single.reasons, ['Water research expertise']);
    },
  );

  test('matching rejects unassignable IDs from the backend', () async {
    final api = apiWith(
      MockClient(
        (_) async => http.Response(
          '{"registered":[{"organizationId":"directory-only","score":0.9}]}',
          200,
        ),
      ),
    );
    await expectLater(
      api.match(challenge('current'), [
        const UniversityModel(
          id: 'registered',
          name: 'University',
          normalizedName: 'university',
        ),
      ]),
      throwsA(isA<AiException>()),
    );
  });

  test('submission persists selected category and AI priority', () async {
    final api = SavingApi();
    final controller = ChallengeController(
      api: api,
      cloudinary: CloudinaryService(cloudName: '', uploadPreset: ''),
    );
    addTearDown(controller.dispose);
    final result = await controller.submitChallenge(
      title: 'Water issue',
      description: 'Contaminated drinking water',
      category: 'Healthcare',
      priority: 'High',
      location: 'Ranchi',
      latitude: 23.3,
      longitude: 85.3,
    );
    expect(result, isNotNull);
    expect(api.saved!.priority, 'High');
    expect(api.saved!.category, 'Healthcare');
    expect(api.saved!.status, 'Submitted');
    expect(controller.state.hasError, false);
  });
}
