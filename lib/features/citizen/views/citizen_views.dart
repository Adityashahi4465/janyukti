import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../shared/mock_data/app_store.dart';
import '../../../shared/widgets/ui.dart';

class CitizenDashboard extends StatelessWidget {
  const CitizenDashboard({super.key});
  @override
  Widget build(BuildContext c) {
    final s = StoreScope.of(c);
    return PageFrame(
      title: 'CIVORA',
      color: AppColors.citizen,
      actions: [
        const Icon(Icons.notifications_none),
        const SizedBox(width: 12),
      ],
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Hello, Aarav 👋',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const Text(
            'What would you like to do?',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          RoleButton(
            label: 'Report a Challenge',
            color: AppColors.citizen,
            onTap: () => Navigator.pushNamed(c, Routes.submit),
            icon: Icons.add_circle_outline,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              c,
              Routes.track,
              arguments: s.challenges.first,
            ),
            icon: const Icon(Icons.track_changes),
            label: const Text('My Challenges'),
          ),
          Row(
            children: [
              Stat('${s.challenges.length}', 'Challenges', AppColors.citizen),
              const SizedBox(width: 8),
              const Stat('1', 'In Progress', AppColors.citizen),
              const SizedBox(width: 8),
              const Stat('12', 'People Impacted', AppColors.citizen),
            ],
          ),
          section('Recent Challenges'),
          ...s.challenges.map(
            (x) => ChallengeCard(
              x,
              onTap: () => Navigator.pushNamed(c, Routes.track, arguments: x),
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard(this.x, {super.key, this.onTap});
  final Challenge x;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFEAF7EF),
          child: Icon(Icons.water_drop, color: AppColors.citizen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                x.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                x.location,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        StatusPill(x.status),
      ],
    ),
  );
}

class SubmitChallengeView extends StatefulWidget {
  const SubmitChallengeView({super.key});
  @override
  State<SubmitChallengeView> createState() => _SubmitChallengeViewState();
}

class _SubmitChallengeViewState extends State<SubmitChallengeView> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(), desc = TextEditingController();
  String category = 'Water Management';
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Submit Challenge',
    color: AppColors.citizen,
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Tell us what needs attention',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Title *'),
            validator: (x) => x!.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: desc,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description *'),
            validator: (x) => x!.isEmpty ? 'Description is required' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField(
            initialValue: category,
            items: [
              'Water Management',
              'Waste Management',
              'Agriculture',
              'Infrastructure',
              'Healthcare',
              'Education',
              'Other',
            ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (x) => setState(() => category = x!),
            decoration: const InputDecoration(labelText: 'Category *'),
          ),
          const SizedBox(height: 24),
          RoleButton(
            label: 'Next',
            color: AppColors.citizen,
            onTap: () {
              if (form.currentState!.validate())
                Navigator.pushNamed(
                  c,
                  Routes.details,
                  arguments: [title.text, desc.text, category],
                );
            },
          ),
        ],
      ),
    ),
  );
}

class AddDetailsView extends StatefulWidget {
  const AddDetailsView({super.key, required this.draft});
  final List<String> draft;
  @override
  State<AddDetailsView> createState() => _AddDetailsViewState();
}

class _AddDetailsViewState extends State<AddDetailsView> {
  final loc = TextEditingController(text: 'Ranchi, Jharkhand');
  bool uploaded = false;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Add Details',
    color: AppColors.citizen,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          controller: loc,
          decoration: const InputDecoration(labelText: 'Location *'),
        ),
        const SizedBox(height: 18),
        AppCard(
          onTap: () => setState(() => uploaded = true),
          child: Row(
            children: [
              Icon(
                uploaded
                    ? Icons.check_circle
                    : Icons.add_photo_alternate_outlined,
                color: AppColors.citizen,
              ),
              const SizedBox(width: 12),
              Text(uploaded ? '1 photo selected' : 'Upload Photos / Videos'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(labelText: 'Additional information'),
        ),
        const SizedBox(height: 24),
        RoleButton(
          label: 'Submit Challenge',
          color: AppColors.citizen,
          onTap: () {
            final x = StoreScope.of(c).addChallenge(
              widget.draft[0],
              widget.draft[1],
              widget.draft[2],
              loc.text,
            );
            Navigator.pushNamed(c, Routes.success, arguments: x);
          },
        ),
      ],
    ),
  );
}

class SubmissionSuccess extends StatelessWidget {
  const SubmissionSuccess({super.key, required this.challenge});
  final Challenge challenge;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Challenge Submitted',
    color: AppColors.citizen,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 39,
            backgroundColor: AppColors.success,
            child: Icon(Icons.check, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Thank you!',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your challenge has been submitted successfully.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            challenge.id,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 32),
          RoleButton(
            label: 'Track Challenge',
            color: AppColors.citizen,
            onTap: () =>
                Navigator.pushNamed(c, Routes.track, arguments: challenge),
            icon: Icons.track_changes,
          ),
          TextButton(
            onPressed: () =>
                Navigator.popUntil(c, ModalRoute.withName(Routes.citizen)),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  );
}

class TrackChallengeView extends StatelessWidget {
  const TrackChallengeView({super.key, required this.x});
  final Challenge x;
  @override
  Widget build(BuildContext c) {
    const events = [
      'Submitted',
      'Under Review',
      'Assigned to University',
      'In Progress',
      'Solution Deployed',
    ];
    var a = x.status == 'Submitted'
        ? 0
        : x.status == 'Under Review'
        ? 1
        : x.status.startsWith('Assigned')
        ? 2
        : 3;
    return PageFrame(
      title: 'Track Challenge',
      color: AppColors.citizen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(x.id, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  x.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  x.location,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          section('Challenge journey'),
          Timeline(items: events, active: a, color: AppColors.citizen),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => showDialog(
              context: c,
              builder: (_) => AlertDialog(
                title: const Text('Challenge details'),
                content: Text(x.description),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
}
