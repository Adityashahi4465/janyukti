import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// CHALLENGE MEDIA
// ============================================================

class ChallengeMedia {
  const ChallengeMedia({
    required this.url,
    required this.publicId,
    required this.type,
    required this.resourceType,
    required this.format,
    required this.bytes,
    this.duration,
  });

  /// photo / video
  final String type;

  /// Cloudinary secure URL
  final String url;

  /// Cloudinary public id
  final String publicId;

  final String resourceType;
  final String format;
  final int bytes;
  final double? duration;

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'publicId': publicId,
      'type': type,
      'resourceType': resourceType,
      'format': format,
      'bytes': bytes,
      'duration': duration,
    };
  }

  factory ChallengeMedia.fromMap(Map<String, dynamic> map) {
    return ChallengeMedia(
      url: map['url']?.toString() ?? '',
      publicId: map['publicId']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      resourceType: map['resourceType']?.toString() ?? '',
      format: map['format']?.toString() ?? '',
      bytes: (map['bytes'] as num?)?.toInt() ?? 0,
      duration: (map['duration'] as num?)?.toDouble(),
    );
  }
}

// ============================================================
// VOICE NOTE
// ============================================================

class ChallengeVoiceNote {
  const ChallengeVoiceNote({
    required this.url,
    required this.publicId,
    required this.field,
    required this.transcript,
    required this.resourceType,
    required this.format,
    required this.bytes,
    this.duration,
  });

  /// title / description / additional
  final String field;

  /// Speech-to-text result
  final String transcript;

  /// Cloudinary secure URL
  final String url;

  final String publicId;
  final String resourceType;
  final String format;
  final int bytes;
  final double? duration;

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'publicId': publicId,
      'field': field,
      'transcript': transcript,
      'resourceType': resourceType,
      'format': format,
      'bytes': bytes,
      'duration': duration,
    };
  }

  factory ChallengeVoiceNote.fromMap(Map<String, dynamic> map) {
    return ChallengeVoiceNote(
      url: map['url']?.toString() ?? '',
      publicId: map['publicId']?.toString() ?? '',
      field: map['field']?.toString() ?? '',
      transcript: map['transcript']?.toString() ?? '',
      resourceType: map['resourceType']?.toString() ?? '',
      format: map['format']?.toString() ?? '',
      bytes: (map['bytes'] as num?)?.toInt() ?? 0,
      duration: (map['duration'] as num?)?.toDouble(),
    );
  }
}

// ============================================================
// STATUS HISTORY
// ============================================================

class ChallengeStatusEvent {
  const ChallengeStatusEvent({
    required this.status,
    required this.at,
    required this.updatedById,
    required this.updatedByName,
    this.note = '',
  });

  final String status;

  final DateTime at;

  final String updatedById;
  final String updatedByName;

  final String note;

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'at': Timestamp.fromDate(at),
      'updatedById': updatedById,
      'updatedByName': updatedByName,
      'note': note,
    };
  }

  factory ChallengeStatusEvent.fromMap(Map<String, dynamic> map) {
    return ChallengeStatusEvent(
      status: map['status']?.toString() ?? '',
      at: _parseDate(map['at']) ?? DateTime.now(),
      updatedById: map['updatedById']?.toString() ?? '',
      updatedByName: map['updatedByName']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }
}

// ============================================================
// CHALLENGE
// ============================================================

class Challenge {
  const Challenge({
    this.id = '',

    required this.title,
    required this.category,
    required this.location,
    required this.description,

    this.additionalInfo = '',

    this.latitude,
    this.longitude,

    this.media = const [],
    this.voiceNotes = const [],

    // Workflow
    this.status = 'Submitted',
    this.priority = 'Medium',
    this.statusHistory = const [],

    // Citizen
    this.submittedBy = '',
    this.submittedById = '',

    // Review
    this.reviewedById,
    this.reviewedByName,
    this.reviewedAt,

    // University assignment
    this.assignedUniversityId,
    this.assignedUniversityName,
    this.assignedById,
    this.assignedByName,
    this.assignedAt,

    // Lifecycle
    this.solutionDeployedAt,
    this.resolvedAt,

    // Audit
    this.lastUpdatedById = '',
    this.lastUpdatedByName = '',

    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // IDENTITY
  // ============================================================

  final String id;

  // ============================================================
  // BASIC INFORMATION
  // ============================================================

  final String title;
  final String category;
  final String location;
  final String description;
  final String additionalInfo;

  // ============================================================
  // LOCATION
  // ============================================================

  final double? latitude;
  final double? longitude;

  GeoPoint? get geoPoint {
    if (latitude == null || longitude == null) {
      return null;
    }

    return GeoPoint(latitude!, longitude!);
  }

  // ============================================================
  // EVIDENCE
  // ============================================================

  final List<ChallengeMedia> media;
  final List<ChallengeVoiceNote> voiceNotes;

  // ============================================================
  // WORKFLOW
  // ============================================================

  final String status;
  final String priority;

  final List<ChallengeStatusEvent> statusHistory;

  // ============================================================
  // CITIZEN
  // ============================================================

  final String submittedBy;
  final String submittedById;

  // ============================================================
  // ADMIN REVIEW
  // ============================================================

  final String? reviewedById;
  final String? reviewedByName;
  final DateTime? reviewedAt;

  // ============================================================
  // UNIVERSITY ASSIGNMENT
  // ============================================================

  final String? assignedUniversityId;
  final String? assignedUniversityName;

  final String? assignedById;
  final String? assignedByName;

  final DateTime? assignedAt;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  final DateTime? solutionDeployedAt;
  final DateTime? resolvedAt;

  // ============================================================
  // AUDIT
  // ============================================================

  final String lastUpdatedById;
  final String lastUpdatedByName;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ============================================================
  // FIRESTORE MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      // Basic
      'title': title,
      'category': category,
      'location': location,
      'description': description,
      'additionalInfo': additionalInfo,

      // Coordinates
      'latitude': latitude,
      'longitude': longitude,
      'geoPoint': geoPoint,

      // Evidence
      'media': media.map((item) => item.toMap()).toList(),
      'voiceNotes': voiceNotes.map((item) => item.toMap()).toList(),

      // Workflow
      'status': status,
      'priority': priority,

      'statusHistory': statusHistory.map((item) => item.toMap()).toList(),

      // Citizen
      'submittedBy': submittedBy,
      'submittedById': submittedById,

      // Review
      'reviewedById': reviewedById,
      'reviewedByName': reviewedByName,
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),

      // University
      'assignedUniversityId': assignedUniversityId,
      'assignedUniversityName': assignedUniversityName,

      'assignedById': assignedById,
      'assignedByName': assignedByName,

      'assignedAt': assignedAt == null ? null : Timestamp.fromDate(assignedAt!),

      // Lifecycle
      'solutionDeployedAt': solutionDeployedAt == null
          ? null
          : Timestamp.fromDate(solutionDeployedAt!),

      'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),

      // Audit
      'lastUpdatedById': lastUpdatedById,
      'lastUpdatedByName': lastUpdatedByName,

      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory Challenge.fromMap({
    String id = '',
    required Map<String, dynamic> map,
  }) {
    final rawMedia = map['media'];
    final rawVoiceNotes = map['voiceNotes'];
    final rawStatusHistory = map['statusHistory'];

    double? latitude = (map['latitude'] as num?)?.toDouble();

    double? longitude = (map['longitude'] as num?)?.toDouble();

    // Backward compatibility:
    // if lat/lng are missing but geoPoint exists.
    final rawGeoPoint = map['geoPoint'];

    if (rawGeoPoint is GeoPoint) {
      latitude ??= rawGeoPoint.latitude;
      longitude ??= rawGeoPoint.longitude;
    }

    return Challenge(
      id: id,

      // Basic
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      additionalInfo: map['additionalInfo']?.toString() ?? '',

      // Location
      latitude: latitude,
      longitude: longitude,

      // Media
      media: rawMedia is List
          ? rawMedia
                .whereType<Map>()
                .map(
                  (item) =>
                      ChallengeMedia.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],

      // Voice
      voiceNotes: rawVoiceNotes is List
          ? rawVoiceNotes
                .whereType<Map>()
                .map(
                  (item) => ChallengeVoiceNote.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],

      // Workflow
      status: map['status']?.toString() ?? 'Submitted',

      priority: map['priority']?.toString() ?? 'Medium',

      statusHistory: rawStatusHistory is List
          ? rawStatusHistory
                .whereType<Map>()
                .map(
                  (item) => ChallengeStatusEvent.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],

      // Citizen
      submittedBy: map['submittedBy']?.toString() ?? '',

      submittedById: map['submittedById']?.toString() ?? '',

      // Review
      reviewedById: map['reviewedById']?.toString(),

      reviewedByName: map['reviewedByName']?.toString(),

      reviewedAt: _parseDate(map['reviewedAt']),

      // University
      assignedUniversityId: map['assignedUniversityId']?.toString(),

      assignedUniversityName: map['assignedUniversityName']?.toString(),

      assignedById: map['assignedById']?.toString(),

      assignedByName: map['assignedByName']?.toString(),

      assignedAt: _parseDate(map['assignedAt']),

      // Lifecycle
      solutionDeployedAt: _parseDate(map['solutionDeployedAt']),

      resolvedAt: _parseDate(map['resolvedAt']),

      // Audit
      lastUpdatedById: map['lastUpdatedById']?.toString() ?? '',

      lastUpdatedByName: map['lastUpdatedByName']?.toString() ?? '',

      // Dates
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),

      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Challenge copyWith({
    String? id,
    String? title,
    String? category,
    String? location,
    String? description,
    String? additionalInfo,

    double? latitude,
    double? longitude,

    List<ChallengeMedia>? media,
    List<ChallengeVoiceNote>? voiceNotes,

    String? status,
    String? priority,

    List<ChallengeStatusEvent>? statusHistory,

    String? submittedBy,
    String? submittedById,

    String? reviewedById,
    String? reviewedByName,
    DateTime? reviewedAt,

    String? assignedUniversityId,
    String? assignedUniversityName,
    String? assignedById,
    String? assignedByName,
    DateTime? assignedAt,

    DateTime? solutionDeployedAt,
    DateTime? resolvedAt,

    String? lastUpdatedById,
    String? lastUpdatedByName,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Challenge(
      id: id ?? this.id,

      title: title ?? this.title,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,

      additionalInfo: additionalInfo ?? this.additionalInfo,

      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,

      media: media ?? this.media,

      voiceNotes: voiceNotes ?? this.voiceNotes,

      status: status ?? this.status,

      priority: priority ?? this.priority,

      statusHistory: statusHistory ?? this.statusHistory,

      submittedBy: submittedBy ?? this.submittedBy,

      submittedById: submittedById ?? this.submittedById,

      reviewedById: reviewedById ?? this.reviewedById,

      reviewedByName: reviewedByName ?? this.reviewedByName,

      reviewedAt: reviewedAt ?? this.reviewedAt,

      assignedUniversityId: assignedUniversityId ?? this.assignedUniversityId,

      assignedUniversityName:
          assignedUniversityName ?? this.assignedUniversityName,

      assignedById: assignedById ?? this.assignedById,

      assignedByName: assignedByName ?? this.assignedByName,

      assignedAt: assignedAt ?? this.assignedAt,

      solutionDeployedAt: solutionDeployedAt ?? this.solutionDeployedAt,

      resolvedAt: resolvedAt ?? this.resolvedAt,

      lastUpdatedById: lastUpdatedById ?? this.lastUpdatedById,

      lastUpdatedByName: lastUpdatedByName ?? this.lastUpdatedByName,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// DATE PARSER
// ============================================================

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}
