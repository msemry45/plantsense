import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diagnosis.dart';

class DiagnosisService {
  final SupabaseClient _client;

  DiagnosisService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Invoke the Edge Function to analyze a plant image using Gemini Multimodal AI
  Future<Diagnosis> analyzePlantImage({
    required String plantId,
    required String imageId,
    String? speciesCommon,
    String? speciesScientific,
    String language = 'ar',
  }) async {
    final effectiveKey = (dotenv.isInitialized ? dotenv.env['GEMINI_API_KEY'] : null);
    final response = await _client.functions.invoke(
      'analyze-plant-image',
      body: {
        'plant_id': plantId,
        'image_id': imageId,
        'species_common': speciesCommon,
        'species_scientific': speciesScientific,
        'language': language,
        if (effectiveKey != null && effectiveKey.isNotEmpty)
          'gemini_api_key': effectiveKey,
      },
    );

    if (response.status != 200) {
      final errorMsg = response.data is Map
          ? (response.data['error'] ?? 'Server returned status ${response.status}')
          : 'Server returned status ${response.status}';
      throw Exception(errorMsg.toString());
    }

    final rawData = response.data;
    if (rawData is! Map) {
      throw Exception('Invalid response format from analysis service');
    }
    final data = Map<String, dynamic>.from(rawData);

    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }

    return Diagnosis.fromJson(data, isCached: data['cached'] == true);
  }

  /// Get the latest visual analysis for a given plant
  Future<Diagnosis?> getLatestDiagnosis(String plantId) async {
    final row = await _client
        .from('diagnoses')
        .select()
        .eq('plant_id', plantId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return Diagnosis.fromJson(row);
  }

  /// Get visual diagnosis for a specific plant image if it exists
  Future<Diagnosis?> getDiagnosisByImageId(String imageId) async {
    final row = await _client
        .from('diagnoses')
        .select()
        .eq('image_id', imageId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return Diagnosis.fromJson(row);
  }

  /// Retrieve the full chronological diagnosis history for a plant
  Future<List<Diagnosis>> getPlantDiagnosesHistory(String plantId) async {
    final rows = await _client
        .from('diagnoses')
        .select()
        .eq('plant_id', plantId)
        .order('created_at', ascending: false);

    return rows
        .map((r) => Diagnosis.fromJson(r))
        .toList();
  }
}
