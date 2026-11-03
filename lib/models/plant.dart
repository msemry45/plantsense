import 'species.dart';

class Plant {
  final String id;
  final String ownerId;
  final String? speciesId;
  final String name;
  final String? location;
  final DateTime? plantedOn;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Species? species;
  final String? latestImageUrl;

  const Plant({
    required this.id,
    required this.ownerId,
    this.speciesId,
    required this.name,
    this.location,
    this.plantedOn,
    this.notes,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.species,
    this.latestImageUrl,
  });

  int? get daysSincePlanted {
    if (plantedOn == null) return null;
    final now = DateTime.now();
    final difference = now.difference(plantedOn!).inDays;
    return difference >= 0 ? difference : 0;
  }

  factory Plant.fromJson(Map<String, dynamic> json) {
    Species? parsedSpecies;
    if (json['species'] != null && json['species'] is Map<String, dynamic>) {
      parsedSpecies = Species.fromJson(json['species'] as Map<String, dynamic>);
    }

    return Plant(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      speciesId: json['species_id'] as String?,
      name: json['name'] as String,
      location: json['location'] as String?,
      plantedOn: json['planted_on'] != null
          ? DateTime.tryParse(json['planted_on'] as String)
          : null,
      notes: json['notes'] as String?,
      status: (json['status'] as String?) ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      species: parsedSpecies,
      latestImageUrl: json['latest_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'species_id': speciesId,
      'name': name,
      'location': location,
      'planted_on': plantedOn?.toIso8601String().split('T').first,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Plant copyWith({
    String? id,
    String? ownerId,
    String? speciesId,
    String? name,
    String? location,
    DateTime? plantedOn,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Species? species,
    String? latestImageUrl,
  }) {
    return Plant(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      speciesId: speciesId ?? this.speciesId,
      name: name ?? this.name,
      location: location ?? this.location,
      plantedOn: plantedOn ?? this.plantedOn,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      species: species ?? this.species,
      latestImageUrl: latestImageUrl ?? this.latestImageUrl,
    );
  }
}

