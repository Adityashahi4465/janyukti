import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../models/project_model.dart';
import '../../../shared/mock_data/app_store.dart';
import '../../../shared/widgets/ui.dart';

class UniversityDashboard extends StatelessWidget {
  const UniversityDashboard({super.key});
  @override
  Widget build(BuildContext c) {
    final s = StoreScope.of(c);
    return PageFrame(
      title: 'University Dashboard',
      color: AppColors.university,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              const Stat('12', 'Challenges Assigned', AppColors.university),
              const SizedBox(width: 8),
              const Stat('8', 'Projects in Progress', AppColors.university),
            ],
          ),
          section('Quick actions'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['My Projects', 'Team', 'Mentors', 'Reports']
                .map(
                  (x) => ActionChip(
                    avatar: const Icon(Icons.grid_view, size: 16),
                    label: Text(x),
                    onPressed: () => Navigator.pushNamed(
                      c,
                      Routes.workspace,
                      arguments: s.projects.first,
                    ),
                  ),
                )
                .toList(),
          ),
          section('Recent Assigned Challenges'),
          ...s.challenges.map(
            (x) => AppCard(
              onTap: () =>
                  Navigator.pushNamed(c, Routes.challengeDetail, arguments: x),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.water_drop,
                  color: AppColors.university,
                ),
                title: Text(
                  x.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(x.location),
                trailing: StatusPill(x.priority),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UniversityChallengeDetails extends StatelessWidget {
  const UniversityChallengeDetails({super.key, required this.x});
  final Challenge x;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Challenge Details',
    color: AppColors.university,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          x.title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Challenge ID  ${x.id}'),
              const Divider(),
              Text('Category  ${x.category}'),
              Text('Location  ${x.location}'),
              Text('Submitted by  ${x.submittedBy}'),
              const SizedBox(height: 10),
              Text(x.description),
              const SizedBox(height: 10),
              StatusPill(x.priority),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RoleButton(
          label: 'Accept Challenge',
          color: AppColors.university,
          onTap: () {
            StoreScope.of(c).accept(x);
            Navigator.pushNamed(c, Routes.createProject, arguments: x);
          },
          icon: Icons.handshake,
        ),
      ],
    ),
  );
}

class CreateProjectView extends StatefulWidget {
  const CreateProjectView({super.key, required this.challenge});
  final Challenge challenge;
  @override
  State<CreateProjectView> createState() => _CreateProjectViewState();
}

class _CreateProjectViewState extends State<CreateProjectView> {
  final name = TextEditingController(text: 'Water Purification System');
  String mentor = 'Dr. Priya Sharma';
  final members = ['Ankit Kumar', 'Neha Verma'];
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Create Project',
    color: AppColors.university,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Project name *'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField(
          initialValue: mentor,
          items: [
            for (final x in ['Dr. Priya Sharma', 'Prof. Rahul Kumar'])
              DropdownMenuItem(value: x, child: Text(x)),
          ],
          onChanged: (x) => setState(() => mentor = x!),
          decoration: const InputDecoration(labelText: 'Faculty mentor'),
        ),
        section('Team members'),
        for (final x in members)
          AppCard(
            padding: 8,
            child: ListTile(
              title: Text(x),
              leading: const CircleAvatar(child: Icon(Icons.person)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => members.remove(x)),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => setState(() => members.add('New Team Member')),
          icon: const Icon(Icons.add),
          label: const Text('Add Member'),
        ),
        const SizedBox(height: 18),
        RoleButton(
          label: 'Create Project',
          color: AppColors.university,
          onTap: () {
            final p = StoreScope.of(c).createProject(name.text, mentor);
            Navigator.pushNamed(c, Routes.workspace, arguments: p);
          },
        ),
      ],
    ),
  );
}

class ProjectWorkspace extends StatelessWidget {
  const ProjectWorkspace({super.key, required this.p});
  final Project p;
  @override
  Widget build(BuildContext c) {
    final s = StoreScope.of(c);
    return DefaultTabController(
      length: 4,
      child: PageFrame(
        title: 'Project Workspace',
        color: AppColors.university,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Milestones'),
                Tab(text: 'Team'),
                Tab(text: 'Files'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: p.progress / 100,
                        color: AppColors.university,
                      ),
                      Text('${p.progress}% complete'),
                      section('Milestones'),
                      Timeline(
                        items: p.milestones,
                        active: p.activeMilestone,
                        color: AppColors.university,
                      ),
                      RoleButton(
                        label: 'Update Progress',
                        color: AppColors.university,
                        onTap: () => s.advance(p),
                        icon: Icons.update,
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(18),
                    children: p.milestones
                        .asMap()
                        .entries
                        .map(
                          (e) => AppCard(
                            child: ListTile(
                              leading: Icon(
                                e.key <= p.activeMilestone
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: AppColors.university,
                              ),
                              title: Text(e.value),
                              trailing: Text(
                                e.key < p.activeMilestone
                                    ? 'Completed'
                                    : e.key == p.activeMilestone
                                    ? 'In Progress'
                                    : 'Pending',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const Center(
                    child: Text(
                      'Faculty mentor\nDr. Priya Sharma\n\nTeam: Ankit, Neha',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.folder_open,
                      size: 60,
                      color: AppColors.muted,
                    ),
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
