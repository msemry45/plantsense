import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificationService? notificationService;

  const NotificationsScreen({super.key, this.notificationService});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _service;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _careRemindersEnabled = true;
  bool _diagnosisAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _service = widget.notificationService ?? NotificationService();
    _loadNotificationsAndPrefs();
  }

  Future<void> _loadNotificationsAndPrefs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getNotifications();
      final carePref = await _service.isCareRemindersEnabled();
      final diagPref = await _service.isDiagnosisAlertsEnabled();

      if (mounted) {
        setState(() {
          _notifications = list;
          _careRemindersEnabled = carePref;
          _diagnosisAlertsEnabled = diagPref;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;
    try {
      await _service.markAsRead(item.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == item.id);
          if (idx != -1) {
            _notifications[idx] = item.copyWith(isRead: true);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(context.l10n.isArabic
                ? 'تم تحديد جميع التنبيهات كمقروءة.'
                : 'All notifications marked as read.'),
          ),
        );
      }
    } catch (_) {}
  }

  void _showPreferencesSheet() {
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.notificationPreferences,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: Text(l10n.careRemindersPref),
                value: _careRemindersEnabled,
                onChanged: (val) async {
                  await _service.setCareRemindersEnabled(val);
                  setSheetState(() => _careRemindersEnabled = val);
                  setState(() => _careRemindersEnabled = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: Text(l10n.diagnosisAlertsPref),
                value: _diagnosisAlertsEnabled,
                onChanged: (val) async {
                  await _service.setDiagnosisAlertsEnabled(val);
                  setSheetState(() => _diagnosisAlertsEnabled = val);
                  setState(() => _diagnosisAlertsEnabled = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.done),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.notificationPreferences,
            onPressed: _showPreferencesSheet,
          ),
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: l10n.markAllRead,
            onPressed: _notifications.any((n) => !n.isRead) ? _markAllRead : null,
          ),
          const LanguageToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadNotificationsAndPrefs,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.lightGreen,
                            child: Icon(Icons.notifications_none_rounded, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noNotifications,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 15,
                              color: AppColors.dark.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final item = _notifications[idx];
                        Color iconBg = item.isDiagnosisAlert
                            ? const Color(0xFFFFF3E0)
                            : AppColors.lightGreen;
                        Color iconColor = item.isDiagnosisAlert
                            ? const Color(0xFFE65100)
                            : AppColors.primary;
                        IconData iconData = item.isDiagnosisAlert
                            ? Icons.warning_amber_rounded
                            : Icons.alarm_rounded;

                        return Card(
                          color: item.isRead ? Colors.white : const Color(0xFFF6FBF7),
                          elevation: item.isRead ? 0.3 : 1.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: item.isRead
                                  ? Colors.grey.shade200
                                  : AppColors.primary.withAlpha(100),
                              width: item.isRead ? 0.5 : 1.2,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _markRead(item),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: iconBg,
                                    child: Icon(iconData, color: iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontFamily: AppTheme.fontFamily,
                                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                                  fontSize: 14,
                                                  color: AppColors.dark,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead) ...[
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.dark.withOpacity(0.75),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')} • ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
