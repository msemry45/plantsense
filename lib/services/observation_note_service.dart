import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/observation_note.dart';

class ObservationNoteService {
  final SupabaseClient? _clientInstance;

  ObservationNoteService({SupabaseClient? client}) : _clientInstance = client;

  SupabaseClient get _client => _clientInstance ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<ObservationNote>> getNotes(String plantId) async {
    final response = await _client
        .from('observation_notes')
        .select()
        .eq('plant_id', plantId)
        .order('observed_at', ascending: false);

    return response
        .map((row) => ObservationNote.fromJson(row))
        .toList();
  }

  Future<ObservationNote> addNote({
    required String plantId,
    required String note,
    DateTime? observedAt,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to add observation notes.');
    }

    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw Exception('Note content cannot be empty.');
    }

    final payload = {
      'plant_id': plantId,
      'author_id': userId,
      'note': trimmed,
      'observed_at': (observedAt ?? DateTime.now()).toIso8601String(),
    };

    final response = await _client
        .from('observation_notes')
        .insert(payload)
        .select()
        .single();

    return ObservationNote.fromJson(response);
  }

  Future<ObservationNote> updateNote({
    required String noteId,
    required String note,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw Exception('Note content cannot be empty.');
    }

    final response = await _client
        .from('observation_notes')
        .update({'note': trimmed})
        .eq('id', noteId)
        .select()
        .single();

    return ObservationNote.fromJson(response);
  }

  Future<void> deleteNote(String noteId) async {
    await _client.from('observation_notes').delete().eq('id', noteId);
  }
}
