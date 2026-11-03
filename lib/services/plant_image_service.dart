import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant_image.dart';

class PlantImageService {
  final SupabaseClient? _clientInstance;

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
  ];

  PlantImageService({SupabaseClient? client}) : _clientInstance = client;

  SupabaseClient get _client => _clientInstance ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<PlantImage>> getPlantImages(String plantId) async {
    final response = await _client
        .from('plant_images')
        .select()
        .eq('plant_id', plantId)
        .order('captured_at', ascending: false);

    final List<PlantImage> images = [];

    for (final row in response) {
      final img = PlantImage.fromJson(row);
      String? signedUrl;
      try {
        signedUrl = await _client.storage
            .from('plant-images')
            .createSignedUrl(img.storagePath, 3600);
      } catch (_) {
        // Fallback if signed URL generation fails
      }
      images.add(img.copyWith(signedUrl: signedUrl));
    }

    return images;
  }

  Future<PlantImage> uploadPlantImage({
    required String plantId,
    required Uint8List imageBytes,
    required String fileName,
    String source = 'gallery',
    String mimeType = 'image/jpeg',
    DateTime? capturedAt,
    int? width,
    int? height,
  }) async {
    // Client-side validation: File size check
    if (imageBytes.isEmpty) {
      throw Exception('Selected image file is empty.');
    }
    if (imageBytes.length > maxFileSizeBytes) {
      final sizeMb = (imageBytes.length / (1024 * 1024)).toStringAsFixed(1);
      throw Exception('Image size ($sizeMb MB) exceeds the maximum allowed 10 MB limit.');
    }

    // Client-side validation: MIME type check
    final normalizedMime = mimeType.toLowerCase();
    if (!allowedMimeTypes.contains(normalizedMime)) {
      throw Exception('Unsupported image format ($normalizedMime). Allowed: JPEG, PNG, WebP, HEIC.');
    }

    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to upload plant images.');
    }

    // Construct path adhering strictly to RLS: {userId}/{plantId}/{timestamp}_{sanitizedName}
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$userId/$plantId/${timestamp}_$sanitizedName';

    // 1. Upload to Supabase Storage
    await _client.storage.from('plant-images').uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(
            contentType: normalizedMime,
            upsert: false,
          ),
        );

    // 2. Insert metadata record in database
    final captureTimestamp = capturedAt ?? DateTime.now();
    final insertPayload = {
      'plant_id': plantId,
      'uploaded_by': userId,
      'storage_path': storagePath,
      'source': source,
      'captured_at': captureTimestamp.toIso8601String(),
      'width': width,
      'height': height,
      'file_size_bytes': imageBytes.length,
      'mime_type': normalizedMime,
    };

    final record = await _client
        .from('plant_images')
        .insert(insertPayload)
        .select()
        .single();

    // 3. Generate signed URL for immediate preview
    String? signedUrl;
    try {
      signedUrl = await _client.storage
          .from('plant-images')
          .createSignedUrl(storagePath, 3600);
    } catch (_) {}

    return PlantImage.fromJson(record, signedUrl: signedUrl);
  }

  Future<void> deletePlantImage(PlantImage image) async {
    // Delete database row
    await _client.from('plant_images').delete().eq('id', image.id);

    // Delete storage file
    try {
      await _client.storage.from('plant-images').remove([image.storagePath]);
    } catch (_) {
      // Ignored if storage file was already cleaned
    }
  }
}
