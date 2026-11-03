class PlantImage {
  final String id;
  final String plantId;
  final String uploadedBy;
  final String storagePath;
  final String source;
  final DateTime capturedAt;
  final int? width;
  final int? height;
  final int? fileSizeBytes;
  final String? mimeType;
  final DateTime createdAt;
  final String? signedUrl;

  const PlantImage({
    required this.id,
    required this.plantId,
    required this.uploadedBy,
    required this.storagePath,
    this.source = 'gallery',
    required this.capturedAt,
    this.width,
    this.height,
    this.fileSizeBytes,
    this.mimeType,
    required this.createdAt,
    this.signedUrl,
  });

  String get formattedFileSize {
    if (fileSizeBytes == null) return '';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1024 * 1024) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  factory PlantImage.fromJson(Map<String, dynamic> json, {String? signedUrl}) {
    return PlantImage(
      id: json['id'] as String,
      plantId: json['plant_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      storagePath: json['storage_path'] as String,
      source: (json['source'] as String?) ?? 'gallery',
      capturedAt: json['captured_at'] != null
          ? DateTime.parse(json['captured_at'] as String)
          : DateTime.now(),
      width: json['width'] as int?,
      height: json['height'] as int?,
      fileSizeBytes: json['file_size_bytes'] != null
          ? (json['file_size_bytes'] as num).toInt()
          : null,
      mimeType: json['mime_type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      signedUrl: signedUrl ?? (json['signed_url'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'uploaded_by': uploadedBy,
      'storage_path': storagePath,
      'source': source,
      'captured_at': capturedAt.toIso8601String(),
      'width': width,
      'height': height,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PlantImage copyWith({
    String? id,
    String? plantId,
    String? uploadedBy,
    String? storagePath,
    String? source,
    DateTime? capturedAt,
    int? width,
    int? height,
    int? fileSizeBytes,
    String? mimeType,
    DateTime? createdAt,
    String? signedUrl,
  }) {
    return PlantImage(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      storagePath: storagePath ?? this.storagePath,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      signedUrl: signedUrl ?? this.signedUrl,
    );
  }
}

