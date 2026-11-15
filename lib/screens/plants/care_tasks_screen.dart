import 'package:flutter/material.dart';
import '../../models/care_task.dart';
import '../../models/plant.dart';
import '../../services/care_task_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class CareTasksScreen extends StatefulWidget {
  final Plant plant;
  final CareTaskService? careTaskService;
  final NotificationService? notificationService;
  final bool isViewer;

  const CareTasksScreen({
    super.key,
    required this.plant,
    this.careTaskService,
    this.notificationService,
    this.isViewer = false,
  });

  @override
  State<CareTasksScreen> createState() => _CareTasksScreenState();
}

class _CareTasksScreenState extends State<CareTasksScreen>
    with SingleTickerProviderStateMixin {
  late final CareTaskService _service;
  late final NotificationService _notificationService;
  late final TabController _tabController;

  List<CareTask> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _completingTaskIds = {};

  @override
  void initState() {
    super.initState();
    _service = widget.careTaskService ?? CareTaskService();
    _notificationService = widget.notificationService ?? NotificationService();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getCareTasksForPlant(widget.plant.id);
      if (mounted) {
        setState(() {
          _tasks = list;
          _isLoading = false;
        });
      }

      // Automatically generate care alerts for overdue tasks if device reminders enabled
      for (final t in list.where((t) => t.isOverdue)) {
        try {
          await _notificationService.createCareTaskAlert(
            plantId: widget.plant.id,
            plantName: widget.plant.name,
            careTaskId: t.id,
            taskTitle: t.title,
            isOverdue: true,
            isArabic: mounted ? context.l10n.isArabic : true,
          );
        } catch (_) {}
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

  Future<void> _completeTask(CareTask task) async {
    if (widget.isViewer || _completingTaskIds.contains(task.id)) return;

    setState(() => _completingTaskIds.add(task.id));
    final isArabic = context.l10n.isArabic;

    try {
      await _service.completeCareTask(task);
      await _loadTasks();
      if (mounted) {
        // Switch tab to completed tasks history
        _tabController.animateTo(1);

        final String successMessage;
        if (task.repeatEveryDays != null && task.repeatEveryDays! > 0) {
          final nextDue = DateTime.now().add(Duration(days: task.repeatEveryDays!));
          final dateStr =
              '${nextDue.year}-${nextDue.month.toString().padLeft(2, '0')}-${nextDue.day.toString().padLeft(2, '0')}';
          successMessage = isArabic
              ? 'تم إكمال المهمة بنجاح. الموعد القادم: $dateStr'
              : 'Task completed successfully. Next due date: $dateStr';
        } else {
          successMessage = context.l10n.taskCompletedSuccess;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(successMessage),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _completingTaskIds.remove(task.id));
      }
    }
  }

  Future<void> _initializeDefaultSchedule() async {
    if (widget.isViewer) return;
    setState(() => _isLoading = true);
    try {
      await _service.initializeDefaultSchedule(
        plantId: widget.plant.id,
        speciesName: widget.plant.species?.commonName,
        isArabic: context.l10n.isArabic,
      );
      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(context.l10n.isArabic
                ? 'تم إنشاء جدول العناية الموصى به بنجاح.'
                : 'Recommended care schedule created.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  void _showTaskDialog({CareTask? existingTask}) {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;
    final isEditing = existingTask != null;

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existingTask?.title ?? '');
    final customTypeCtrl =
        TextEditingController(text: existingTask?.customTaskTypeName ?? '');
    final descCtrl =
        TextEditingController(text: existingTask?.cleanDescription ?? '');

    bool isRecurring = existingTask != null
        ? (existingTask.repeatEveryDays != null && existingTask.repeatEveryDays! > 0)
        : true;
    final repeatCtrl = TextEditingController(
      text: existingTask != null
          ? (existingTask.repeatEveryDays?.toString() ?? '')
          : '3',
    );

    String selectedType = existingTask != null ? existingTask.taskType : 'watering';
    final now = DateTime.now();
    DateTime selectedDate = existingTask?.dueAt ?? now.add(const Duration(days: 1));
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing
              ? (isArabic ? 'تعديل مهمة عناية' : 'Edit Care Task')
              : l10n.addCareTask),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'عنوان المهمة *' : 'Task Title *',
                      hintText: isArabic
                          ? 'مثال: ري خفيف، تسميد NPK'
                          : 'e.g. Light watering',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return isArabic
                            ? 'يرجى إدخال عنوان المهمة'
                            : 'Please enter task title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(labelText: l10n.taskType),
                    items: [
                      DropdownMenuItem(
                          value: 'watering', child: Text(isArabic ? 'ري' : 'Watering')),
                      DropdownMenuItem(
                          value: 'fertilizing',
                          child: Text(isArabic ? 'تسميد' : 'Fertilizing')),
                      DropdownMenuItem(
                          value: 'pruning',
                          child: Text(isArabic ? 'تقليم' : 'Pruning')),
                      DropdownMenuItem(
                          value: 'inspection',
                          child: Text(isArabic ? 'مراقبة وفحص' : 'Inspection')),
                      DropdownMenuItem(
                          value: 'other', child: Text(isArabic ? 'أخرى' : 'Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                  if (selectedType == 'other') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: customTypeCtrl,
                      decoration: InputDecoration(
                        labelText:
                            isArabic ? 'اسم نوع المهمة المخصص *' : 'Custom Task Type *',
                        hintText: isArabic
                            ? 'مثال: رش مبيد، تدفئة شتوية'
                            : 'e.g. Pest spray, Winter heating',
                      ),
                      validator: (val) {
                        if (selectedType == 'other' && (val == null || val.trim().isEmpty)) {
                          return isArabic
                              ? 'يرجى كتابة اسم نوع المهمة المخصص'
                              : 'Please enter custom task type';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary),
                    title: Text(l10n.dueDate),
                    subtitle: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final todayStart = DateTime(now.year, now.month, now.day);
                      final initial = selectedDate.isBefore(todayStart)
                          ? todayStart
                          : selectedDate;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: todayStart, // Disable past days
                        lastDate: DateTime(now.year + 2, 12, 31),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(isArabic ? 'تكرار دوري للمهمة' : 'Recurring Schedule'),
                    subtitle: Text(
                      isArabic
                          ? (isRecurring
                              ? 'تتكرر تلقائياً بعد كل إنجاز'
                              : 'بدون تكرار (مهمة لمرة واحدة)')
                          : (isRecurring
                              ? 'Repeats automatically after completion'
                              : 'No repeat (one-time task)'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isRecurring,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setDialogState(() => isRecurring = val),
                  ),
                  if (isRecurring) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: repeatCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'التكرار كل (أيام) *'
                            : 'Repeat every (days) *',
                        hintText: '3, 7, 14...',
                        suffixText: isArabic ? 'يوم' : 'days',
                      ),
                      validator: (val) {
                        if (isRecurring) {
                          final n = int.tryParse(val?.trim() ?? '');
                          if (n == null || n <= 0) {
                            return isArabic
                                ? 'أدخل عدد أيام صحيح أكبر من 0'
                                : 'Enter valid days (> 0)';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText:
                          isArabic ? 'ملاحظات إضافية (اختياري)' : 'Additional Notes (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      // If selected today, set due time to 23:59:59 so it stays due today and not immediately overdue
                      final isToday = selectedDate.year == now.year &&
                          selectedDate.month == now.month &&
                          selectedDate.day == now.day;
                      final effectiveDueAt = isToday
                          ? DateTime(
                              selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59)
                          : DateTime(
                              selectedDate.year, selectedDate.month, selectedDate.day, 12, 0, 0);

                      final notes = descCtrl.text.trim();
                      final String? finalDescription;
                      if (selectedType == 'other') {
                        final customName = customTypeCtrl.text.trim();
                        finalDescription =
                            notes.isEmpty ? '[نوع: $customName]' : '[نوع: $customName] $notes';
                      } else {
                        finalDescription = notes.isEmpty ? null : notes;
                      }

                      final repeatDays =
                          isRecurring ? int.tryParse(repeatCtrl.text.trim()) : null;

                      try {
                        if (isEditing) {
                          await _service.updateCareTask(
                            taskId: existingTask.id,
                            title: titleCtrl.text.trim(),
                            description: finalDescription,
                            taskType: selectedType,
                            dueAt: effectiveDueAt,
                            repeatEveryDays: repeatDays,
                          );
                        } else {
                          await _service.createCareTask(
                            plantId: widget.plant.id,
                            title: titleCtrl.text.trim(),
                            description: finalDescription,
                            taskType: selectedType,
                            dueAt: effectiveDueAt,
                            repeatEveryDays: repeatDays,
                          );
                        }
                        if (mounted) {
                          Navigator.of(ctx).pop();
                        }
                        await _loadTasks();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primary,
                              content: Text(isEditing
                                  ? (isArabic
                                      ? 'تم تحديث المهمة بنجاح.'
                                      : 'Task updated successfully.')
                                  : (isArabic
                                      ? 'تمت إضافة المهمة بنجاح.'
                                      : 'Task added successfully.')),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.error,
                              content:
                                  Text(e.toString().replaceFirst('Exception: ', '')),
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;

    final pendingTasks = _tasks.where((t) => t.isPending).toList();
    final completedTasks = _tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text('${l10n.careScheduleTitle}: ${widget.plant.name}'),
        actions: const [
          LanguageToggleButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.dark.withOpacity(0.6),
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.upcomingTasks),
                  if (pendingTasks.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: pendingTasks.any((t) => t.isOverdue)
                            ? AppColors.error
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pendingTasks.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: '${l10n.completedTasks} (${completedTasks.length})'),
          ],
        ),
      ),
      floatingActionButton: widget.isViewer
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showTaskDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: Text(l10n.addCareTask, style: const TextStyle(color: Colors.white)),
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
                        onPressed: _loadTasks,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Pending & Overdue Tasks
                    pendingTasks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircleAvatar(
                                    radius: 36,
                                    backgroundColor: AppColors.lightGreen,
                                    child: Icon(Icons.check_circle_outline_rounded,
                                        size: 40, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isArabic
                                        ? 'رائع! لا توجد مهام عناية معلقة حالياً.'
                                        : 'All care tasks are up to date!',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (!widget.isViewer) ...[
                                    ElevatedButton.icon(
                                      onPressed: _initializeDefaultSchedule,
                                      icon: const Icon(Icons.auto_awesome, size: 18),
                                      label: Text(l10n.initRecommendedSchedule),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: pendingTasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final task = pendingTasks[idx];
                              final isOverdue = task.isOverdue;

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isOverdue
                                        ? AppColors.error.withOpacity(0.5)
                                        : AppColors.lightGreen.withAlpha(140),
                                    width: isOverdue ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: isOverdue
                                            ? const Color(0xFFFFEBEE)
                                            : AppColors.lightGreen,
                                        child: Icon(
                                          _getIconForTaskType(task.taskType),
                                          color: isOverdue ? AppColors.error : AppColors.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    task.title,
                                                    style: const TextStyle(
                                                      fontFamily: AppTheme.fontFamily,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.dark,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isOverdue
                                                        ? const Color(0xFFFFEBEE)
                                                        : AppColors.lightGreen,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isOverdue
                                                        ? (isArabic ? 'متأخرة' : 'Overdue')
                                                        : task.displayTaskType(isArabic),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isOverdue
                                                          ? AppColors.error
                                                          : AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (task.cleanDescription.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                task.cleanDescription,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.dark.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.event_outlined,
                                                  size: 14,
                                                  color: isOverdue ? AppColors.error : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  task.dueAt != null
                                                      ? '${task.dueAt!.year}-${task.dueAt!.month.toString().padLeft(2, '0')}-${task.dueAt!.day.toString().padLeft(2, '0')}'
                                                      : '-',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                                    color: isOverdue ? AppColors.error : Colors.grey.shade700,
                                                  ),
                                                ),
                                                if (task.repeatEveryDays != null) ...[
                                                  const SizedBox(width: 12),
                                                  const Icon(Icons.repeat, size: 14, color: AppColors.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${isArabic ? "كل" : "every"} ${task.repeatEveryDays} ${l10n.days}',
                                                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!widget.isViewer) ...[
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
                                              tooltip: isArabic ? 'تعديل المهمة' : 'Edit Task',
                                              onPressed: () => _showTaskDialog(existingTask: task),
                                            ),
                                            if (_completingTaskIds.contains(task.id))
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                                ),
                                              )
                                            else
                                              IconButton(
                                                icon: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 28),
                                                tooltip: l10n.markAsCompleted,
                                                onPressed: () => _completeTask(task),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    // Tab 2: Completed Tasks History
                    completedTasks.isEmpty
                        ? Center(
                            child: Text(
                              isArabic ? 'لم يتم إكمال أي مهمة بعد.' : 'No completed tasks yet.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: completedTasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final task = completedTasks[idx];
                              return Card(
                                color: Colors.white,
                                elevation: 0.3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Color(0xFFE8F5E9),
                                    child: Icon(Icons.check, color: AppColors.primary, size: 18),
                                  ),
                                  title: Text(
                                    task.title,
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  subtitle: Text(
                                    task.completedAt != null
                                        ? '${isArabic ? "تم الإنجاز: " : "Done: "}${task.completedAt!.year}-${task.completedAt!.month.toString().padLeft(2, '0')}-${task.completedAt!.day.toString().padLeft(2, '0')}'
                                        : '-',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
    );
  }

  IconData _getIconForTaskType(String type) {
    switch (type) {
      case 'watering':
        return Icons.water_drop_rounded;
      case 'fertilizing':
        return Icons.grain_rounded;
      case 'pruning':
        return Icons.content_cut_rounded;
      case 'inspection':
        return Icons.visibility_rounded;
      case 'other':
      default:
        return Icons.task_alt_rounded;
    }
  }
}
