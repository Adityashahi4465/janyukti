import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apis/universites_api.dart';
import '../../../models/project_model.dart';
import '../../../models/project_update_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';
import '../controllers/university_controller.dart';

class ProjectWorkspace extends ConsumerWidget {
  const ProjectWorkspace({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(universityProjectProvider(challengeId));

    final challengeAsync = ref.watch(universityChallengeProvider(challengeId));

    final updatesAsync = ref.watch(
      universityProjectUpdatesProvider(challengeId),
    );

    return PageFrame(
      title: 'Project Workspace',
      color: AppColors.university,
      child: projectAsync.when(
        // ========================================================
        // LOADING
        // ========================================================
        loading: () => const Center(child: CircularProgressIndicator()),

        // ========================================================
        // ERROR
        // ========================================================
        error: (error, _) => _ErrorState(
          message: _cleanError(error),
          onRetry: () {
            ref.invalidate(universityProjectProvider(challengeId));

            ref.invalidate(universityChallengeProvider(challengeId));

            ref.invalidate(universityProjectUpdatesProvider(challengeId));
          },
        ),

        // ========================================================
        // PROJECT
        // ========================================================
        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found.'));
          }

          final challenge = challengeAsync.asData?.value;

          final status = project.status.trim().toLowerCase();

          final deployed =
              status == 'solution_deployed' ||
              challenge?.status.trim().toLowerCase() == 'solution deployed';

          final resolved =
              challenge?.status.trim().toLowerCase() == 'resolved' ||
              challenge?.status.trim().toLowerCase() == 'completed';

          final canPostProgress =
              !deployed && !resolved && project.progress < 100;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(universityProjectProvider(challengeId));

              ref.invalidate(universityChallengeProvider(challengeId));

              ref.invalidate(universityProjectUpdatesProvider(challengeId));

              await ref.read(universityProjectProvider(challengeId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                _ProjectHeader(
                  project: project,
                  challengeTitle: challenge?.title,
                  challengeStatus: challenge?.status,
                ),

                // ==================================================
                // CHALLENGE INFORMATION
                // ==================================================
                if (challenge != null) ...[
                  section('Challenge'),

                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Challenge ID',
                          value: challenge.id,
                        ),

                        const Divider(height: 28),

                        _InfoRow(
                          icon: Icons.category_outlined,
                          label: 'Category',
                          value: challenge.category,
                        ),

                        const Divider(height: 28),

                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: challenge.location,
                        ),

                        const Divider(height: 28),

                        _InfoRow(
                          icon: Icons.flag_outlined,
                          label: 'Priority',
                          value: challenge.priority,
                        ),

                        if (challenge.description.trim().isNotEmpty) ...[
                          const Divider(height: 28),

                          _InfoRow(
                            icon: Icons.description_outlined,
                            label: 'Challenge',
                            value: challenge.description,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // ==================================================
                // PROJECT INFORMATION
                // ==================================================
                section('Project Information'),

                AppCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.school_outlined,
                        label: 'University',
                        value: project.universityName,
                      ),

                      const Divider(height: 28),

                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Faculty Mentor',
                        value: project.mentor,
                      ),

                      const Divider(height: 28),

                      _InfoRow(
                        icon: Icons.groups_outlined,
                        label: 'Team Members',
                        value: project.teamMembers.isEmpty
                            ? 'No team members added'
                            : project.teamMembers.join(', '),
                      ),

                      if (project.createdByName.trim().isNotEmpty) ...[
                        const Divider(height: 28),

                        _InfoRow(
                          icon: Icons.person_add_alt_outlined,
                          label: 'Project Created By',
                          value: project.createdByName,
                        ),
                      ],

                      if (project.createdAt != null) ...[
                        const Divider(height: 28),

                        _InfoRow(
                          icon: Icons.schedule_outlined,
                          label: 'Created',
                          value: _formatDate(project.createdAt!),
                        ),
                      ],
                    ],
                  ),
                ),

                // ==================================================
                // MILESTONES
                // ==================================================
                section('Milestones'),

                if (project.milestones.isEmpty)
                  const AppCard(
                    child: Text(
                      'No milestones configured.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  for (var i = 0; i < project.milestones.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MilestoneCard(
                        number: i + 1,
                        milestone: project.milestones[i],
                      ),
                    ),

                // ==================================================
                // PROJECT UPDATES
                // ==================================================
                section('Project Updates'),

                updatesAsync.when(
                  loading: () => const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                  error: (error, _) => AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                        ),

                        const SizedBox(width: 10),

                        Expanded(child: Text(_cleanError(error))),

                        IconButton(
                          onPressed: () {
                            ref.invalidate(
                              universityProjectUpdatesProvider(challengeId),
                            );
                          },
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ),

                  data: (updates) {
                    if (updates.isEmpty) {
                      return const AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No progress updates have been posted yet.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final update in updates)
                          _ProjectUpdateCard(update: update),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 22),

                // ==================================================
                // ACTIONS
                // ==================================================
                if (resolved)
                  _ResolvedCard()
                else if (deployed)
                  _SolutionSubmittedCard()
                else ...[
                  if (canPostProgress)
                    RoleButton(
                      label: 'Post Progress Update',
                      color: AppColors.university,
                      icon: Icons.update_rounded,
                      onTap: () => _showProgressDialog(context, ref, project),
                    ),

                  if (canPostProgress) const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => _showSolutionDialog(context, ref, project),
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: const Text('Submit Solution'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.university,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.muted,
                      ),

                      SizedBox(width: 7),

                      Expanded(
                        child: Text(
                          'Submitting the solution marks the challenge as Solution Deployed. The administrator performs the final verification and resolution.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // POST PROGRESS UPDATE
  // ============================================================

  Future<void> _showProgressDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final result = await showDialog<_ProgressResult>(
      context: context,
      builder: (_) => _ProgressDialog(currentProgress: project.progress),
    );

    if (result == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(universitiesApiProvider)
          .postProgressUpdate(
            challengeId: project.challengeId,
            title: result.title,
            description: result.description,
            progress: result.progress,
          );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Progress update posted successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_cleanError(error)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ============================================================
  // SUBMIT SOLUTION
  // ============================================================

  Future<void> _showSolutionDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final result = await showDialog<_SolutionResult>(
      context: context,
      builder: (_) => const _SolutionDialog(),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Submit Solution?'),
          content: const Text(
            'The project will be marked as Solution Deployed and sent to the administrator for final review. Progress updates will be locked after submission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(universitiesApiProvider)
          .submitSolution(
            challengeId: project.challengeId,
            title: result.title,
            description: result.description,
          );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Solution submitted successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_cleanError(error)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

// ============================================================
// PROJECT HEADER
// ============================================================

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.project,
    this.challengeTitle,
    this.challengeStatus,
  });

  final Project project;
  final String? challengeTitle;
  final String? challengeStatus;

  @override
  Widget build(BuildContext context) {
    final status = challengeStatus?.trim().isNotEmpty == true
        ? challengeStatus!
        : project.status;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.darkPurpleTextGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${project.challengeId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              StatusPill(status),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            project.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),

          if (challengeTitle != null && challengeTitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),

            Text(
              challengeTitle!,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ],

          const SizedBox(height: 18),

          Row(
            children: [
              const Text(
                'Project Progress',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),

              const Spacer(),

              Text(
                '${project.progress}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: project.progress.clamp(0, 100) / 100,
              minHeight: 9,
              backgroundColor: Colors.white.withOpacity(.20),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: AppColors.university.withOpacity(.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: AppColors.university),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.trim().isEmpty ? 'Not provided' : value,
                style: const TextStyle(
                  color: AppColors.title,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// MILESTONE
// ============================================================

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.number, required this.milestone});

  final int number;
  final ProjectMilestone milestone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (milestone.completed ? Colors.green : AppColors.university)
                  .withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: milestone.completed
                ? const Icon(Icons.check_rounded, color: Colors.green)
                : Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: AppColors.university,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 3),

                Text(
                  milestone.completed
                      ? milestone.completedAt != null
                            ? 'Completed ${_formatDate(milestone.completedAt!)}'
                            : 'Completed'
                      : 'Pending',
                  style: TextStyle(
                    color: milestone.completed ? Colors.green : AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROJECT UPDATE
// ============================================================

class _ProjectUpdateCard extends StatelessWidget {
  const _ProjectUpdateCard({required this.update});

  final ProjectUpdate update;

  @override
  Widget build(BuildContext context) {
    final type = update.type.trim().toLowerCase();

    final solution = type == 'solution';

    final blocker = type == 'blocker';

    final color = solution
        ? Colors.green
        : blocker
        ? Colors.orange
        : AppColors.university;

    final icon = solution
        ? Icons.rocket_launch_outlined
        : blocker
        ? Icons.warning_amber_rounded
        : Icons.update_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withOpacity(.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          update.title.trim().isEmpty
                              ? solution
                                    ? 'Solution Submitted'
                                    : 'Progress Update'
                              : update.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${update.progressPercent}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (update.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),

                    Text(
                      update.description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 13,
                        color: AppColors.muted,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          update.createdByName.trim().isEmpty
                              ? update.universityName
                              : update.createdByName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9.5,
                          ),
                        ),
                      ),

                      Text(
                        _formatDate(update.createdAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROGRESS RESULT
// ============================================================

class _ProgressResult {
  const _ProgressResult({
    required this.title,
    required this.description,
    required this.progress,
  });

  final String title;
  final String description;
  final int progress;
}

// ============================================================
// PROGRESS DIALOG
// ============================================================

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({required this.currentProgress});

  final int currentProgress;

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  final title = TextEditingController();

  final description = TextEditingController();

  final form = GlobalKey<FormState>();

  late double progress;

  @override
  void initState() {
    super.initState();

    progress = widget.currentProgress.clamp(0, 100).toDouble();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.currentProgress.clamp(0, 100);

    final remaining = 100 - current;

    return AlertDialog(
      title: const Text('Post Progress Update'),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'Update title *',
                  hintText: 'e.g. Field survey completed',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Update title is required.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: description,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Progress details *',
                  hintText:
                      'Describe what was completed, findings or next steps.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Progress details are required.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),

                  const Spacer(),

                  Text(
                    '${progress.round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.university,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              Slider(
                value: progress,
                min: current.toDouble(),
                max: 100,
                divisions: remaining > 0 ? remaining : null,
                activeColor: AppColors.university,
                onChanged: remaining == 0
                    ? null
                    : (value) {
                        setState(() {
                          progress = value;
                        });
                      },
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Current progress: $current%',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.university),
          onPressed: () {
            if (!form.currentState!.validate()) {
              return;
            }

            Navigator.pop(
              context,
              _ProgressResult(
                title: title.text.trim(),
                description: description.text.trim(),
                progress: progress.round(),
              ),
            );
          },
          child: const Text('Post Update'),
        ),
      ],
    );
  }
}

// ============================================================
// SOLUTION RESULT
// ============================================================

class _SolutionResult {
  const _SolutionResult({required this.title, required this.description});

  final String title;
  final String description;
}

// ============================================================
// SOLUTION DIALOG
// ============================================================

class _SolutionDialog extends StatefulWidget {
  const _SolutionDialog();

  @override
  State<_SolutionDialog> createState() => _SolutionDialogState();
}

class _SolutionDialogState extends State<_SolutionDialog> {
  final title = TextEditingController();

  final description = TextEditingController();

  final form = GlobalKey<FormState>();

  @override
  void dispose() {
    title.dispose();
    description.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Solution'),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.university.withOpacity(.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.university,
                      size: 19,
                    ),

                    SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Submitting the solution will move this challenge to Solution Deployed. The administrator will perform the final verification.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'Solution title *',
                  hintText: 'e.g. Smart Waste Monitoring System',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Solution title is required.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: description,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Solution summary *',
                  hintText:
                      'Describe the implemented solution, outcome and impact.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Solution summary is required.';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.university),
          onPressed: () {
            if (!form.currentState!.validate()) {
              return;
            }

            Navigator.pop(
              context,
              _SolutionResult(
                title: title.text.trim(),
                description: description.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text('Continue'),
        ),
      ],
    );
  }
}

// ============================================================
// SOLUTION SUBMITTED
// ============================================================

class _SolutionSubmittedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, color: Colors.green),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solution Submitted',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'The solution has been deployed and submitted for administrator verification. No further progress updates can be posted.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RESOLVED
// ============================================================

class _ResolvedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge Resolved',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'The administrator has verified the solution and marked this challenge as resolved.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 12),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

String _formatDate(DateTime date) {
  final local = date.toLocal();

  final day = local.day.toString().padLeft(2, '0');

  final month = local.month.toString().padLeft(2, '0');

  final hour = local.hour.toString().padLeft(2, '0');

  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/${local.year} $hour:$minute';
}
