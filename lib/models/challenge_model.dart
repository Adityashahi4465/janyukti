import 'package:cloud_firestore/cloud_firestore.dart';

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
      'type': type,
      'resourceType': resourceType,
      'format': format,
      'bytes': bytes,
      if (duration != null) 'duration': duration,
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

  /// Speech-to-text result.
  final String transcript;

  /// Cloudinary URL of original audio.
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
      if (duration != null) 'duration': duration,
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

class Challenge {
  Challenge({
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

    this.status = 'In Progress',
    this.priority = 'Medium',

    this.submittedBy = '',
    this.submittedById = '',

    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;

  final String title;
  final String category;
  final String location;
  final String description;

  final String additionalInfo;

  final double? latitude;
  final double? longitude;

  final List<ChallengeMedia> media;
  final List<ChallengeVoiceNote> voiceNotes;

  String status;

  final String priority;

  final String submittedBy;
  final String submittedById;

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'location': location,
      'description': description,

      'additionalInfo': additionalInfo,

      'latitude': latitude,
      'longitude': longitude,

      'media': media.map((x) => x.toMap()).toList(),

      'voiceNotes': voiceNotes.map((x) => x.toMap()).toList(),

      'status': status,
      'priority': priority,

      'submittedBy': submittedBy,
      'submittedById': submittedById,

      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Challenge.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return DateTime.now();
    }

    final rawMedia = map['media'];

    final rawVoice = map['voiceNotes'];

    return Challenge(
      id: id,

      title: map['title']?.toString() ?? '',

      category: map['category']?.toString() ?? '',

      location: map['location']?.toString() ?? '',

      description: map['description']?.toString() ?? '',

      additionalInfo: map['additionalInfo']?.toString() ?? '',

      latitude: (map['latitude'] as num?)?.toDouble(),

      longitude: (map['longitude'] as num?)?.toDouble(),

      media: rawMedia is List
          ? rawMedia
                .whereType<Map>()
                .map(
                  (x) => ChallengeMedia.fromMap(Map<String, dynamic>.from(x)),
                )
                .toList()
          : [],

      voiceNotes: rawVoice is List
          ? rawVoice
                .whereType<Map>()
                .map(
                  (x) =>
                      ChallengeVoiceNote.fromMap(Map<String, dynamic>.from(x)),
                )
                .toList()
          : [],

      status: map['status']?.toString() ?? 'In Progress',

      priority: map['priority']?.toString() ?? 'Medium',

      submittedBy: map['submittedBy']?.toString() ?? '',

      submittedById: map['submittedById']?.toString() ?? '',

      createdAt: parseDate(map['createdAt']),

      updatedAt: parseDate(map['updatedAt']),
    );
  }

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
    String? submittedBy,
    String? submittedById,
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
      submittedBy: submittedBy ?? this.submittedBy,
      submittedById: submittedById ?? this.submittedById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
