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
    String? parentTaskId,
  }) async {
    final user = _client.auth.currentUser;
    final normalizedType = ['watering', 'fertilizing', 'pruning', 'inspection', 'other']
            .contains(taskType)
        ? taskType
        : 'other';

    final payload = <String, dynamic>{
      'plant_id': plantId,
      'created_by': user?.id,
      'title': title,
      'description': description,
      'task_type': normalizedType,
      'due_at': (dueAt ?? DateTime.now()).toIso8601String(),
      'repeat_every_days': repeatEveryDays,
      'status': 'pending',
    };
    if (parentTaskId != null && parentTaskId.isNotEmpty) {
      payload['parent_task_id'] = parentTaskId;
    }

    final row = await _client
        .from('care_tasks')
        .insert(payload)
        .select()
        .single();

    return CareTask.fromJson(row);
  }

  /// Update an existing care task
  Future<CareTask> updateCareTask({
    required String taskId,
    required String title,
    String? description,
    String taskType = 'other',
    DateTime? dueAt,
    int? repeatEveryDays,
  }) async {
    final now = DateTime.now();
    final normalizedType = ['watering', 'fertilizing', 'pruning', 'inspection', 'other']
            .contains(taskType)
        ? taskType
        : 'other';

    final row = await _client
        .from('care_tasks')
        .update({
          'title': title,
          'description': description,
          'task_type': normalizedType,
          'due_at': (dueAt ?? now).toIso8601String(),
          'repeat_every_days': repeatEveryDays,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', taskId)
        .select()
        .single();

    return CareTask.fromJson(row);
  }

  /// Mark a care task as completed and automatically schedule recurring task if applicable
  Future<CareTask> completeCareTask(CareTask task) async {
    if (task.isCompleted) {
      return task;
    }

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

    // If recurring, schedule next occurrence idempotently
    if (task.repeatEveryDays != null && task.repeatEveryDays! > 0) {
      final nextDue = now.add(Duration(days: task.repeatEveryDays!));
      final normalizedType = ['watering', 'fertilizing', 'pruning', 'inspection', 'other']
              .contains(task.taskType)
          ? task.taskType
          : 'other';

      // Identify the original/root task ID to maintain lineage across recurring cycles
      final originId = (task.parentTaskId != null && task.parentTaskId!.isNotEmpty)
          ? task.parentTaskId!
          : task.id;

      // Verify no pending occurrence linked to this original task already exists.
      // Checks both parent_task_id matching the origin task ID or the completing task ID.
      // This strictly decouples from title-matching so multiple tasks with identical titles
      // maintain independent schedules, and repeated complete calls produce exactly one task.
      final existingFuture = await _client
          .from('care_tasks')
          .select('id')
          .eq('plant_id', task.plantId)
          .eq('status', 'pending')
          .or('parent_task_id.eq.$originId,parent_task_id.eq.${task.id}')
          .limit(1)
          .maybeSingle();

      if (existingFuture == null) {
        await _client.from('care_tasks').insert({
          'plant_id': task.plantId,
          'created_by': user?.id,
          'title': task.title,
          'description': task.description,
          'task_type': normalizedType,
          'due_at': nextDue.toIso8601String(),
          'repeat_every_days': task.repeatEveryDays,
          'status': 'pending',
          'parent_task_id': originId,
        });
      }
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
    String? careInstructions,
    bool isArabic = true,
  }) async {
    return initializeScheduleFromSpecies(
      plantId: plantId,
      speciesName: speciesName,
      careInstructions: careInstructions,
      isArabic: isArabic,
    );
  }

  /// Initialize recommended care schedule for a plant from species template
  Future<List<CareTask>> initializeScheduleFromSpecies({
    required String plantId,
    String? speciesName,
    String? careInstructions,
    bool isArabic = true,
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    final tasks = [
      {
        'plant_id': plantId,
        'created_by': user?.id,
        'title': isArabic ? 'ري النبتة الدوري' : 'Periodic Plant Watering',
        'description': careInstructions != null && careInstructions.isNotEmpty
            ? careInstructions
            : (isArabic ? 'ري خفيف ومناسب لرطوبة التربة' : 'Moderate watering suitable for soil moisture'),
        'task_type': 'watering',
        'due_at': now.add(const Duration(days: 2)).toIso8601String(),
        'repeat_every_days': 3,
        'status': 'pending',
      },
      {
        'plant_id': plantId,
        'created_by': user?.id,
        'title': isArabic ? 'فحص الأوراق ومراقبة النمو' : 'Foliage & Growth Inspection',
        'description': isArabic
            ? 'التقاط صورة وفحص علامات الإجهاد والنمو'
            : 'Capture leaf photo and inspect growth signs',
        'task_type': 'inspection',
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
      {
        'plant_id': plantId,
        'created_by': user?.id,
        'title': isArabic ? 'تقليم وتشذيب الأوراق' : 'Pruning & Maintenance',
        'description': isArabic
            ? 'إزالة الأوراق القديمة أو الجافة لتشجيع النمو'
            : 'Remove old or dry leaves to promote growth',
        'task_type': 'pruning',
        'due_at': now.add(const Duration(days: 30)).toIso8601String(),
        'repeat_every_days': 30,
        'status': 'pending',
      },
    ];

    final inserted = await _client
        .from('care_tasks')
        .insert(tasks)
        .select();

    return inserted.map((r) => CareTask.fromJson(r)).toList();
  }
}
