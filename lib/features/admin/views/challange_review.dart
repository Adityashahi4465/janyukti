import 'package:flutter/material.dart';
import '../../../models/challenge_model.dart';
import '../../../shared/mock_data/app_store.dart';
import '../../../widgets/ui.dart';
import '../../../theme/app_colors.dart';

class ChallengeReview extends StatefulWidget {
  const ChallengeReview({super.key, required this.x});
  final Challenge x;
  @override
  State<ChallengeReview> createState() => _ChallengeReviewState();
}

class _ChallengeReviewState extends State<ChallengeReview> {
  String uni = 'BIT Mesra';
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Assign to University',
    color: AppColors.admin,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.x.id,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                widget.x.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('Submitted by ${widget.x.submittedBy}'),
              Text(widget.x.location),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField(
          initialValue: uni,
          items: [
            'BIT Mesra',
            'Ranchi University',
            'IIT ISM',
          ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (x) => setState(() => uni = x!),
          decoration: const InputDecoration(labelText: 'Select university'),
        ),
        const SizedBox(height: 22),
        RoleButton(
          label: 'Assign Challenge',
          color: AppColors.admin,
          onTap: () {
            StoreScope.of(c).assign(widget.x, uni);
            ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text('Challenge assigned to $uni')),
            );
            Navigator.pop(c);
          },
        ),
      ],
    ),
  );
}
