/// Model representing a plant care task aligned with public.care_tasks table schema.
class CareTask {
  final String id;
  final String plantId;
  final String createdBy;
  final String title;
  final String? description;
  final String taskType; // watering, fertilizing, pruning, inspection, other
  final DateTime? dueAt;
  final int? repeatEveryDays;
  final String status; // pending, completed, cancelled
  final DateTime? completedAt;
  final String? completedBy;
  final String? parentTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CareTask({
    required this.id,
    required this.plantId,
    required this.createdBy,
    required this.title,
    this.description,
    this.taskType = 'other',
    this.dueAt,
    this.repeatEveryDays,
    this.status = 'pending',
    this.completedAt,
    this.completedBy,
    this.parentTaskId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isOverdue {
    if (status != 'pending' || dueAt == null) return false;
    return dueAt!.isBefore(DateTime.now());
  }

  String localizedTaskType(bool isArabic) {
    switch (taskType) {
      case 'watering':
        return isArabic ? 'ري' : 'Watering';
      case 'fertilizing':
        return isArabic ? 'تسميد' : 'Fertilizing';
      case 'pruning':
        return isArabic ? 'تقليم' : 'Pruning';
      case 'inspection':
        return isArabic ? 'مراقبة وفحص' : 'Inspection';
      case 'other':
      default:
        return isArabic ? 'عناية عامة' : 'General Care';
    }
  }

  /// Extracts custom task type name if stored in description as `[نوع: الاسم]` or `[type: Name]`
  String? get customTaskTypeName {
    if (taskType != 'other' || description == null) return null;
    final match = RegExp(r'^\[(?:نوع|type):\s*([^\]]+)\]\s*').firstMatch(description!);
    return match?.group(1)?.trim();
  }

  /// Returns user notes without technical tags like `[نوع: ...]` or `[origin: ...]`
  String get cleanDescription {
    if (description == null) return '';
    var text = description!;
    text = text.replaceFirst(RegExp(r'^\[(?:نوع|type):\s*[^\]]+\]\s*'), '');
    text = text.replaceAll(RegExp(r'\[(?:origin|اصل|أصل):\s*[^\]]+\]\s*'), '');
    return text.trim();
  }

  /// Display string for task type, respecting custom type name if specified
  String displayTaskType(bool isArabic) {
    if (taskType == 'other') {
      final custom = customTaskTypeName;
      if (custom != null && custom.isNotEmpty) return custom;
      return isArabic ? 'أخرى' : 'Other';
    }
    return localizedTaskType(isArabic);
  }

  factory CareTask.fromJson(Map<String, dynamic> json) {
    String? parentTaskId = json['parent_task_id'] as String?;
    if (parentTaskId == null && json['description'] != null) {
      final originMatch = RegExp(r'\[(?:origin|اصل|أصل):\s*([^\]]+)\]')
          .firstMatch(json['description'] as String);
      if (originMatch != null) {
        parentTaskId = originMatch.group(1)?.trim();
      }
    }

    return CareTask(
      id: json['id'] as String,
      plantId: json['plant_id'] as String,
      createdBy: (json['created_by'] ?? '') as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      taskType: (json['task_type'] ?? 'other') as String,
      dueAt: json['due_at'] != null ? DateTime.parse(json['due_at'] as String) : null,
      repeatEveryDays: json['repeat_every_days'] as int?,
      status: (json['status'] ?? 'pending') as String,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      completedBy: json['completed_by'] as String?,
      parentTaskId: parentTaskId,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'task_type': taskType,
      'due_at': dueAt?.toIso8601String(),
      'repeat_every_days': repeatEveryDays,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'completed_by': completedBy,
      'parent_task_id': parentTaskId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CareTask copyWith({
    String? id,
    String? plantId,
    String? createdBy,
    String? title,
    String? description,
    String? taskType,
    DateTime? dueAt,
    int? repeatEveryDays,
    String? status,
    DateTime? completedAt,
    String? completedBy,
    String? parentTaskId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CareTask(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      dueAt: dueAt ?? this.dueAt,
      repeatEveryDays: repeatEveryDays ?? this.repeatEveryDays,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
