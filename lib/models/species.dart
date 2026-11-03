class Species {
  final String id;
  final String commonName;
  final String? scientificName;
  final String? description;
  final String? careInstructions;
  final double? idealTemperatureMin;
  final double? idealTemperatureMax;
  final double? idealHumidityMin;
  final double? idealHumidityMax;
  final String? idealLightConditions;
  final String? imagePath;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Species({
    required this.id,
    required this.commonName,
    this.scientificName,
    this.description,
    this.careInstructions,
    this.idealTemperatureMin,
    this.idealTemperatureMax,
    this.idealHumidityMin,
    this.idealHumidityMax,
    this.idealLightConditions,
    this.imagePath,
    this.isPublished = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['id'] as String,
      commonName: json['common_name'] as String,
      scientificName: json['scientific_name'] as String?,
      description: json['description'] as String?,
      careInstructions: json['care_instructions'] as String?,
      idealTemperatureMin: json['ideal_temperature_min'] != null
          ? (json['ideal_temperature_min'] as num).toDouble()
          : null,
      idealTemperatureMax: json['ideal_temperature_max'] != null
          ? (json['ideal_temperature_max'] as num).toDouble()
          : null,
      idealHumidityMin: json['ideal_humidity_min'] != null
          ? (json['ideal_humidity_min'] as num).toDouble()
          : null,
      idealHumidityMax: json['ideal_humidity_max'] != null
          ? (json['ideal_humidity_max'] as num).toDouble()
          : null,
      idealLightConditions: json['ideal_light_conditions'] as String?,
      imagePath: json['image_path'] as String?,
      isPublished: (json['is_published'] as bool?) ?? false,
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
      'common_name': commonName,
      'scientific_name': scientificName,
      'description': description,
      'care_instructions': careInstructions,
      'ideal_temperature_min': idealTemperatureMin,
      'ideal_temperature_max': idealTemperatureMax,
      'ideal_humidity_min': idealHumidityMin,
      'ideal_humidity_max': idealHumidityMax,
      'ideal_light_conditions': idealLightConditions,
      'image_path': imagePath,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

