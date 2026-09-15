import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/app_routes.dart';
import '../../../models/industry_models.dart';
import '../../../models/project_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';

import '../../auth/services/auth_session.dart';
import '../controllers/industry_controller.dart';

// ============================================================
// INDUSTRY DASHBOARD
// ============================================================

class IndustryDashboard extends ConsumerWidget {
  const IndustryDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(currentIndustryIdentityProvider);

    final projectsAsync = ref.watch(industryProjectsProvider);

    final interestsAsync = ref.watch(industryInterestsProvider);

    final collaborationsAsync = ref.watch(industryCollaborationsProvider);

    final projects = projectsAsync.asData?.value ?? const <Project>[];

    final interests =
        interestsAsync.asData?.value ?? const <CollaborationInterest>[];

    final collaborations =
        collaborationsAsync.asData?.value ?? const <CollaborationInterest>[];

    final pendingInterests = interests.where((item) => item.isPending).length;

    return PageFrame(
      title: 'Industry Dashboard',
      color: AppColors.industry,
      actions: [
        IconButton(
          onPressed: () => AuthSession.signOut(context),
          icon: const Icon(Icons.logout_outlined),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(industryProjectsProvider);

          ref.invalidate(industryInterestsProvider);

          ref.invalidate(industryCollaborationsProvider);

          await ref.read(industryProjectsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
          children: [
            // ==================================================
            // WELCOME
            // ==================================================
            identityAsync.when(
              loading: () => const SizedBox.shrink(),

              error: (_, __) => const SizedBox.shrink(),

              data: (identity) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    identity.organizationName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.title,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Discover projects and collaborate with universities.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ==================================================
            // STATS
            // ==================================================
            Row(
              children: [
                Expanded(
                  child: Stat(
                    '${projects.length}',
                    'Available Projects',
                    AppColors.industry,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Stat(
                    '$pendingInterests',
                    'Pending Interests',
                    AppColors.industry,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Stat(
                    '${collaborations.length}',
                    'Collaborations',
                    AppColors.industry,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Stat(
                    '${projects.where((p) => p.status == 'solution_deployed').length}',
                    'Solutions Ready',
                    AppColors.industry,
                  ),
                ),
              ],
            ),

            // ==================================================
            // QUICK ACTION
            // ==================================================
            section('Quick Actions'),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.handshake_outlined, size: 17),
                  label: const Text('My Activity'),
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.collaborations);
                  },
                ),

                ActionChip(
                  avatar: const Icon(Icons.business_center_outlined, size: 17),
                  label: const Text('Collaborations'),
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.collaborations);
                  },
                ),
              ],
            ),

            // ==================================================
            // PROJECTS
            // ==================================================
            section('University Projects'),

            projectsAsync.when(
              loading: () => const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

              error: (error, _) => AppCard(child: Text(_cleanError(error))),

              data: (projects) {
                if (projects.isEmpty) {
                  return const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No university projects are currently available for industry collaboration.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final project in projects)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _IndustryProjectCard(project: project),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROJECT CARD
// ============================================================

class _IndustryProjectCard extends StatelessWidget {
  const _IndustryProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.projectDetail,
          arguments: project.id,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.industry.withOpacity(.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.industry,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      project.universityName.trim().isEmpty
                          ? 'University Project'
                          : project.universityName,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: project.progress.clamp(0, 100) / 100,
                    minHeight: 7,
                    color: AppColors.industry,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                '${project.progress}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.industry,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          StatusPill(_projectStatus(project.status)),
        ],
      ),
    );
  }
}

// ============================================================
// PROJECT DETAILS
// ============================================================

class ProjectDetails extends ConsumerWidget {
  const ProjectDetails({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(industryProjectProvider(projectId));

    return PageFrame(
      title: 'Project Details',
      color: AppColors.industry,
      child: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, _) => Center(child: Text(_cleanError(error))),

        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found.'));
          }

          final challengeAsync = ref.watch(
            industryChallengeProvider(project.challengeId),
          );

          final interestAsync = ref.watch(
            industryProjectInterestProvider(project.id),
          );

          final challenge = challengeAsync.asData?.value;

          final interest = interestAsync.asData?.value;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
            children: [
              // ================================================
              // PROJECT
              // ================================================
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.title,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                project.universityName,
                style: const TextStyle(color: AppColors.muted),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  StatusPill(_projectStatus(project.status)),

                  const Spacer(),

                  Text(
                    '${project.progress}% complete',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.industry,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              LinearProgressIndicator(
                value: project.progress.clamp(0, 100) / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
                color: AppColors.industry,
              ),

              section('Project Information'),

              AppCard(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.school_outlined,
                      label: 'University',
                      value: project.universityName,
                    ),

                    const Divider(height: 28),

                    _DetailRow(
                      icon: Icons.person_outline,
                      label: 'Faculty Mentor',
                      value: project.mentor,
                    ),

                    const Divider(height: 28),

                    _DetailRow(
                      icon: Icons.groups_outlined,
                      label: 'Team',
                      value: project.teamMembers.isEmpty
                          ? 'Not specified'
                          : project.teamMembers.join(', '),
                    ),
                  ],
                ),
              ),

              if (challenge != null) ...[
                section('Challenge Being Solved'),

                AppCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.assignment_outlined,
                        label: 'Challenge',
                        value: challenge.title,
                      ),

                      const Divider(height: 28),

                      _DetailRow(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: challenge.category,
                      ),

                      const Divider(height: 28),

                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: challenge.location,
                      ),

                      const Divider(height: 28),

                      _DetailRow(
                        icon: Icons.description_outlined,
                        label: 'Problem',
                        value: challenge.description,
                      ),
                    ],
                  ),
                ),
              ],

              section('Milestones'),

              for (final milestone in project.milestones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        milestone.completed
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: milestone.completed
                            ? Colors.green
                            : AppColors.muted,
                      ),
                      title: Text(milestone.title),
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              _buildInterestAction(
                context: context,
                interest: interest,
                project: project,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInterestAction({
    required BuildContext context,
    required CollaborationInterest? interest,
    required Project project,
  }) {
    if (interest == null || interest.isWithdrawn || interest.isRejected) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.industry),
          onPressed: () {
            Navigator.pushNamed(
              context,
              Routes.interest,
              arguments: project.id,
            );
          },
          icon: const Icon(Icons.handshake_outlined),
          label: const Text('Express Interest'),
        ),
      );
    }

    if (interest.isPending) {
      return _InterestStatusCard(
        icon: Icons.schedule_rounded,
        title: 'Interest Submitted',
        text: 'Your request is waiting for the university to review it.',
        color: Colors.orange,
      );
    }

    if (interest.isAccepted) {
      return Column(
        children: [
          const _InterestStatusCard(
            icon: Icons.check_circle_rounded,
            title: 'Collaboration Accepted',
            text: 'The university has accepted your collaboration request.',
            color: Colors.green,
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.industry,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.chat,
                  arguments: interest.id,
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open Collaboration Chat'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ============================================================
// EXPRESS INTEREST
// ============================================================

class ExpressInterest extends ConsumerStatefulWidget {
  const ExpressInterest({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ExpressInterest> createState() => _ExpressInterestState();
}

class _ExpressInterestState extends ConsumerState<ExpressInterest> {
  final message = TextEditingController();

  String contributionType = 'Technical Expertise';

  bool submitting = false;

  static const contributionTypes = [
    'Funding',
    'Technical Expertise',
    'Manufacturing',
    'Deployment Support',
    'Mentorship',
    'Other',
  ];

  @override
  void dispose() {
    message.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(industryProjectProvider(widget.projectId));

    return PageFrame(
      title: 'Express Interest',
      color: AppColors.industry,
      child: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, _) => Center(child: Text(_cleanError(error))),

        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      project.universityName,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),

              section('How can your organization help?'),

              DropdownButtonFormField<String>(
                initialValue: contributionType,
                items: contributionTypes
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            contributionType = value;
                          });
                        }
                      },
                decoration: const InputDecoration(
                  labelText: 'Contribution Type',
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: message,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Collaboration proposal *',
                  alignLabelWithHint: true,
                  hintText:
                      'Briefly explain how your organization can support this project.',
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.industry,
                  ),
                  onPressed: submitting ? null : _submit,
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(submitting ? 'Submitting...' : 'Submit Interest'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your collaboration proposal.'),
        ),
      );

      return;
    }

    setState(() => submitting = true);

    try {
      await ref
          .read(industryControllerProvider.notifier)
          .expressInterest(
            projectId: widget.projectId,
            contributionType: contributionType,
            message: message.text,
          );

      final state = ref.read(industryControllerProvider);

      if (state.hasError) {
        throw state.error!;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collaboration interest submitted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(error)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }
}

// ============================================================
// COLLABORATIONS
// ============================================================

class Collaborations extends ConsumerWidget {
  const Collaborations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interestsAsync = ref.watch(industryInterestsProvider);

    final collaborationsAsync = ref.watch(industryCollaborationsProvider);

    return DefaultTabController(
      length: 2,
      child: PageFrame(
        title: 'Industry Activity',
        color: AppColors.industry,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Interests'),
                Tab(text: 'Collaborations'),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _InterestList(asyncValue: interestsAsync),

                  _CollaborationList(asyncValue: collaborationsAsync),
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
// INTEREST LIST
// ============================================================

class _InterestList extends StatelessWidget {
  const _InterestList({required this.asyncValue});

  final AsyncValue<List<CollaborationInterest>> asyncValue;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),

      error: (error, _) => Center(child: Text(_cleanError(error))),

      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No collaboration interests submitted yet.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.projectDetail,
                    arguments: item.projectId,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.universityName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),

                        StatusPill(_displayStatus(item.status)),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      item.contributionType,
                      style: const TextStyle(
                        color: AppColors.industry,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      item.message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// COLLABORATION LIST
// ============================================================

class _CollaborationList extends StatelessWidget {
  const _CollaborationList({required this.asyncValue});

  final AsyncValue<List<CollaborationInterest>> asyncValue;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),

      error: (error, _) => Center(child: Text(_cleanError(error))),

      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No active collaborations yet.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () {
                  Navigator.pushNamed(context, Routes.chat, arguments: item.id);
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.industry,
                    child: Icon(Icons.handshake_outlined, color: Colors.white),
                  ),
                  title: Text(
                    item.universityName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(item.contributionType),
                  trailing: const Icon(Icons.chat_bubble_outline),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// CHAT
// ============================================================

class CollaborationChat extends ConsumerStatefulWidget {
  const CollaborationChat({super.key, required this.collaborationId});

  final String collaborationId;

  @override
  ConsumerState<CollaborationChat> createState() => _CollaborationChatState();
}

class _CollaborationChatState extends ConsumerState<CollaborationChat> {
  final messageController = TextEditingController();

  bool sending = false;

  @override
  void dispose() {
    messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      collaborationMessagesProvider(widget.collaborationId),
    );

    final identity = ref.watch(currentIndustryIdentityProvider).asData?.value;

    return PageFrame(
      title: 'Collaboration Chat',
      color: AppColors.industry,
      child: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (error, _) => Center(child: Text(_cleanError(error))),

              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start the collaboration conversation.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    final mine = message.senderId == identity?.uid;

                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 290),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? AppColors.industry
                              : const Color(0xFFF1F4F8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              Text(
                                message.senderName,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.muted,
                                ),
                              ),

                            if (!mine) const SizedBox(height: 3),

                            Text(
                              message.text,
                              style: TextStyle(
                                color: mine ? Colors.white : AppColors.title,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.industry,
                    ),
                    onPressed: sending ? null : _send,
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = messageController.text.trim();

    if (text.isEmpty || sending) {
      return;
    }

    setState(() => sending = true);

    try {
      await ref
          .read(industryControllerProvider.notifier)
          .sendMessage(collaborationId: widget.collaborationId, text: text);

      messageController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.industry.withOpacity(.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.industry, size: 19),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),

              const SizedBox(height: 3),

              Text(
                value.trim().isEmpty ? 'Not provided' : value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
// INTEREST STATUS
// ============================================================

class _InterestStatusCard extends StatelessWidget {
  const _InterestStatusCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 3),

                Text(text, style: const TextStyle(fontSize: 11.5, height: 1.4)),
              ],
            ),
          ),
        ],
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

String _displayStatus(String value) {
  final status = value.trim().toLowerCase();

  switch (status) {
    case 'pending':
      return 'Pending';

    case 'accepted':
      return 'Accepted';

    case 'rejected':
      return 'Rejected';

    case 'withdrawn':
      return 'Withdrawn';

    default:
      return value;
  }
}

String _projectStatus(String value) {
  switch (value.trim().toLowerCase()) {
    case 'active':
      return 'In Progress';

    case 'solution_deployed':
      return 'Solution Deployed';

    default:
      return value;
  }
}
