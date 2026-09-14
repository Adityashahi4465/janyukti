import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../models/challenge_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';
import '../../citizen/controllers/citizen_controller.dart';

class ProjectMonitoring extends ConsumerStatefulWidget {
  const ProjectMonitoring({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<ProjectMonitoring> createState() => _ProjectMonitoringState();
}

class _ProjectMonitoringState extends ConsumerState<ProjectMonitoring> {
  final TextEditingController _updateNoteController = TextEditingController();

  bool _isUpdatingStatus = false;

  @override
  void dispose() {
    _updateNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // DIRECT REAL-TIME FIRESTORE DOCUMENT
    // ============================================================

    final challengeAsync = ref.watch(
      challengeStreamProvider(widget.challengeId),
    );

    return PageFrame(
      title: 'Project Monitoring',
      color: AppColors.admin,
      child: challengeAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },

        error: (error, stackTrace) {
          return _ErrorState(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () {
              ref.invalidate(challengeStreamProvider(widget.challengeId));
            },
          );
        },

        data: (challenge) {
          if (challenge == null) {
            return const _ChallengeNotFound();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(challengeStreamProvider(widget.challengeId));

              await ref.read(
                challengeStreamProvider(widget.challengeId).future,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
              children: [
                // ==================================================
                // CHALLENGE HEADER
                // ==================================================
                _ChallengeHeader(challenge: challenge),

                const SizedBox(height: 16),

                // ==================================================
                // ASSIGNED UNIVERSITY
                // ==================================================
                _UniversityAssignmentCard(challenge: challenge),

                const SizedBox(height: 28),

                // ==================================================
                // CHALLENGE PROGRESS
                // ==================================================
                const _SectionTitle(
                  title: 'Challenge Progress',
                  subtitle: 'Live workflow history for this challenge.',
                ),

                const SizedBox(height: 12),

                AppCard(child: _ChallengeTimeline(challenge: challenge)),

                const SizedBox(height: 28),

                // ==================================================
                // MONITORING METRICS
                // ==================================================
                const _SectionTitle(
                  title: 'Monitoring',
                  subtitle: 'Current operational indicators.',
                ),

                const SizedBox(height: 12),

                _MonitoringMetrics(challenge: challenge),

                if (_isStale(challenge)) ...[
                  const SizedBox(height: 12),

                  _StaleWarning(
                    days: DateTime.now().difference(challenge.updatedAt).inDays,
                  ),
                ],

                const SizedBox(height: 28),

                // ==================================================
                // LATEST UPDATE
                // ==================================================
                const _SectionTitle(
                  title: 'Latest University Update',
                  subtitle: 'Most recent progress information received.',
                ),

                const SizedBox(height: 12),

                _LatestUpdateCard(challenge: challenge),

                const SizedBox(height: 28),

                // ==================================================
                // CITIZEN EVIDENCE
                // ==================================================
                const _SectionTitle(
                  title: 'Citizen Evidence',
                  subtitle: 'Original evidence submitted with the challenge.',
                ),

                const SizedBox(height: 12),

                if (challenge.media.isEmpty && challenge.voiceNotes.isEmpty)
                  const _EmptyEvidence(
                    text: 'No citizen evidence was submitted.',
                  )
                else ...[
                  for (final media in challenge.media) ...[
                    _MediaEvidenceCard(media: media),

                    const SizedBox(height: 12),
                  ],

                  for (final voice in challenge.voiceNotes) ...[
                    _VoiceEvidenceCard(voice: voice),

                    const SizedBox(height: 12),
                  ],
                ],

                const SizedBox(height: 18),

                // ==================================================
                // SOLUTION EVIDENCE
                // ==================================================
                const _SectionTitle(
                  title: 'Solution Evidence',
                  subtitle:
                      'Prototype, implementation images, reports or deployment evidence.',
                ),

                const SizedBox(height: 12),

                /*
                 * Challenge currently does not have a dedicated
                 * solutionEvidence / universityUpdates field.
                 *
                 * Do not display fake evidence here.
                 *
                 * When university-side uploads are added,
                 * render them here.
                 */
                const _EmptyEvidence(
                  text: 'No solution evidence has been uploaded yet.',
                  icon: Icons.science_outlined,
                ),

                const SizedBox(height: 28),

                // ==================================================
                // CURRENT ACTION
                // ==================================================
                const _SectionTitle(
                  title: 'Current Action',
                  subtitle:
                      'Move the challenge to its next valid workflow stage.',
                ),

                const SizedBox(height: 12),

                _buildCurrentAction(challenge),

                const SizedBox(height: 30),

                // ==================================================
                // AUDIT
                // ==================================================
                const _SectionTitle(
                  title: 'Activity & Audit Trail',
                  subtitle: 'Complete recorded history of this challenge.',
                ),

                const SizedBox(height: 12),

                _AuditTrail(challenge: challenge),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CURRENT ACTION
  // ============================================================

  Widget _buildCurrentAction(Challenge challenge) {
    final status = challenge.status.trim().toLowerCase();

    String? nextStatus;
    String? buttonLabel;
    IconData? icon;

    if (status == 'assigned') {
      nextStatus = 'In Progress';
      buttonLabel = 'Mark In Progress';
      icon = Icons.play_arrow_rounded;
    } else if (status == 'in progress') {
      nextStatus = 'Solution Deployed';
      buttonLabel = 'Mark Solution Deployed';
      icon = Icons.rocket_launch_rounded;
    } else if (status == 'solution deployed' || status == 'deployed') {
      nextStatus = 'Resolved';
      buttonLabel = 'Mark Resolved';
      icon = Icons.check_circle_rounded;
    }

    if (status == 'resolved' || status == 'completed') {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.withOpacity(.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Colors.green, size: 27),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Challenge Resolved',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'No further workflow action is required.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (nextStatus == null || buttonLabel == null || icon == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No monitoring action is available for status "${challenge.status}".',
          style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next stage: $nextStatus',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),

          const SizedBox(height: 5),

          const Text(
            'Add a short note explaining this update.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _updateNoteController,
            minLines: 3,
            maxLines: 5,
            maxLength: 300,
            decoration: InputDecoration(
              hintText:
                  'e.g. Field inspection completed and implementation has started...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 55),
                child: Icon(Icons.notes_rounded, color: AppColors.admin),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE0E6EF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.admin, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _updateStatus(
                      challenge: challenge,
                      nextStatus: nextStatus!,
                    ),
              icon: _isUpdatingStatus
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon),
              label: Text(
                _isUpdatingStatus ? 'Updating...' : buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.admin,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS UPDATE
  // ============================================================

  Future<void> _updateStatus({
    required Challenge challenge,
    required String nextStatus,
  }) async {
    final note = _updateNoteController.text.trim();

    if (note.isEmpty) {
      _showMessage(
        'Please add an update note before changing the status.',
        error: true,
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Status Update'),
          content: Text(
            'Move this challenge from '
            '"${challenge.status}" to "$nextStatus"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await ref
          .read(citizenControllerProvider.notifier)
          .updateStatus(
            challengeId: challenge.id,
            status: nextStatus,
            note: note,
          );

      if (!mounted) return;

      _updateNoteController.clear();

      _showMessage('Challenge moved to $nextStatus.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.redAccent : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  bool _isStale(Challenge challenge) {
    final status = challenge.status.trim().toLowerCase();

    if (status == 'resolved' || status == 'completed') {
      return false;
    }

    return DateTime.now().difference(challenge.updatedAt).inDays >= 7;
  }
}

// ============================================================
// CHALLENGE HEADER
// ============================================================

class _ChallengeHeader extends StatelessWidget {
  const _ChallengeHeader({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(challenge.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.darkPurpleTextGradient,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Challenge #${_shortId(challenge.id)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.22),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: color.withOpacity(.55)),
                ),
                child: Text(
                  challenge.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            challenge.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 11),

          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                color: Colors.white70,
                size: 16,
              ),

              const SizedBox(width: 6),

              Flexible(
                child: Text(
                  challenge.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: Colors.white54)),
              ),

              const Icon(
                Icons.location_on_outlined,
                color: Colors.white70,
                size: 16,
              ),

              const SizedBox(width: 4),

              Expanded(
                child: Text(
                  challenge.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ASSIGNED UNIVERSITY
// ============================================================

class _UniversityAssignmentCard extends StatelessWidget {
  const _UniversityAssignmentCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final university = challenge.assignedUniversityName?.trim();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: AppColors.admin.withOpacity(.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.school_rounded, color: AppColors.admin),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned University',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  university != null && university.isNotEmpty
                      ? university
                      : 'Not assigned',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),

                if (challenge.assignedAt != null) ...[
                  const SizedBox(height: 7),

                  _SmallInfo(
                    icon: Icons.schedule_rounded,
                    text: 'Assigned: ${_formatDate(challenge.assignedAt!)}',
                  ),
                ],

                if (challenge.assignedByName?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),

                  _SmallInfo(
                    icon: Icons.admin_panel_settings_outlined,
                    text: 'Assigned by: ${challenge.assignedByName}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TIMELINE
// ============================================================

class _ChallengeTimeline extends StatelessWidget {
  const _ChallengeTimeline({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final events = [...challenge.statusHistory]
      ..sort((a, b) => a.at.compareTo(b.at));

    const steps = [
      'Submitted',
      'Under Review',
      'Assigned',
      'In Progress',
      'Solution Deployed',
      'Resolved',
    ];

    final activeIndex = _statusIndex(challenge.status);

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];

        final event = _findEventForStep(events, step);

        final reached = index <= activeIndex;

        final current = index == activeIndex;

        var label = step;

        if (step == 'Assigned' &&
            challenge.assignedUniversityName?.trim().isNotEmpty == true) {
          label = 'Assigned to ${challenge.assignedUniversityName}';
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Column(
                children: [
                  Icon(
                    current
                        ? Icons.radio_button_checked_rounded
                        : reached
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: reached ? AppColors.admin : AppColors.line,
                    size: 22,
                  ),

                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 47,
                      color: index < activeIndex
                          ? AppColors.admin
                          : AppColors.line,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              color: reached
                                  ? AppColors.title
                                  : AppColors.muted,
                              fontWeight: reached
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),

                          if (current) ...[
                            const SizedBox(height: 3),

                            Text(
                              'Current stage',
                              style: TextStyle(
                                color: AppColors.admin,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],

                          if (event != null &&
                              event.note.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),

                            Text(
                              event.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (event != null)
                      Text(
                        _formatTimelineDate(event.at),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  ChallengeStatusEvent? _findEventForStep(
    List<ChallengeStatusEvent> events,
    String step,
  ) {
    final target = step.toLowerCase();

    for (final event in events) {
      var status = event.status.trim().toLowerCase();

      if (target == 'assigned' && status.startsWith('assigned')) {
        return event;
      }

      if (target == 'solution deployed' && status == 'deployed') {
        return event;
      }

      if (target == 'resolved' && status == 'completed') {
        return event;
      }

      if (status == target) {
        return event;
      }
    }

    return null;
  }
}

// ============================================================
// MONITORING METRICS
// ============================================================

class _MonitoringMetrics extends StatelessWidget {
  const _MonitoringMetrics({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final daysOpen = DateTime.now().difference(challenge.createdAt).inDays;

    final lastUpdate = _relativeTime(challenge.updatedAt);

    return Row(
      children: [
        Expanded(
          child: _MonitoringMetric(
            value: '$daysOpen',
            label: 'Days Open',
            icon: Icons.schedule_outlined,
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: _MonitoringMetric(
            value: challenge.priority,
            label: 'Priority',
            icon: Icons.flag_outlined,
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: _MonitoringMetric(
            value: lastUpdate,
            label: 'Last Update',
            icon: Icons.update_rounded,
          ),
        ),
      ],
    );
  }
}

class _MonitoringMetric extends StatelessWidget {
  const _MonitoringMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.admin, size: 20),

          const SizedBox(height: 7),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LATEST UPDATE
// ============================================================

class _LatestUpdateCard extends StatelessWidget {
  const _LatestUpdateCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    /*
     * We do NOT yet have a dedicated universityUpdates collection.
     *
     * Until that exists, use the most recent status-history entry
     * with a note as the latest workflow update.
     */

    final updates =
        challenge.statusHistory
            .where((event) => event.note.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));

    if (updates.isEmpty) {
      return const _EmptyEvidence(
        text: 'No university progress update has been posted yet.',
        icon: Icons.update_outlined,
      );
    }

    final update = updates.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.admin.withOpacity(.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  color: AppColors.admin,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  update.status,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            update.note,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.title,
            ),
          ),

          const SizedBox(height: 11),

          Text(
            '${_formatDate(update.at)}'
            '${update.updatedByName.trim().isEmpty ? '' : ' • ${update.updatedByName}'}',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AUDIT TRAIL
// ============================================================

class _AuditTrail extends StatelessWidget {
  const _AuditTrail({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final history = [...challenge.statusHistory]
      ..sort((a, b) => b.at.compareTo(a.at));

    if (history.isEmpty) {
      return const _EmptyEvidence(
        text: 'No activity history is available yet.',
        icon: Icons.history_rounded,
      );
    }

    return AppCard(
      child: Column(
        children: List.generate(history.length, (index) {
          final event = history[index];

          final last = index == history.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.admin.withOpacity(.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _statusIcon(event.status),
                        size: 15,
                        color: AppColors.admin,
                      ),
                    ),

                    if (!last)
                      Container(width: 2, height: 55, color: AppColors.line),
                  ],
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.status,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          Text(
                            _formatTimelineDate(event.at),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),

                      if (event.updatedByName.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),

                        Text(
                          'Updated by ${event.updatedByName}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],

                      if (event.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),

                        Text(
                          event.note,
                          style: const TextStyle(fontSize: 11.5, height: 1.35),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ============================================================
// MEDIA
// ============================================================

class _MediaEvidenceCard extends StatelessWidget {
  const _MediaEvidenceCard({required this.media});

  final ChallengeMedia media;

  @override
  Widget build(BuildContext context) {
    final type = media.type.trim().toLowerCase();

    final resource = media.resourceType.trim().toLowerCase();

    final isImage = type == 'photo' || type == 'image' || resource == 'image';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        children: [
          if (isImage)
            Image.network(
              media.url,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.muted,
                      size: 40,
                    ),
                  ),
                );
              },
            )
          else
            _NetworkVideoPlayer(url: media.url),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isImage ? Icons.image_outlined : Icons.videocam_outlined,
                  color: AppColors.admin,
                  size: 19,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    isImage ? 'Citizen Photo' : 'Citizen Video',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),

                if (media.format.isNotEmpty)
                  Text(
                    media.format.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
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
// VIDEO
// ============================================================

class _NetworkVideoPlayer extends StatefulWidget {
  const _NetworkVideoPlayer({required this.url});

  final String url;

  @override
  State<_NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<_NetworkVideoPlayer> {
  late final VideoPlayerController _controller;

  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));

    _initialise();
  }

  Future<void> _initialise() async {
    try {
      await _controller.initialize();

      if (!mounted) return;

      setState(() {
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Unable to load video',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    if (!_ready) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final aspectRatio = _controller.value.aspectRatio > 0
        ? _controller.value.aspectRatio
        : 16 / 9;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),

              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ],
          ),
        ),

        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }
}

// ============================================================
// VOICE
// ============================================================

class _VoiceEvidenceCard extends StatefulWidget {
  const _VoiceEvidenceCard({required this.voice});

  final ChallengeVoiceNote voice;

  @override
  State<_VoiceEvidenceCard> createState() => _VoiceEvidenceCardState();
}

class _VoiceEvidenceCardState extends State<_VoiceEvidenceCard> {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<void>? _completeSubscription;

  bool _playing = false;

  @override
  void initState() {
    super.initState();

    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        _playing = false;
      });
    });
  }

  @override
  void dispose() {
    _completeSubscription?.cancel();

    _player.dispose();

    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_playing) {
        await _player.pause();

        if (!mounted) return;

        setState(() {
          _playing = false;
        });

        return;
      }

      await _player.play(UrlSource(widget.voice.url));

      if (!mounted) return;

      setState(() {
        _playing = true;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final voice = widget.voice;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: AppColors.admin.withOpacity(.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.admin,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _voiceTitle(voice.field),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (voice.transcript.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Text(
                    voice.transcript,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                ],

                if (voice.duration != null) ...[
                  const SizedBox(height: 5),

                  Text(
                    '${voice.duration!.toStringAsFixed(1)} sec',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY EVIDENCE
// ============================================================

class _EmptyEvidence extends StatelessWidget {
  const _EmptyEvidence({
    required this.text,
    this.icon = Icons.photo_library_outlined,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 29),

          const SizedBox(height: 9),

          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STALE WARNING
// ============================================================

class _StaleWarning extends StatelessWidget {
  const _StaleWarning({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(.15)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 19,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'No update has been recorded for $days days.',
              style: const TextStyle(
                color: Color(0xFF9A6700),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.title,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

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
              Icons.cloud_off_outlined,
              color: AppColors.muted,
              size: 46,
            ),

            const SizedBox(height: 12),

            const Text(
              'Unable to load monitoring',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 6),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
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

class _ChallengeNotFound extends StatelessWidget {
  const _ChallengeNotFound();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Challenge not found.'));
  }
}

int _statusIndex(String status) {
  final value = status.trim().toLowerCase();

  if (value == 'submitted') {
    return 0;
  }

  if (value == 'under review') {
    return 1;
  }

  if (value.startsWith('assigned')) {
    return 2;
  }

  if (value == 'in progress') {
    return 3;
  }

  if (value == 'solution deployed' || value == 'deployed') {
    return 4;
  }

  if (value == 'resolved' || value == 'completed') {
    return 5;
  }

  return 0;
}

Color _statusColor(String status) {
  final value = status.trim().toLowerCase();

  if (value == 'assigned') {
    return Colors.orange;
  }

  if (value == 'in progress') {
    return Colors.blue;
  }

  if (value.contains('deployed')) {
    return Colors.deepPurple;
  }

  if (value == 'resolved' || value == 'completed') {
    return Colors.green;
  }

  return AppColors.admin;
}

IconData _statusIcon(String status) {
  final value = status.trim().toLowerCase();

  if (value == 'submitted') {
    return Icons.send_outlined;
  }

  if (value == 'under review') {
    return Icons.search_rounded;
  }

  if (value.startsWith('assigned')) {
    return Icons.school_outlined;
  }

  if (value == 'in progress') {
    return Icons.engineering_outlined;
  }

  if (value.contains('deployed')) {
    return Icons.rocket_launch_outlined;
  }

  if (value == 'resolved' || value == 'completed') {
    return Icons.check_circle_outline_rounded;
  }

  return Icons.circle_outlined;
}

String _shortId(String id) {
  if (id.length <= 8) {
    return id.toUpperCase();
  }

  return id.substring(0, 8).toUpperCase();
}

String _voiceTitle(String field) {
  switch (field) {
    case 'title':
      return 'Title Voice Note';

    case 'description':
      return 'Description Voice Note';

    case 'additional':
      return 'Additional Information Voice Note';

    default:
      return 'Voice Note';
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} '
      '${months[date.month - 1]} '
      '${date.year}';
}

String _formatTimelineDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '${date.day} '
      '${months[date.month - 1]} '
      '$hour:$minute';
}

String _relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);

  if (difference.inMinutes < 1) {
    return 'Now';
  }

  if (difference.inHours < 1) {
    return '${difference.inMinutes}m';
  }

  if (difference.inDays < 1) {
    return '${difference.inHours}h';
  }

  return '${difference.inDays}d';
}
