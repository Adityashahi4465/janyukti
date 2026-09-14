import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectMilestone {
  const ProjectMilestone({
    required this.title,
    this.completed = false,
    this.completedAt,
  });

  final String title;
  final bool completed;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'completed': completed,
    'completedAt': completedAt == null
        ? null
        : Timestamp.fromDate(completedAt!),
  };

  factory ProjectMilestone.fromMap(Map<String, dynamic> map) {
    return ProjectMilestone(
      title: map['title']?.toString() ?? '',
      completed: map['completed'] as bool? ?? false,
      completedAt: _date(map['completedAt']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class Project {
  const Project({
    required this.id,
    required this.challengeId,
    required this.universityId,
    required this.universityName,
    required this.name,
    required this.mentor,
    required this.teamMembers,
    required this.status,
    required this.progress,
    required this.milestones,
    required this.createdById,
    required this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  final String challengeId;

  final String universityId;
  final String universityName;

  final String name;
  final String mentor;

  final List<String> teamMembers;

  /// active / solution_deployed / completed
  final String status;

  final int progress;

  final List<ProjectMilestone> milestones;

  final String createdById;
  final String createdByName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Project.fromMap(String id, Map<String, dynamic> map) {
    return Project(
      id: id,
      challengeId: map['challengeId']?.toString() ?? id,
      universityId: map['universityId']?.toString() ?? '',
      universityName: map['universityName']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      mentor: map['mentor']?.toString() ?? '',
      teamMembers:
          (map['teamMembers'] as List?)?.map((x) => x.toString()).toList() ??
          const [],
      status: map['status']?.toString() ?? 'active',
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      milestones:
          (map['milestones'] as List?)
              ?.whereType<Map>()
              .map(
                (x) => ProjectMilestone.fromMap(Map<String, dynamic>.from(x)),
              )
              .toList() ??
          const [],
      createdById: map['createdById']?.toString() ?? '',
      createdByName: map['createdByName']?.toString() ?? '',
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
