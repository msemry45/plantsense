import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant.dart';

String _generateUuidV4() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  values[6] = (values[6] & 0x0f) | 0x40; // RFC 4122 Version 4
  values[8] = (values[8] & 0x3f) | 0x80; // Variant 10
  final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class PlantService {
  final SupabaseClient? _clientInstance;

  PlantService({SupabaseClient? client}) : _clientInstance = client;

  SupabaseClient get _client => _clientInstance ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Plant>> getPlants({String? search, String? status = 'active'}) async {
    var query = _client.from('plants').select('*, species(*)');

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name', '%${search.trim()}%');
    }

    final response = await query.order('created_at', ascending: false);
    final plants = response
        .map((row) => Plant.fromJson(row))
        .toList();

    // Fetch latest image thumbnail for each plant if available
    final List<Plant> enrichedPlants = [];
    for (final plant in plants) {
      String? latestImageUrl;
      try {
        final imgRows = await _client
            .from('plant_images')
            .select('storage_path')
            .eq('plant_id', plant.id)
            .order('captured_at', ascending: false)
            .limit(1);

        if (imgRows.isNotEmpty) {
          final storagePath = imgRows.first['storage_path'] as String;
          latestImageUrl = await _client.storage
              .from('plant-images')
              .createSignedUrl(storagePath, 3600);
        }
      } catch (_) {
        // Fallback gracefully without thumbnail if signed URL fails
      }
      enrichedPlants.add(plant.copyWith(latestImageUrl: latestImageUrl));
    }

    return enrichedPlants;
  }

  Future<Plant?> getPlantById(String id) async {
    final response = await _client
        .from('plants')
        .select('*, species(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    final plant = Plant.fromJson(response);

    String? latestImageUrl;
    try {
      final imgRows = await _client
          .from('plant_images')
          .select('storage_path')
          .eq('plant_id', plant.id)
          .order('captured_at', ascending: false)
          .limit(1);

      if (imgRows.isNotEmpty) {
        final storagePath = imgRows.first['storage_path'] as String;
        latestImageUrl = await _client.storage
            .from('plant-images')
            .createSignedUrl(storagePath, 3600);
      }
    } catch (_) {
      // Ignored
    }

    return plant.copyWith(latestImageUrl: latestImageUrl);
  }

  Future<Plant> createPlant({
    required String name,
    String? speciesId,
    String? location,
    DateTime? plantedOn,
    String? notes,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to create a plant.');
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Plant name cannot be empty.');
    }

    final plantId = _generateUuidV4();
    final payload = {
      'id': plantId,
      'owner_id': userId,
      'name': trimmedName,
      'species_id': (speciesId != null && speciesId.isNotEmpty) ? speciesId : null,
      'location': (location != null && location.trim().isNotEmpty) ? location.trim() : null,
      'planted_on': plantedOn?.toIso8601String().split('T').first,
      'notes': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
      'status': 'active',
    };

    await _client.from('plants').insert(payload);
    final created = await getPlantById(plantId);
    if (created == null) {
      throw Exception('Failed to retrieve created plant.');
    }
    return created;
  }

  Future<Plant> updatePlant({
    required String id,
    required String name,
    String? speciesId,
    String? location,
    DateTime? plantedOn,
    String? notes,
    String? status,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Plant name cannot be empty.');
    }

    final payload = <String, dynamic>{
      'name': trimmedName,
      'species_id': (speciesId != null && speciesId.isNotEmpty) ? speciesId : null,
      'location': (location != null && location.trim().isNotEmpty) ? location.trim() : null,
      'planted_on': plantedOn?.toIso8601String().split('T').first,
      'notes': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
    };

    if (status != null && status.isNotEmpty) {
      payload['status'] = status;
    }

    final response = await _client
        .from('plants')
        .update(payload)
        .eq('id', id)
        .select('*, species(*)')
        .single();

    return Plant.fromJson(response);
  }

  Future<void> deletePlant(String id) async {
    // Clean up physical files from private storage before database row deletion
    try {
      final rows = await _client
          .from('plant_images')
          .select('storage_path')
          .eq('plant_id', id);
      final paths = rows
          .map((r) => r['storage_path'] as String)
          .where((path) => path.isNotEmpty)
          .toList();
      if (paths.isNotEmpty) {
        await _client.storage.from('plant-images').remove(paths);
      }
    } catch (_) {
      // Best-effort storage cleanup
    }

    await _client.from('plants').delete().eq('id', id);
  }

  Future<int> getActivePlantCount() async {
    final response = await _client
        .from('plants')
        .select('id')
        .eq('status', 'active');
    return response.length;
  }
}
