/// Model representing in-app and system alerts aligned with public.notifications table schema.
class NotificationItem {
  final String id;
  final String userId;
  final String? plantId;
  final String? diagnosisId;
  final String? careTaskId;
  final String type; // diagnosis_alert, care_due, general
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    this.plantId,
    this.diagnosisId,
    this.careTaskId,
    this.type = 'general',
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isDiagnosisAlert => type == 'diagnosis_alert';
  bool get isCareDueAlert => type == 'care_due';

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      plantId: json['plant_id'] as String?,
      diagnosisId: json['diagnosis_id'] as String?,
      careTaskId: json['care_task_id'] as String?,
      type: (json['type'] ?? 'general') as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plant_id': plantId,
      'diagnosis_id': diagnosisId,
      'care_task_id': careTaskId,
      'type': type,
      'title': title,
      'body': body,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? plantId,
    String? diagnosisId,
    String? careTaskId,
    String? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plantId: plantId ?? this.plantId,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      careTaskId: careTaskId ?? this.careTaskId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
