import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/models/care_task.dart';
import 'package:plantsense/models/notification_item.dart';

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
        taskType: 'pest_control',
        dueAt: pastDate,
        status: 'pending',
        createdAt: pastDate,
        updatedAt: pastDate,
      );

      expect(task.isOverdue, isTrue);
      expect(task.localizedTaskType(true), 'مكافحة الآفات');
      expect(task.localizedTaskType(false), 'Pest Control');
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
        'type': 'diagnosis_alert',
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
}
