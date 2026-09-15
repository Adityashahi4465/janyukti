import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// COLLABORATION INTEREST
// ============================================================

class CollaborationInterest {
  const CollaborationInterest({
    required this.id,
    required this.projectId,
    required this.challengeId,
    required this.universityId,
    required this.universityName,
    required this.industryOrganizationId,
    required this.industryName,
    required this.submittedById,
    required this.submittedByName,
    required this.contributionType,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String projectId;
  final String challengeId;

  final String universityId;
  final String universityName;

  final String industryOrganizationId;
  final String industryName;

  final String submittedById;
  final String submittedByName;

  /// Funding
  /// Technical Expertise
  /// Manufacturing
  /// Deployment Support
  /// Mentorship
  /// Other
  final String contributionType;

  final String message;

  /// pending / accepted / rejected / withdrawn
  final String status;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending =>
      status.trim().toLowerCase() == 'pending';

  bool get isAccepted =>
      status.trim().toLowerCase() == 'accepted';

  bool get isRejected =>
      status.trim().toLowerCase() == 'rejected';

  bool get isWithdrawn =>
      status.trim().toLowerCase() == 'withdrawn';

  factory CollaborationInterest.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return CollaborationInterest(
      id: id,
      projectId:
          map['projectId']?.toString() ?? '',
      challengeId:
          map['challengeId']?.toString() ?? '',
      universityId:
          map['universityId']?.toString() ?? '',
      universityName:
          map['universityName']?.toString() ?? '',
      industryOrganizationId:
          map['industryOrganizationId']
                  ?.toString() ??
              '',
      industryName:
          map['industryName']?.toString() ?? '',
      submittedById:
          map['submittedById']?.toString() ?? '',
      submittedByName:
          map['submittedByName']?.toString() ?? '',
      contributionType:
          map['contributionType']?.toString() ?? '',
      message:
          map['message']?.toString() ?? '',
      status:
          map['status']?.toString() ?? 'pending',
      createdAt:
          _date(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _date(map['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ============================================================
// CHAT MESSAGE
// ============================================================

class CollaborationMessage {
  const CollaborationMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final String id;

  final String senderId;
  final String senderName;

  /// industry / university
  final String senderRole;

  final String text;

  final DateTime createdAt;

  factory CollaborationMessage.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return CollaborationMessage(
      id: id,
      senderId:
          map['senderId']?.toString() ?? '',
      senderName:
          map['senderName']?.toString() ?? '',
      senderRole:
          map['senderRole']?.toString() ?? '',
      text:
          map['text']?.toString() ?? '',
      createdAt:
          _date(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ============================================================
// INDUSTRY IDENTITY
// ============================================================

class IndustryIdentity {
  const IndustryIdentity({
    required this.uid,
    required this.fullName,
    required this.organizationId,
    required this.organizationName,
  });

  final String uid;
  final String fullName;

  final String organizationId;
  final String organizationName;
}

// ============================================================
// DATE
// ============================================================

DateTime? _date(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return null;
}