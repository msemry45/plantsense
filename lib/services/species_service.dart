import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/species.dart';

class SpeciesService {
  final SupabaseClient? _clientInstance;
  static const String _cacheKeySpecies = 'svpg_cached_encyclopedia_species_v2';
  static const String _cacheKeyTimestamp = 'svpg_cached_encyclopedia_timestamp_v2';

  SpeciesService({SupabaseClient? client}) : _clientInstance = client;

  SupabaseClient get _client => _clientInstance ?? Supabase.instance.client;

  /// Get published species for the public Encyclopedia (Guests and Farmers) with local device caching
  Future<List<Species>> getPublishedSpecies({String? search, bool forceRefresh = false}) async {
    final isSearching = search != null && search.trim().isNotEmpty;

    // 1. If not searching and not forcing refresh, try to read from local device cache first
    if (!isSearching && !forceRefresh) {
      try {
        final cachedList = await _loadFromCache();
        if (cachedList != null && cachedList.isNotEmpty) {
          // Trigger asynchronous background refresh without blocking user
          _refreshCacheInBackground();
          return cachedList;
        }
      } catch (_) {
        // Cache read failure, proceed to remote fetch
      }
    }

    try {
      var query = _client
          .from('species')
          .select()
          .eq('is_published', true);

      if (isSearching) {
        query = query.ilike('common_name', '%${search.trim()}%');
      }

      final response = await query.order('common_name', ascending: true);
      final list = response.map((row) => Species.fromJson(row)).toList();

      // If full list (not search), save to local device cache
      if (!isSearching && list.isNotEmpty) {
        await _saveToCache(response);
      }

      return list;
    } catch (e) {
      // If network fails (e.g. offline or server error), fall back to cache
      if (!isSearching) {
        final fallback = await _loadFromCache();
        if (fallback != null && fallback.isNotEmpty) {
          return fallback;
        }
      }
      rethrow;
    }
  }

  Future<List<Species>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKeySpecies);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson);
        if (decoded is List) {
          return decoded.map((e) => Species.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveToCache(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeySpecies, jsonEncode(data));
      await prefs.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeySpecies);
      await prefs.remove(_cacheKeyTimestamp);
    } catch (_) {}
  }

  void _refreshCacheInBackground() {
    Future.microtask(() async {
      try {
        final response = await _client
            .from('species')
            .select()
            .eq('is_published', true)
            .order('common_name', ascending: true);
        if (response.isNotEmpty) {
          await _saveToCache(response);
        }
      } catch (_) {}
    });
  }

  /// Get species available for plant creation (published species + farmer's own custom species)
  Future<List<Species>> getAvailableSpeciesForPlant({String? search}) async {
    final user = _client.auth.currentUser;
    var query = _client.from('species').select();

    if (user != null) {
      query = query.or('is_published.eq.true,created_by.eq.${user.id}');
    } else {
      query = query.eq('is_published', true);
    }

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('common_name', '%${search.trim()}%');
    }

    final response = await query.order('common_name', ascending: true);
    return response.map((row) => Species.fromJson(row)).toList();
  }

  Future<Species?> getSpeciesById(String id) async {
    final response = await _client
        .from('species')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Species.fromJson(response);
  }

  Future<Species> createCustomSpecies(
    String commonName, {
    String? scientificName,
  }) async {
    final trimmedCommon = commonName.trim();
    if (trimmedCommon.isEmpty) {
      throw ArgumentError('Common name cannot be empty');
    }

    try {
      // 1. Attempt insertion via backend Edge Function with service-role permissions
      final response = await _client.functions.invoke(
        'analyze-plant-image',
        body: {
          'action': 'create_species',
          'common_name': trimmedCommon,
          'scientific_name': scientificName?.trim(),
        },
      );

      final data = response.data;
      if (data is Map && data['species'] != null) {
        return Species.fromJson(Map<String, dynamic>.from(data['species']));
      } else if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
    } catch (e) {
      if (e is! UnimplementedError && !e.toString().contains('functions')) {
        if (e is Exception && !e.toString().contains('NoSuchMethod')) rethrow;
      }
    }

    // 2. Fallback to direct table insertion
    final row = await _client
        .from('species')
        .insert({
          'common_name': trimmedCommon,
          'scientific_name': (scientificName != null && scientificName.trim().isNotEmpty)
              ? scientificName.trim()
              : null,
          'is_published': false,
          'created_by': _client.auth.currentUser?.id,
        })
        .select()
        .single();

    return Species.fromJson(row);
  }

  /// Get all species for admin review (including unpublished drafts)
  Future<List<Species>> getAllSpeciesForAdmin({String? search}) async {
    var query = _client.from('species').select();

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('common_name', '%${search.trim()}%');
    }

    final response = await query.order('created_at', ascending: false);
    return response.map((row) => Species.fromJson(row)).toList();
  }

  /// Toggle published status of a species in the encyclopedia (Admin only)
  Future<Species> toggleSpeciesPublished(String speciesId, bool isPublished) async {
    final response = await _client
        .from('species')
        .update({'is_published': isPublished, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', speciesId)
        .select()
        .single();

    await clearCache();
    return Species.fromJson(response);
  }

  /// Delete species from encyclopedia (Admin only)
  Future<void> deleteSpecies(String speciesId) async {
    await _client.from('species').delete().eq('id', speciesId);
    await clearCache();
  }

  /// Create species manually (Admin only)
  Future<Species> createSpecies({
    required String commonName,
    String? scientificName,
    String? description,
    String? careInstructions,
    num? idealTemperatureMin,
    num? idealTemperatureMax,
    num? idealHumidityMin,
    num? idealHumidityMax,
    String? idealLightConditions,
    String? imagePath,
    String? sourceUrl,
    String? license,
    String? attribution,
    bool isPublished = true,
  }) async {
    final insertData = <String, dynamic>{
      'common_name': commonName.trim(),
      'is_published': isPublished,
      'created_by': _client.auth.currentUser?.id,
      if (scientificName != null && scientificName.trim().isNotEmpty)
        'scientific_name': scientificName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (careInstructions != null && careInstructions.trim().isNotEmpty)
        'care_instructions': careInstructions.trim(),
      if (idealTemperatureMin != null) 'ideal_temperature_min': idealTemperatureMin,
      if (idealTemperatureMax != null) 'ideal_temperature_max': idealTemperatureMax,
      if (idealHumidityMin != null) 'ideal_humidity_min': idealHumidityMin,
      if (idealHumidityMax != null) 'ideal_humidity_max': idealHumidityMax,
      if (idealLightConditions != null && idealLightConditions.trim().isNotEmpty)
        'ideal_light_conditions': idealLightConditions.trim(),
      if (imagePath != null && imagePath.trim().isNotEmpty)
        'image_path': imagePath.trim(),
      if (sourceUrl != null && sourceUrl.trim().isNotEmpty)
        'source_url': sourceUrl.trim(),
      if (license != null && license.trim().isNotEmpty)
        'license': license.trim(),
      if (attribution != null && attribution.trim().isNotEmpty)
        'attribution': attribution.trim(),
    };

    final row = await _client.from('species').insert(insertData).select().single();
    await clearCache();
    return Species.fromJson(row);
  }

  /// Update species details (Admin only)
  Future<Species> updateSpecies({
    required String id,
    String? commonName,
    String? scientificName,
    String? description,
    String? careInstructions,
    num? idealTemperatureMin,
    num? idealTemperatureMax,
    num? idealHumidityMin,
    num? idealHumidityMax,
    String? idealLightConditions,
    String? imagePath,
    String? sourceUrl,
    String? license,
    String? attribution,
    bool? isPublished,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (commonName != null) 'common_name': commonName.trim(),
      if (scientificName != null) 'scientific_name': scientificName.trim(),
      if (description != null) 'description': description.trim(),
      if (careInstructions != null) 'care_instructions': careInstructions.trim(),
      if (idealTemperatureMin != null) 'ideal_temperature_min': idealTemperatureMin,
      if (idealTemperatureMax != null) 'ideal_temperature_max': idealTemperatureMax,
      if (idealHumidityMin != null) 'ideal_humidity_min': idealHumidityMin,
      if (idealHumidityMax != null) 'ideal_humidity_max': idealHumidityMax,
      if (idealLightConditions != null) 'ideal_light_conditions': idealLightConditions,
      if (imagePath != null) 'image_path': imagePath.trim(),
      if (sourceUrl != null) 'source_url': sourceUrl.trim(),
      if (license != null) 'license': license.trim(),
      if (attribution != null) 'attribution': attribution.trim(),
      if (isPublished != null) 'is_published': isPublished,
    };

    final response = await _client
        .from('species')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    await clearCache();
    return Species.fromJson(response);
  }
}
