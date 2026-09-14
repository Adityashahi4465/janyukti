import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';
import '../controllers/university_controller.dart';

class UniversityChallengeDetails extends ConsumerWidget {
  const UniversityChallengeDetails({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(universityChallengeProvider(challengeId));

    final projectAsync = ref.watch(universityProjectProvider(challengeId));

    return PageFrame(
      title: 'Challenge Details',
      color: AppColors.university,
      child: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, _) => Center(child: Text(error.toString())),

        data: (challenge) {
          if (challenge == null) {
            return const Center(child: Text('Challenge not found.'));
          }

          final project = projectAsync.asData?.value;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                challenge.title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              StatusPill(challenge.status),

              const SizedBox(height: 16),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Challenge ID  ${challenge.id}'),

                    const Divider(),

                    Text('Category  ${challenge.category}'),

                    const SizedBox(height: 8),

                    Text('Location  ${challenge.location}'),

                    const SizedBox(height: 8),

                    Text('Priority  ${challenge.priority}'),

                    const Divider(),

                    Text(challenge.description),

                    if (challenge.additionalInfo.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),

                      Text(challenge.additionalInfo),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (project == null)
                RoleButton(
                  label: 'Create Project & Start Work',
                  color: AppColors.university,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.createProject,
                      arguments: challenge.id,
                    );
                  },
                  icon: Icons.play_arrow_rounded,
                )
              else
                RoleButton(
                  label: 'Open Project Workspace',
                  color: AppColors.university,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.workspace,
                      arguments: challenge.id,
                    );
                  },
                  icon: Icons.dashboard_outlined,
                ),
            ],
          );
        },
      ),
    );
  }
}
