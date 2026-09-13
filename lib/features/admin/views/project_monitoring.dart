import 'package:flutter/material.dart';

import '../../../shared/mock_data/app_store.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';

class ProjectMonitoring extends StatelessWidget {
  const ProjectMonitoring({super.key});
  @override
  Widget build(BuildContext c) {
    final s = StoreScope.of(c);
    return PageFrame(
      title: 'Project Monitoring',
      color: AppColors.admin,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          for (final p in s.projects)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    p.university,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: p.progress / 100,
                    color: AppColors.admin,
                  ),
                  Text('${p.progress}%'),
                ],
              ),
            ),
          const SizedBox(height: 12),
          RoleButton(
            label: 'View All Projects',
            color: AppColors.admin,
            onTap: () => ScaffoldMessenger.of(c).showSnackBar(
              const SnackBar(content: Text('Showing all local projects')),
            ),
          ),
        ],
      ),
    );
  }
}
