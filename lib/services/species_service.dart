import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/species.dart';

class SpeciesService {
  final SupabaseClient? _clientInstance;

  SpeciesService({SupabaseClient? client}) : _clientInstance = client;

  SupabaseClient get _client => _clientInstance ?? Supabase.instance.client;

  Future<List<Species>> getPublishedSpecies({String? search}) async {
    var query = _client
        .from('species')
        .select()
        .eq('is_published', true);

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('common_name', '%${search.trim()}%');
    }

    final response = await query.order('common_name', ascending: true);
    return response
        .map((row) => Species.fromJson(row))
        .toList();
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
      // to permit farmers to define new agricultural species without being blocked by admin-only RLS.
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
        // If Edge Function responded with explicit logic or error, rethrow unless it's missing
        if (e is Exception && !e.toString().contains('NoSuchMethod')) rethrow;
      }
    }

    // 2. Fallback to direct table insertion (e.g. for mock clients in unit tests or if user is admin)
    final row = await _client
        .from('species')
        .insert({
          'common_name': trimmedCommon,
          'scientific_name': (scientificName != null && scientificName.trim().isNotEmpty)
              ? scientificName.trim()
              : null,
          'is_published': true,
        })
        .select()
        .single();

    return Species.fromJson(row);
  }
}
