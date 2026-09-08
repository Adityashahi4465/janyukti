import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../shared/mock_data/app_store.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_colors.dart';

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
