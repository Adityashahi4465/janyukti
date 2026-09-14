import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apis/universites_api.dart';
import '../../../core/routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';

class CreateProjectView extends ConsumerStatefulWidget {
  const CreateProjectView({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<CreateProjectView> createState() => _CreateProjectViewState();
}

class _CreateProjectViewState extends ConsumerState<CreateProjectView> {
  final name = TextEditingController();

  final mentor = TextEditingController();

  final member = TextEditingController();

  final members = <String>[];

  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    mentor.dispose();
    member.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Create Project',
      color: AppColors.university,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Project Name *'),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: mentor,
            decoration: const InputDecoration(labelText: 'Faculty Mentor *'),
          ),

          section('Team Members'),

          for (final person in members)
            AppCard(
              padding: 8,
              child: ListTile(
                title: Text(person),
                leading: const CircleAvatar(child: Icon(Icons.person)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: busy
                      ? null
                      : () {
                          setState(() {
                            members.remove(person);
                          });
                        },
                ),
              ),
            ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: member,
                  decoration: const InputDecoration(labelText: 'Member name'),
                ),
              ),

              const SizedBox(width: 8),

              IconButton.filled(
                onPressed: busy
                    ? null
                    : () {
                        final value = member.text.trim();

                        if (value.isEmpty) {
                          return;
                        }

                        setState(() {
                          members.add(value);

                          member.clear();
                        });
                      },
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 24),

          RoleButton(
            label: busy ? 'Creating...' : 'Create Project & Start',
            color: AppColors.university,
            onTap: () => busy ? null : _create,
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    if (name.text.trim().isEmpty || mentor.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project name and faculty mentor are required.'),
        ),
      );

      return;
    }

    setState(() => busy = true);

    try {
      await ref
          .read(universitiesApiProvider)
          .createProject(
            challengeId: widget.challengeId,
            name: name.text,
            mentor: mentor.text,
            teamMembers: members,
          );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        Routes.workspace,
        arguments: widget.challengeId,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }
}
