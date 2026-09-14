import 'package:cloud_firestore/cloud_firestore.dart';

class UniversityModel {
  const UniversityModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.domain = '',
    this.website = '',
    this.type = '',
    this.city = '',
    this.state = '',
    this.address = '',
    this.active = true,
    this.mlEligible = false,
    this.source = 'registration',
    this.aliases = const [],
    this.departments = const [],
    this.capabilities = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  final String name;
  final String normalizedName;

  final String domain;
  final String website;

  final String type;

  final String city;
  final String state;
  final String address;

  final bool active;

  /// true when this university exists in / is synchronized
  /// with the ML matching dataset.
  final bool mlEligible;

  /// ml_seed / registration
  final String source;

  final List<String> aliases;
  final List<String> departments;

  /// Example:
  /// {
  ///   "wasteManagement": 0.85,
  ///   "waterManagement": 0.70
  /// }
  final Map<String, double> capabilities;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UniversityModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final rawCapabilities = map['capabilities'];

    return UniversityModel(
      id: id,

      name: map['name']?.toString() ?? '',

      normalizedName: map['normalizedName']?.toString() ?? '',

      domain: map['domain']?.toString() ?? '',

      website: map['website']?.toString() ?? '',

      type: map['type']?.toString() ?? '',

      city: map['city']?.toString() ?? '',

      state: map['state']?.toString() ?? '',

      address: map['address']?.toString() ?? '',

      active: map['active'] as bool? ?? true,

      mlEligible: map['mlEligible'] as bool? ?? false,

      source: map['source']?.toString() ?? 'registration',

      aliases:
          (map['aliases'] as List?)?.map((x) => x.toString()).toList() ??
          const [],

      departments:
          (map['departments'] as List?)?.map((x) => x.toString()).toList() ??
          const [],

      capabilities: rawCapabilities is Map
          ? rawCapabilities.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num).toDouble()),
            )
          : const {},

      createdAt: _date(map['createdAt']),

      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'name': name,
      'normalizedName': normalizedName,

      'domain': domain,
      'website': website,

      'type': type,

      'city': city,
      'state': state,
      'address': address,

      'active': active,

      'mlEligible': mlEligible,

      'source': source,

      'aliases': aliases,

      'departments': departments,

      'capabilities': capabilities,

      'createdAt': createdAt,

      'updatedAt': updatedAt,
    };
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
