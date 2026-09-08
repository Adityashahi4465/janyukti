import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../shared/mock_data/app_store.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_colors.dart';

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
