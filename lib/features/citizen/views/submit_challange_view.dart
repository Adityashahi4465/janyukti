import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart' show Routes;
import '../../../shared/widgets/ui.dart' show RoleButton, PageFrame;
import '../../../theme/app_colors.dart';

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
              if (form.currentState!.validate()) {
                Navigator.pushNamed(
                  c,
                  Routes.details,
                  arguments: [title.text, desc.text, category],
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}
