class ObservationNote {
  final String id;
  final String plantId;
  final String authorId;
  final String note;
  final DateTime observedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ObservationNote({
    required this.id,
    required this.plantId,
    required this.authorId,
    required this.note,
    required this.observedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ObservationNote.fromJson(Map<String, dynamic> json) {
    return ObservationNote(
      id: json['id'] as String,
      plantId: json['plant_id'] as String,
      authorId: json['author_id'] as String,
      note: json['note'] as String,
      observedAt: json['observed_at'] != null
          ? DateTime.parse(json['observed_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'author_id': authorId,
      'note': note,
      'observed_at': observedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ObservationNote copyWith({
    String? id,
    String? plantId,
    String? authorId,
    String? note,
    DateTime? observedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ObservationNote(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      authorId: authorId ?? this.authorId,
      note: note ?? this.note,
      observedAt: observedAt ?? this.observedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

