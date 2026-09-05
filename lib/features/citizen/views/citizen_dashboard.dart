import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../shared/mock_data/app_store.dart';
import '../../../shared/widgets/ui.dart';
import '../widgets/challange_card.dart';

class CitizenDashboard extends StatelessWidget {
  const CitizenDashboard({super.key});
  @override
  Widget build(BuildContext c) {
    final s = StoreScope.of(c);
    return PageFrame(
      title: 'JanYukti',
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
