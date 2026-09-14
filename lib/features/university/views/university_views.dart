import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';
import '../../auth/services/auth_session.dart';
import '../controllers/university_controller.dart';

class UniversityDashboard extends ConsumerWidget {
  const UniversityDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(assignedUniversityChallengesProvider);

    final projectsAsync = ref.watch(universityProjectsProvider);

    return PageFrame(
      title: 'University Dashboard',
      color: AppColors.university,
      actions: [
        IconButton(
          onPressed: () => AuthSession.signOut(context),
          icon: const Icon(Icons.logout_outlined),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(assignedUniversityChallengesProvider);

          ref.invalidate(universityProjectsProvider);

          await ref.read(assignedUniversityChallengesProvider.future);
        },
        child: challengesAsync.when(
          loading: () => ListView(
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 350,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),

          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              AppCard(
                child: Text(error.toString().replaceFirst('Exception: ', '')),
              ),
            ],
          ),

          data: (challenges) {
            final projects = projectsAsync.asData?.value ?? const [];

            final active = challenges
                .where(
                  (challenge) =>
                      challenge.status.toLowerCase() == 'in progress',
                )
                .length;

            final deployed = challenges
                .where(
                  (challenge) =>
                      challenge.status.toLowerCase() == 'solution deployed',
                )
                .length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Stat(
                        '${challenges.length}',
                        'Assigned',
                        AppColors.university,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Stat(
                        '$active',
                        'In Progress',
                        AppColors.university,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Stat(
                        '${projects.length}',
                        'Projects',
                        AppColors.university,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Stat(
                        '$deployed',
                        'Solutions',
                        AppColors.university,
                      ),
                    ),
                  ],
                ),

                section('Assigned Challenges'),

                if (challenges.isEmpty)
                  const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No challenges have been assigned to your university yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                for (final challenge in challenges)
                  _UniversityChallengeCard(challenge: challenge),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UniversityChallengeCard extends StatelessWidget {
  const _UniversityChallengeCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.challengeDetail,
        arguments: challenge.id,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.university.withOpacity(.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.university,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  challenge.location,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),

                const SizedBox(height: 7),

                StatusPill(challenge.status),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
