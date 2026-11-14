import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/care_task.dart';

class CareTaskService {
  final SupabaseClient? _clientInstance;

  CareTaskService({SupabaseClient? client}) : _clientInstance = client;

  SupabaseClient get _client => _clientInstance ?? Supabase.instance.client;

  /// Fetch all care tasks for a specific plant, sorted by due_at ascending
  Future<List<CareTask>> getCareTasksForPlant(String plantId) async {
    final rows = await _client
        .from('care_tasks')
        .select()
        .eq('plant_id', plantId)
        .order('due_at', ascending: true);

    return rows.map((r) => CareTask.fromJson(r)).toList();
  }

  /// Create a new care task
  Future<CareTask> createCareTask({
    required String plantId,
    required String title,
    String? description,
    String taskType = 'other',
    DateTime? dueAt,
    int? repeatEveryDays,
  }) async {
    final user = _client.auth.currentUser;
    final row = await _client
        .from('care_tasks')
        .insert({
          'plant_id': plantId,
          'created_by': user?.id,
          'title': title,
          'description': description,
          'task_type': taskType,
          'due_at': (dueAt ?? DateTime.now()).toIso8601String(),
          'repeat_every_days': repeatEveryDays,
          'status': 'pending',
        })
        .select()
        .single();

    return CareTask.fromJson(row);
  }

  /// Mark a care task as completed and automatically schedule recurring task if applicable
  Future<CareTask> completeCareTask(CareTask task) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    final updatedRow = await _client
        .from('care_tasks')
        .update({
          'status': 'completed',
          'completed_at': now.toIso8601String(),
          'completed_by': user?.id,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', task.id)
        .select()
        .single();

    // If recurring, schedule next occurrence
    if (task.repeatEveryDays != null && task.repeatEveryDays! > 0) {
      final nextDue = now.add(Duration(days: task.repeatEveryDays!));
      await _client.from('care_tasks').insert({
        'plant_id': task.plantId,
        'created_by': user?.id,
        'title': task.title,
        'description': task.description,
        'task_type': task.taskType,
        'due_at': nextDue.toIso8601String(),
        'repeat_every_days': task.repeatEveryDays,
        'status': 'pending',
      });
    }

    return CareTask.fromJson(updatedRow);
  }

  /// Delete a care task
  Future<void> deleteCareTask(String taskId) async {
    await _client.from('care_tasks').delete().eq('id', taskId);
  }

  /// Initialize default recommended care schedule for a plant
  Future<List<CareTask>> initializeDefaultSchedule({
    required String plantId,
    String? speciesName,
    bool isArabic = true,
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    final defaultTasks = [
      {
        'plant_id': plantId,
        'created_by': user?.id,
        'title': isArabic ? 'ري النبتة المنتظم' : 'Regular Plant Watering',
        'description': isArabic
            ? 'ري خفيف ومناسب لرطوبة التربة'
            : 'Moderate watering suitable for soil moisture',
        'task_type': 'watering',
        'due_at': now.add(const Duration(days: 2)).toIso8601String(),
        'repeat_every_days': 3,
        'status': 'pending',
      },
      {
        'plant_id': plantId,
        'created_by': user?.id,
        'title': isArabic ? 'مراقبة وفحص الأوراق' : 'Foliage Inspection',
        'description': isArabic
            ? 'التقاط صورة وفحص علامات الإجهاد والنمو'
            : 'Capture leaf photo and inspect growth signs',
        'task_type': 'monitoring',
        'due_at': now.add(const Duration(days: 5)).toIso8601String(),
        'repeat_every_days': 7,
        'status': 'pending',
      },
      {
        'plant_id': plantId,
        'created_by': user?.id,
        'title': isArabic ? 'تسميد وتغذية دورية' : 'Periodic Fertilizing',
        'description': isArabic
            ? 'تغذية متوازنة حسب إرشادات النوع'
            : 'Balanced nutrition per species guidelines',
        'task_type': 'fertilizing',
        'due_at': now.add(const Duration(days: 14)).toIso8601String(),
        'repeat_every_days': 14,
        'status': 'pending',
      },
    ];

    final inserted = await _client
        .from('care_tasks')
        .insert(defaultTasks)
        .select();

    return inserted.map((r) => CareTask.fromJson(r)).toList();
  }
}
