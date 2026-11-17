import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';

class NotificationService {
  final SupabaseClient? _clientInstance;

  NotificationService({SupabaseClient? client}) : _clientInstance = client;

  SupabaseClient get _client => _clientInstance ?? Supabase.instance.client;

  static const String _prefCareRemindersKey = 'svpg_pref_care_reminders';
  static const String _prefDiagnosisAlertsKey = 'svpg_pref_diagnosis_alerts';

  /// Get in-app notifications for current user
  Future<List<NotificationItem>> getNotifications({bool unreadOnly = false}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('notifications')
        .select()
        .eq('user_id', user.id);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map((r) => NotificationItem.fromJson(r)).toList();
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    return rows.length;
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  /// Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id);
  }

  /// Create an AI Diagnosis Alert notification if diagnosis detected attention needed
  Future<NotificationItem?> createDiagnosisAlert({
    required String plantId,
    required String plantName,
    required String diagnosisId,
    required String severity,
    bool isArabic = true,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final enabled = await isDiagnosisAlertsEnabled();
    if (!enabled) return null;

    final String severityLabel;
    if (isArabic) {
      switch (severity.toLowerCase().trim()) {
        case 'none':
          severityLabel = 'منعدم';
          break;
        case 'low':
          severityLabel = 'منخفض';
          break;
        case 'medium':
          severityLabel = 'متوسط';
          break;
        case 'high':
          severityLabel = 'مرتفع';
          break;
        case 'critical':
        case 'severe':
          severityLabel = 'حرج';
          break;
        default:
          severityLabel = severity;
      }
    } else {
      severityLabel = severity;
    }

    final title = isArabic
        ? 'تنبيه صحة النبات: $plantName'
        : 'Plant Health Alert: $plantName';
    final body = isArabic
        ? 'أظهر فحص الأوراق علامات بحاجة لاهتمام (مستوى الشدة: $severityLabel). راجع التوصيات.'
        : 'Leaf analysis detected signs needing attention (Severity: $severityLabel). Check recommendations.';

    final row = await _client.from('notifications').insert({
      'user_id': user.id,
      'plant_id': plantId,
      'diagnosis_id': diagnosisId,
      'type': 'diagnosis',
      'title': title,
      'body': body,
      'is_read': false,
    }).select().single();

    return NotificationItem.fromJson(row);
  }

  /// Create a care task due/overdue alert notification
  Future<NotificationItem?> createCareTaskAlert({
    required String plantId,
    required String plantName,
    required String careTaskId,
    required String taskTitle,
    bool isOverdue = false,
    bool isArabic = true,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final enabled = await isCareRemindersEnabled();
    if (!enabled) return null;

    final title = isArabic
        ? (isOverdue ? 'مهمة متأخرة: $taskTitle' : 'تذكير موعد عناية: $taskTitle')
        : (isOverdue ? 'Overdue Task: $taskTitle' : 'Care Task Reminder: $taskTitle');
    final body = isArabic
        ? (isOverdue
            ? 'مهمة عناية متأخرة للنبتة "$plantName": حان موعد "$taskTitle" ولم تسجل كمكتملة بعد.'
            : 'حان موعد تنفيذ مهمة العناية "$taskTitle" للنبتة "$plantName".')
        : (isOverdue
            ? 'Care task "$taskTitle" for plant "$plantName" is overdue.'
            : 'Care task "$taskTitle" for plant "$plantName" is due.');

    final row = await _client.from('notifications').insert({
      'user_id': user.id,
      'plant_id': plantId,
      'care_task_id': careTaskId,
      'type': 'care',
      'title': title,
      'body': body,
      'is_read': false,
    }).select().single();

    return NotificationItem.fromJson(row);
  }

  // --- Local Preferences ---
  Future<bool> isCareRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefCareRemindersKey) ?? true;
  }

  Future<void> setCareRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefCareRemindersKey, enabled);
  }

  Future<bool> isDiagnosisAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefDiagnosisAlertsKey) ?? true;
  }

  Future<void> setDiagnosisAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDiagnosisAlertsKey, enabled);
  }
}
