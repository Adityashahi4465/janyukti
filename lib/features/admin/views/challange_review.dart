import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../models/challenge_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';
import '../../citizen/controllers/citizen_controller.dart';

class ChallengeReview extends ConsumerStatefulWidget {
  const ChallengeReview({super.key, required this.x});

  final Challenge x;

  @override
  ConsumerState<ChallengeReview> createState() => _ChallengeReviewState();
}

class _ChallengeReviewState extends ConsumerState<ChallengeReview> {
  static const List<_UniversityOption> _universities = [
    _UniversityOption(id: 'bit_mesra', name: 'BIT Mesra'),
    _UniversityOption(id: 'ranchi_university', name: 'Ranchi University'),
    _UniversityOption(id: 'iit_ism', name: 'IIT ISM'),
  ];

  _UniversityOption? _selectedUniversity;

  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();

    _selectedUniversity = _universities.first;
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // REAL-TIME CHALLENGE FROM FIRESTORE
    // ============================================================

    final challengeAsync = ref.watch(challengeStreamProvider(widget.x.id));

    final challenge = challengeAsync.asData?.value ?? widget.x;

    return PageFrame(
      title: 'Review Challenge',
      color: AppColors.admin,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(challengeStreamProvider(widget.x.id));

          await ref.read(challengeStreamProvider(widget.x.id).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
          children: [
            // ======================================================
            // FIRESTORE STATUS
            // ======================================================
            if (challengeAsync.isLoading)
              const LinearProgressIndicator(minHeight: 2),

            if (challengeAsync.hasError)
              _warningCard('Unable to refresh the latest challenge data.'),

            if (challengeAsync.isLoading || challengeAsync.hasError)
              const SizedBox(height: 12),

            // ======================================================
            // HEADER
            // ======================================================
            _buildChallengeHeader(challenge),

            const SizedBox(height: 24),

            // ======================================================
            // DETAILS
            // ======================================================
            _sectionTitle(
              'Challenge Details',
              'Review the citizen submission before assigning it.',
            ),

            const SizedBox(height: 10),

            AppCard(
              child: Column(
                children: [
                  _detailRow(
                    Icons.category_outlined,
                    'Category',
                    challenge.category,
                  ),

                  const Divider(height: 28),

                  _detailRow(
                    Icons.location_on_outlined,
                    'Location',
                    challenge.location,
                  ),

                  if (challenge.latitude != null &&
                      challenge.longitude != null) ...[
                    const Divider(height: 28),

                    _detailRow(
                      Icons.my_location_rounded,
                      'Coordinates',
                      '${challenge.latitude!.toStringAsFixed(5)}, '
                          '${challenge.longitude!.toStringAsFixed(5)}',
                    ),
                  ],

                  const Divider(height: 28),

                  _detailRow(
                    Icons.description_outlined,
                    'Description',
                    challenge.description,
                  ),

                  if (challenge.additionalInfo.trim().isNotEmpty) ...[
                    const Divider(height: 28),

                    _detailRow(
                      Icons.info_outline_rounded,
                      'Additional Information',
                      challenge.additionalInfo,
                    ),
                  ],
                ],
              ),
            ),

            // ======================================================
            // EVIDENCE
            // ======================================================
            if (challenge.media.isNotEmpty ||
                challenge.voiceNotes.isNotEmpty) ...[
              const SizedBox(height: 26),

              _sectionTitle(
                'Submitted Evidence',
                'Review the original photo, video and voice evidence.',
              ),

              const SizedBox(height: 12),

              for (final media in challenge.media) ...[
                _ChallengeMediaCard(media: media),

                const SizedBox(height: 12),
              ],

              for (final voice in challenge.voiceNotes) ...[
                _ChallengeVoiceCard(voice: voice),

                const SizedBox(height: 12),
              ],
            ],

            const SizedBox(height: 26),

            // ======================================================
            // SUBMISSION INFORMATION
            // ======================================================
            _sectionTitle('Submission', 'Citizen and workflow information.'),

            const SizedBox(height: 10),

            AppCard(
              child: Column(
                children: [
                  _detailRow(
                    Icons.person_outline_rounded,
                    'Submitted By',
                    challenge.submittedBy.trim().isEmpty
                        ? 'Citizen'
                        : challenge.submittedBy,
                  ),

                  const Divider(height: 28),

                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Submitted At',
                    _formatDate(challenge.createdAt),
                  ),

                  const Divider(height: 28),

                  _detailRow(
                    Icons.flag_outlined,
                    'Priority',
                    challenge.priority,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ======================================================
            // UNIVERSITY ASSIGNMENT
            // ======================================================
            _sectionTitle(
              'Assign University',
              'Select the institution responsible for taking this challenge forward.',
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE0E6EF)),
              ),
              child: DropdownButtonFormField<_UniversityOption>(
                initialValue: _selectedUniversity,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'University',
                  prefixIcon: Icon(
                    Icons.school_outlined,
                    color: AppColors.admin,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
                items: _universities.map((university) {
                  return DropdownMenuItem<_UniversityOption>(
                    value: university,
                    child: Text(university.name),
                  );
                }).toList(),
                onChanged: _isAssigning
                    ? null
                    : (value) {
                        setState(() {
                          _selectedUniversity = value;
                        });
                      },
              ),
            ),

            const SizedBox(height: 18),

            // ======================================================
            // ASSIGN BUTTON
            // ======================================================
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _isAssigning || _selectedUniversity == null
                    ? null
                    : () => _assignChallenge(context, challenge),
                icon: _isAssigning
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.assignment_ind_rounded),
                label: Text(
                  _isAssigning ? 'Assigning...' : 'Assign Challenge',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.admin,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGN - REAL FIRESTORE ACTION
  // ============================================================

  Future<void> _assignChallenge(
    BuildContext context,
    Challenge challenge,
  ) async {
    final university = _selectedUniversity;

    if (university == null) {
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      await ref
          .read(citizenControllerProvider.notifier)
          .assignUniversity(
            challengeId: challenge.id,
            universityId: university.id,
            universityName: university.name,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Challenge assigned to ${university.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildChallengeHeader(Challenge challenge) {
    final statusColor = _statusColor(challenge.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.darkPurpleTextGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.admin.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${challenge.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.white100,
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
                  color: statusColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      challenge.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            challenge.title,
            style: const TextStyle(
              fontSize: 21,
              height: 1.25,
              fontWeight: FontWeight.w900,
              color: AppColors.white100,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.white100,
                size: 18,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  challenge.location,
                  style: const TextStyle(
                    color: AppColors.white100,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(.50),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              challenge.category,
              style: TextStyle(
                color: AppColors.white100,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: AppColors.admin.withOpacity(.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: AppColors.admin),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.title,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,

                  fontWeight: FontWeight.normal,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
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
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _warningCard(String message) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.orange, size: 18),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final value = status.trim().toLowerCase();

    if (value.contains('resolved') ||
        value.contains('completed') ||
        value.contains('deployed')) {
      return Colors.green;
    }

    if (value.contains('review')) {
      return Colors.orange;
    }

    if (value.contains('assigned')) {
      return AppColors.admin;
    }

    if (value.contains('progress')) {
      return Colors.blue;
    }

    return const Color(0xFF667085);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }
}

// ============================================================
// MEDIA
// ============================================================

class _ChallengeMediaCard extends StatelessWidget {
  const _ChallengeMediaCard({required this.media});

  final ChallengeMedia media;

  @override
  Widget build(BuildContext context) {
    final resourceType = media.resourceType.toLowerCase();

    final type = media.type.toLowerCase();

    final isImage =
        resourceType == 'image' || type == 'photo' || type == 'image';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      size: 42,
                      color: AppColors.muted,
                    ),
                  ),
                );
              },
            )
          else
            _ReviewVideoPlayer(url: media.url),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isImage ? Icons.image_outlined : Icons.videocam_outlined,
                  color: AppColors.admin,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    isImage ? 'Photo Evidence' : 'Video Evidence',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                if (media.format.isNotEmpty)
                  Text(
                    media.format.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
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

class _ReviewVideoPlayer extends StatefulWidget {
  const _ReviewVideoPlayer({required this.url});

  final String url;

  @override
  State<_ReviewVideoPlayer> createState() => _ReviewVideoPlayerState();
}

class _ReviewVideoPlayerState extends State<_ReviewVideoPlayer> {
  late final VideoPlayerController _controller;

  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();

      if (!mounted) return;

      setState(() {
        _initialized = true;
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

    if (!_initialized) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
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

class _ChallengeVoiceCard extends StatefulWidget {
  const _ChallengeVoiceCard({required this.voice});

  final ChallengeVoiceNote voice;

  @override
  State<_ChallengeVoiceCard> createState() => _ChallengeVoiceCardState();
}

class _ChallengeVoiceCardState extends State<_ChallengeVoiceCard> {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _toggleAudio() async {
    try {
      if (_isPlaying) {
        await _player.pause();

        if (!mounted) return;

        setState(() {
          _isPlaying = false;
        });

        return;
      }

      await _player.play(UrlSource(widget.voice.url));

      if (!mounted) return;

      setState(() {
        _isPlaying = true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggleAudio,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.admin.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
                  _voiceTitle(widget.voice.field),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),

                if (widget.voice.transcript.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Text(
                    widget.voice.transcript,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],

                if (widget.voice.duration != null) ...[
                  const SizedBox(height: 5),

                  Text(
                    '${widget.voice.duration!.toStringAsFixed(1)} sec',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
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
}

// ============================================================
// UNIVERSITY MODEL
// ============================================================

class _UniversityOption {
  const _UniversityOption({required this.id, required this.name});

  final String id;
  final String name;
}
