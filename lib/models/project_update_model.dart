import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectUpdate {
  const ProjectUpdate({
    required this.id,
    required this.challengeId,
    required this.type,
    required this.title,
    required this.description,
    required this.progressPercent,
    required this.universityId,
    required this.universityName,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
  });

  final String id;
  final String challengeId;

  /// progress / blocker / milestone / solution
  final String type;

  final String title;
  final String description;

  final int progressPercent;

  final String universityId;
  final String universityName;

  final String createdById;
  final String createdByName;

  final DateTime createdAt;

  factory ProjectUpdate.fromMap(String id, Map<String, dynamic> map) {
    return ProjectUpdate(
      id: id,
      challengeId: map['challengeId']?.toString() ?? '',
      type: map['type']?.toString() ?? 'progress',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      universityId: map['universityId']?.toString() ?? '',
      universityName: map['universityName']?.toString() ?? '',
      createdById: map['createdById']?.toString() ?? '',
      createdByName: map['createdByName']?.toString() ?? '',
      createdAt:
          _date(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
