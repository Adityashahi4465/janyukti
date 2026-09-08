import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import '../../models/project_model.dart';

class AppStore extends ChangeNotifier {
  final challenges = <Challenge>[
    Challenge(
      id: 'CH-2025-00124',
      title: 'Water Contamination in Village',
      category: 'Water Management',
      location: 'Ranchi, Jharkhand',
      description:
          'The drinking water in our village is polluted and causing health issues for people. A safe and sustainable water treatment solution is needed.',
      priority: 'High',
    ),
    Challenge(
      id: 'CH-2025-00125',
      title: 'Poor Waste Management in Residential Areas',
      category: 'Waste Management',
      location: 'Dhanbad, Jharkhand',
      description:
          'Several residential areas in the city lack proper waste collection and segregation facilities. Garbage is often dumped in open spaces and near roads, causing foul odors, blocked drainage systems, and an increased risk of diseases. The community needs an effective waste collection, recycling, and awareness system.',
      priority: 'High',
      status: 'Under Review',
    ),

    Challenge(
      id: 'CH-2025-00126',
      title: 'Frequent Power Outages in Rural Communities',
      category: 'Energy & Infrastructure',
      location: 'Hazaribagh, Jharkhand',
      description:
          'Villages in the surrounding region experience frequent and long-duration power cuts. Students struggle to study, small businesses lose productivity, and essential services are affected. A reliable and sustainable solution is needed to improve electricity availability and explore alternative energy sources.',
      priority: 'Medium',
      status: 'Submitted',
    ),

    Challenge(
      id: 'CH-2025-00127',
      title: 'Lack of Digital Education Resources',
      category: 'Education',
      location: 'Bokaro, Jharkhand',
      description:
          'Many government school students do not have access to digital learning resources, computers, or reliable internet connectivity. Teachers also face difficulties in providing modern and interactive learning experiences. The challenge is to develop an affordable and accessible digital education solution for students and schools.',
      priority: 'High',
    ),

    Challenge(
      id: 'CH-2025-00128',
      title: 'Unsafe Roads and Traffic Congestion Near Schools',
      category: 'Transportation & Safety',
      location: 'Jamshedpur, Jharkhand',
      description:
          'Roads near several schools experience heavy traffic congestion during morning and afternoon hours. Students face difficulties crossing roads due to speeding vehicles, inadequate pedestrian crossings, and poor traffic management. A smart and practical solution is needed to improve road safety and traffic flow.',
      priority: 'High',
    ),
  ];
  final projects = <Project>[
    Project(
      name: 'Water Purification System',
      university: 'BIT Mesra',
      category: 'Water Management',
    ),
    Project(
      name: 'Smart Waste Collection & Segregation',
      university: 'Ranchi University',
      category: 'Waste Management',
      mentor: 'Prof. Rahul Kumar',
      progress: 25,
    ),
    Project(
      name: 'Rural Solar Microgrid Initiative',
      university: 'IIT ISM',
      category: 'Energy & Infrastructure',
      mentor: 'Dr. Priya Sharma',
      progress: 35,
    ),
    Project(
      name: 'Digital Learning Access Platform',
      university: 'BIT Mesra',
      category: 'Education',
      mentor: 'Prof. Rahul Kumar',
      progress: 15,
    ),
    Project(
      name: 'School Zone Smart Mobility System',
      university: 'Ranchi University',
      category: 'Transportation & Safety',
      mentor: 'Dr. Priya Sharma',
      progress: 30,
    ),
  ];
  final chats = <String>[
    'Dr. Priya: Welcome to the project workspace!',
    'You: Looking forward to collaborating.',
  ];
  Challenge addChallenge(String t, String d, String cat, String l) {
    final c = Challenge(
      id: 'CH-2025-${(120 + challenges.length).toString().padLeft(5, '0')}',
      title: t,
      description: d,
      category: cat,
      location: l,
      status: 'Submitted',
    );
    challenges.insert(0, c);
    notifyListeners();
    return c;
  }

  void assign(Challenge c, String u) {
    c.status = 'Assigned to $u';
    notifyListeners();
  }

  void accept(Challenge c) {
    c.status = 'In Progress';
    notifyListeners();
  }

  Project createProject(String n, String m) {
    final p = Project(
      name: n,
      university: 'BIT Mesra',
      category: 'Water Management',
      mentor: m,
      progress: 20,
    );
    projects.insert(0, p);
    notifyListeners();
    return p;
  }

  void advance(Project p) {
    if (p.activeMilestone < p.milestones.length - 1) {
      p.activeMilestone++;
      p.progress = ((p.activeMilestone + 1) / p.milestones.length * 100)
          .round();
      notifyListeners();
    }
  }

  void send(String m) {
    if (m.trim().isNotEmpty) {
      chats.add('You: ${m.trim()}');
      notifyListeners();
    }
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);
  static AppStore of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
