import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/models/care_task.dart';
import 'package:plantsense/models/notification_item.dart';
import 'package:plantsense/models/species.dart';

void main() {
  group('M5 — CareTask Model Tests', () {
    test('CareTask parses from JSON and serializes back correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'task-123',
        'plant_id': 'plant-456',
        'created_by': 'user-789',
        'title': 'ري خفيف للتربة',
        'description': 'التحقق من جفاف أول 2 سم ثم الري باعتدال',
        'task_type': 'watering',
        'due_at': now.add(const Duration(days: 2)).toIso8601String(),
        'repeat_every_days': 3,
        'status': 'pending',
        'completed_at': null,
        'completed_by': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final task = CareTask.fromJson(json);

      expect(task.id, 'task-123');
      expect(task.plantId, 'plant-456');
      expect(task.title, 'ري خفيف للتربة');
      expect(task.taskType, 'watering');
      expect(task.repeatEveryDays, 3);
      expect(task.isPending, isTrue);
      expect(task.isCompleted, isFalse);
      expect(task.isOverdue, isFalse);
      expect(task.localizedTaskType(true), 'ري');
      expect(task.localizedTaskType(false), 'Watering');

      final serialized = task.toJson();
      expect(serialized['id'], 'task-123');
      expect(serialized['plant_id'], 'plant-456');
      expect(serialized['task_type'], 'watering');
    });

    test('CareTask identifies overdue status accurately', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final task = CareTask(
        id: 'task-overdue',
        plantId: 'plant-1',
        createdBy: 'user-1',
        title: 'فحص الحشرات',
        taskType: 'inspection',
        dueAt: pastDate,
        status: 'pending',
        createdAt: pastDate,
        updatedAt: pastDate,
      );

      expect(task.isOverdue, isTrue);
      expect(task.localizedTaskType(true), 'مراقبة وفحص');
      expect(task.localizedTaskType(false), 'Inspection');
    });

    test('CareTask identifies completed status and copyWith', () {
      final now = DateTime.now();
      final task = CareTask(
        id: 'task-1',
        plantId: 'plant-1',
        createdBy: 'user-1',
        title: 'تسميد',
        taskType: 'fertilizing',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      final completed = task.copyWith(
        status: 'completed',
        completedAt: now,
        completedBy: 'user-1',
      );

      expect(completed.isCompleted, isTrue);
      expect(completed.isPending, isFalse);
      expect(completed.completedBy, 'user-1');
      expect(completed.localizedTaskType(true), 'تسميد');
    });

    test('CareTask handles custom task type stored in description properly', () {
      final now = DateTime.now();
      final customTask = CareTask(
        id: 'task-custom',
        plantId: 'plant-1',
        createdBy: 'user-1',
        title: 'رش وقائي',
        description: '[نوع: مكافحة آفات عضوية] رش المحلول مساءً كل أسبوعين',
        taskType: 'other',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      expect(customTask.customTaskTypeName, 'مكافحة آفات عضوية');
      expect(customTask.cleanDescription, 'رش المحلول مساءً كل أسبوعين');
      expect(customTask.displayTaskType(true), 'مكافحة آفات عضوية');
      expect(customTask.displayTaskType(false), 'مكافحة آفات عضوية');
    });

    test('CareTask handles today due date properly without false overdue trigger', () {
      final now = DateTime.now();
      // End of today
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final todayTask = CareTask(
        id: 'task-today',
        plantId: 'plant-1',
        createdBy: 'user-1',
        title: 'مهمة مستحقة اليوم',
        dueAt: endOfToday,
        taskType: 'watering',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      // Should NOT be overdue on the same day
      expect(todayTask.isOverdue, isFalse);
    });

    test('CareTask handles parent_task_id and [origin: ...] metadata correctly', () {
      final now = DateTime.now();
      final jsonWithParent = {
        'id': 'task-child-1',
        'plant_id': 'plant-1',
        'created_by': 'user-1',
        'title': 'ري دوري',
        'description': '[نوع: ري أوتوماتيكي] تفقد الرطوبة أولاً',
        'task_type': 'other',
        'due_at': now.toIso8601String(),
        'repeat_every_days': 3,
        'status': 'pending',
        'parent_task_id': 'task-parent-root-123',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final taskWithParent = CareTask.fromJson(jsonWithParent);
      expect(taskWithParent.parentTaskId, 'task-parent-root-123');
      expect(taskWithParent.customTaskTypeName, 'ري أوتوماتيكي');
      expect(taskWithParent.cleanDescription, 'تفقد الرطوبة أولاً');

      final serialized = taskWithParent.toJson();
      expect(serialized['parent_task_id'], 'task-parent-root-123');

      // Test fallback origin extraction from description when parent_task_id is omitted
      final jsonWithOriginInDesc = {
        'id': 'task-child-2',
        'plant_id': 'plant-1',
        'created_by': 'user-1',
        'title': 'ري يدوي',
        'description': '[نوع: ري يدوي][origin: task-root-legacy-456] سقي نصف لتر',
        'task_type': 'other',
        'status': 'pending',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final taskWithDescOrigin = CareTask.fromJson(jsonWithOriginInDesc);
      expect(taskWithDescOrigin.parentTaskId, 'task-root-legacy-456');
      expect(taskWithDescOrigin.customTaskTypeName, 'ري يدوي');
      expect(taskWithDescOrigin.cleanDescription, 'سقي نصف لتر');

      // Test copyWith parentTaskId
      final updatedParent = taskWithDescOrigin.copyWith(parentTaskId: 'new-parent-789');
      expect(updatedParent.parentTaskId, 'new-parent-789');
    });
  });

  group('M5 — NotificationItem Model Tests', () {
    test('NotificationItem parses and serializes correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'notif-1',
        'user_id': 'user-123',
        'plant_id': 'plant-456',
        'diagnosis_id': 'diag-789',
        'care_task_id': null,
        'type': 'diagnosis',
        'title': 'تنبيه صحة النبات',
        'body': 'أظهر فحص الأوراق اصفراراً بحاجة لاهتمام',
        'is_read': false,
        'created_at': now.toIso8601String(),
      };

      final notif = NotificationItem.fromJson(json);

      expect(notif.id, 'notif-1');
      expect(notif.userId, 'user-123');
      expect(notif.isDiagnosisAlert, isTrue);
      expect(notif.isCareDueAlert, isFalse);
      expect(notif.isRead, isFalse);
      expect(notif.diagnosisId, 'diag-789');

      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, isTrue);
    });
  });

  group('M5 — Recurring Care Task Next Due & Idempotency Tests', () {
    late _InMemoryCareTaskEngine engine;

    setUp(() {
      engine = _InMemoryCareTaskEngine();
    });

    test('Completing a recurring task creates a single next pending task linked to original task id', () async {
      final now = DateTime.now();
      final rootTask = CareTask(
        id: 'task-watering-root',
        plantId: 'plant-1',
        createdBy: 'user-1',
        title: 'ري أسبوعي',
        taskType: 'watering',
        dueAt: now,
        repeatEveryDays: 7,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      engine.tasks.add(rootTask);

      final completed = await engine.completeCareTask(rootTask);
      expect(completed.isCompleted, isTrue);

      final pendingTasks = engine.tasks.where((t) => t.status == 'pending').toList();
      expect(pendingTasks.length, 1);
      final nextTask = pendingTasks.first;

      expect(nextTask.title, 'ري أسبوعي');
      expect(nextTask.parentTaskId, 'task-watering-root');
      expect(nextTask.repeatEveryDays, 7);
      expect(nextTask.dueAt!.isAfter(now), isTrue);
    });

    test('Duplicate completion requests on the same recurring task produce exactly one new due task (idempotency)', () async {
      final now = DateTime.now();
      final rootTask = CareTask(
        id: 'task-fertilizing-root',
        plantId: 'plant-1',
        createdBy: 'user-1',
        title: 'تسميد عضوي',
        taskType: 'fertilizing',
        dueAt: now,
        repeatEveryDays: 14,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      engine.tasks.add(rootTask);

      // First completion call
      await engine.completeCareTask(rootTask);
      expect(engine.tasks.where((t) => t.status == 'pending').length, 1);

      // Second duplicate completion call (e.g. rapid double tap or network retry)
      await engine.completeCareTask(rootTask);
      expect(engine.tasks.where((t) => t.status == 'pending').length, 1);

      // Third duplicate completion call
      await engine.completeCareTask(rootTask);
      expect(engine.tasks.where((t) => t.status == 'pending').length, 1);
    });

    test('Two distinct tasks sharing the identical title on the same plant maintain independent recurring schedules', () async {
      final now = DateTime.now();
      // Two different tasks on the same plant with the IDENTICAL title 'ري'
      final taskA = CareTask(
        id: 'task-a-morning',
        plantId: 'plant-shared',
        createdBy: 'user-1',
        title: 'ري',
        description: 'ري صباحي خفيف',
        taskType: 'watering',
        dueAt: now,
        repeatEveryDays: 3,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      final taskB = CareTask(
        id: 'task-b-evening',
        plantId: 'plant-shared',
        createdBy: 'user-1',
        title: 'ري',
        description: 'ري مسائي عميق',
        taskType: 'watering',
        dueAt: now,
        repeatEveryDays: 7,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      engine.tasks.addAll([taskA, taskB]);

      // Complete Task A
      await engine.completeCareTask(taskA);
      // Completing Task A must NOT prevent Task B from scheduling, nor should Task A be blocked
      final pendingAfterA = engine.tasks.where((t) => t.status == 'pending').toList();
      // Contains taskB (not yet completed) + nextTaskA
      expect(pendingAfterA.length, 2);
      final nextA = pendingAfterA.firstWhere((t) => t.parentTaskId == 'task-a-morning');
      expect(nextA.title, 'ري');
      expect(nextA.repeatEveryDays, 3);

      // Complete Task B
      await engine.completeCareTask(taskB);
      // Both tasks have now completed, each should have generated its own independent next due task!
      final pendingAfterBoth = engine.tasks.where((t) => t.status == 'pending').toList();
      expect(pendingAfterBoth.length, 2);

      final nextB = pendingAfterBoth.firstWhere((t) => t.parentTaskId == 'task-b-evening');
      expect(nextB.title, 'ري');
      expect(nextB.repeatEveryDays, 7);

      // Verify each task maintains its independent lineage and interval
      expect(nextA.parentTaskId, 'task-a-morning');
      expect(nextB.parentTaskId, 'task-b-evening');
      expect(nextA.id != nextB.id, isTrue);
    });

    test('Multi-cycle recurrence preserves the original root task ID across successive generations', () async {
      final now = DateTime.now();
      // Root task
      final rootTask = CareTask(
        id: 'task-gen-0',
        plantId: 'plant-1',
        createdBy: 'user-1',
        title: 'تقليم دوري',
        taskType: 'pruning',
        dueAt: now,
        repeatEveryDays: 30,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      engine.tasks.add(rootTask);

      // Cycle 1: complete root
      await engine.completeCareTask(rootTask);
      final gen1 = engine.tasks.firstWhere((t) => t.status == 'pending');
      expect(gen1.parentTaskId, 'task-gen-0');

      // Cycle 2: complete gen1
      await engine.completeCareTask(gen1);
      final gen2 = engine.tasks.firstWhere((t) => t.status == 'pending');
      expect(gen2.parentTaskId, 'task-gen-0');

      // Attempt duplicate complete on gen1
      await engine.completeCareTask(gen1);
      final pendingCount = engine.tasks.where((t) => t.status == 'pending').length;
      expect(pendingCount, 1);
    });

    test('One-time care task (repeatEveryDays = null or 0) completes into history and creates NO next task', () async {
      final now = DateTime.now();
      final oneTimeTask = CareTask(
        id: 'task-onetime-1',
        plantId: 'plant-1',
        createdBy: 'user-1',
        title: 'تنظيف الحوض لمرة واحدة',
        taskType: 'other',
        dueAt: now,
        repeatEveryDays: null,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      engine.tasks.add(oneTimeTask);

      final completed = await engine.completeCareTask(oneTimeTask);
      expect(completed.isCompleted, isTrue);

      // Must NOT schedule any next task in pending
      final pendingTasks = engine.tasks.where((t) => t.status == 'pending').toList();
      expect(pendingTasks.isEmpty, isTrue);

      // Completed task exists in history
      final completedTasks = engine.tasks.where((t) => t.status == 'completed').toList();
      expect(completedTasks.length, 1);
      expect(completedTasks.first.id, 'task-onetime-1');
    });
  });

  group('M5 — Species Localization & Encyclopedia Content Tests', () {
    test('Species returns proper Arabic names, descriptions, and care guidelines', () {
      final now = DateTime.now();
      final tomato = Species(
        id: 'sp-tomato',
        commonName: 'Tomato',
        scientificName: 'Solanum lycopersicum',
        description: 'Popular crop',
        careInstructions: 'Water regularly',
        createdAt: now,
        updatedAt: now,
      );

      expect(tomato.localizedName(true), 'طماطم (Tomato)');
      expect(tomato.localizedName(false), 'Tomato');
      expect(tomato.localizedDescription(true)!.contains('محصول خضري ثمري'), isTrue);
      expect(tomato.localizedCareInstructions(true)!.contains('الري المنتظم'), isTrue);

      final basil = Species(
        id: 'sp-basil',
        commonName: 'Sweet Basil',
        scientificName: 'Ocimum basilicum',
        createdAt: now,
        updatedAt: now,
      );
      expect(basil.localizedName(true), 'ريحان (Sweet Basil)');
      expect(basil.localizedName(false), 'Sweet Basil');
      expect(basil.localizedDescription(true)!.contains('عشبي عطري'), isTrue);
    });
  });
}

/// In-memory engine implementing the exact CareTaskService next-due & idempotency algorithm
class _InMemoryCareTaskEngine {
  final List<CareTask> tasks = [];

  Future<CareTask> completeCareTask(CareTask task) async {
    if (task.isCompleted) return task;

    final now = DateTime.now();
    final idx = tasks.indexWhere((t) => t.id == task.id);
    final completed = task.copyWith(
      status: 'completed',
      completedAt: now,
      updatedAt: now,
    );
    if (idx != -1) {
      tasks[idx] = completed;
    } else {
      tasks.add(completed);
    }

    if (task.repeatEveryDays != null && task.repeatEveryDays! > 0) {
      final nextDue = now.add(Duration(days: task.repeatEveryDays!));
      final originId = (task.parentTaskId != null && task.parentTaskId!.isNotEmpty)
          ? task.parentTaskId!
          : task.id;

      // Verify no pending occurrence linked to this origin task already exists
      final existingPending = tasks.any((t) =>
          t.plantId == task.plantId &&
          t.status == 'pending' &&
          (t.parentTaskId == originId || t.parentTaskId == task.id));

      if (!existingPending) {
        final nextTask = CareTask(
          id: 'task-gen-${tasks.length + 1}',
          plantId: task.plantId,
          createdBy: task.createdBy,
          title: task.title,
          description: task.description,
          taskType: task.taskType,
          dueAt: nextDue,
          repeatEveryDays: task.repeatEveryDays,
          status: 'pending',
          parentTaskId: originId,
          createdAt: now,
          updatedAt: now,
        );
        tasks.add(nextTask);
      }
    }

    return completed;
  }
}
