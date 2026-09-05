import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../shared/widgets/ui.dart';

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
