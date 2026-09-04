import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/project_model.dart';
import '../../../shared/mock_data/app_store.dart';
import '../../../shared/widgets/ui.dart';

class IndustryDashboard extends StatelessWidget {
  const IndustryDashboard({super.key});
  @override
  Widget build(BuildContext c) {
    final s = StoreScope.of(c);
    return PageFrame(
      title: 'Industry Dashboard',
      color: AppColors.industry,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              const Stat('15', 'Opportunities', AppColors.industry),
              const SizedBox(width: 8),
              const Stat('3', 'Collaborations', AppColors.industry),
            ],
          ),
          section('Recommended Projects'),
          ...s.projects.map(
            (p) => ProjectCard(
              p,
              onTap: () =>
                  Navigator.pushNamed(c, Routes.projectDetail, arguments: p),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard(this.p, {super.key, this.onTap});
  final Project p;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(
          '${p.university} • ${p.category}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: p.progress / 100,
          color: AppColors.industry,
        ),
        const SizedBox(height: 4),
        Text('${p.progress}% progress', style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class ProjectDetails extends StatelessWidget {
  const ProjectDetails({super.key, required this.p});
  final Project p;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Project Details',
    color: AppColors.industry,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          p.name,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('University  ${p.university}'),
              Text('Mentor  ${p.mentor}'),
              Text('Category  ${p.category}'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: p.progress / 100,
                color: AppColors.industry,
              ),
              Text('${p.progress}% progress'),
            ],
          ),
        ),
        const Text(
          'A sustainable, locally maintainable water treatment solution for communities.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        RoleButton(
          label: 'Express Interest',
          color: AppColors.industry,
          onTap: () => Navigator.pushNamed(c, Routes.interest, arguments: p),
          icon: Icons.volunteer_activism,
        ),
      ],
    ),
  );
}

class ExpressInterest extends StatefulWidget {
  const ExpressInterest({super.key, required this.p});
  final Project p;
  @override
  State<ExpressInterest> createState() => _ExpressInterestState();
}

class _ExpressInterestState extends State<ExpressInterest> {
  final selected = <String>{};
  final msg = TextEditingController();
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Express Interest',
    color: AppColors.industry,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'How can TechVentures help?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        ...[
          'Funding',
          'Technology Support',
          'Prototype Support',
          'Field Testing Support',
        ].map(
          (x) => CheckboxListTile(
            value: selected.contains(x),
            onChanged: (v) =>
                setState(() => v! ? selected.add(x) : selected.remove(x)),
            title: Text(x),
            activeColor: AppColors.industry,
          ),
        ),
        TextField(
          controller: msg,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Message (optional)'),
        ),
        const SizedBox(height: 20),
        RoleButton(
          label: 'Submit Interest',
          color: AppColors.industry,
          onTap: () {
            ScaffoldMessenger.of(c).showSnackBar(
              const SnackBar(content: Text('Interest saved locally')),
            );
            Navigator.pushNamed(c, Routes.collaborations);
          },
        ),
      ],
    ),
  );
}

class Collaborations extends StatelessWidget {
  const Collaborations({super.key});
  @override
  Widget build(BuildContext c) {
    final p = StoreScope.of(c).projects.first;
    return DefaultTabController(
      length: 2,
      child: PageFrame(
        title: 'My Collaborations',
        color: AppColors.industry,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Interested'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      ProjectCard(
                        p,
                        onTap: () => Navigator.pushNamed(c, Routes.chat),
                      ),
                    ],
                  ),
                  const Center(
                    child: Text('Your interested projects will appear here'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollaborationChat extends StatefulWidget {
  const CollaborationChat({super.key});
  @override
  State<CollaborationChat> createState() => _CollaborationChatState();
}

class _CollaborationChatState extends State<CollaborationChat> {
  final text = TextEditingController();
  @override
  Widget build(BuildContext c) {
    final s = StoreScope.of(c);
    return PageFrame(
      title: 'Collaboration Chat',
      color: AppColors.industry,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final x in s.chats)
                  Align(
                    alignment: x.startsWith('You')
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: AppCard(padding: 10, child: Text(x)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: text,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    s.send(text.text);
                    text.clear();
                  },
                  icon: const Icon(Icons.send, color: AppColors.industry),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
