import 'package:flutter/material.dart';
import '../../models/care_task.dart';
import '../../models/plant.dart';
import '../../services/care_task_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class CareTasksScreen extends StatefulWidget {
  final Plant plant;
  final CareTaskService? careTaskService;
  final bool isViewer;

  const CareTasksScreen({
    super.key,
    required this.plant,
    this.careTaskService,
    this.isViewer = false,
  });

  @override
  State<CareTasksScreen> createState() => _CareTasksScreenState();
}

class _CareTasksScreenState extends State<CareTasksScreen>
    with SingleTickerProviderStateMixin {
  late final CareTaskService _service;
  late final TabController _tabController;

  List<CareTask> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.careTaskService ?? CareTaskService();
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
    if (widget.isViewer) return;
    try {
      await _service.completeCareTask(task);
      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(context.l10n.taskCompletedSuccess),
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

  void _showAddTaskDialog() {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final repeatCtrl = TextEditingController(text: '3');
    String selectedType = 'watering';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.addCareTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.taskTitle,
                    hintText: isArabic ? 'مثال: ري خفيف، تسميد NPK' : 'e.g. Light watering',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: l10n.taskType),
                  items: [
                    DropdownMenuItem(value: 'watering', child: Text(isArabic ? 'ري' : 'Watering')),
                    DropdownMenuItem(value: 'fertilizing', child: Text(isArabic ? 'تسميد' : 'Fertilizing')),
                    DropdownMenuItem(value: 'pruning', child: Text(isArabic ? 'تقليم' : 'Pruning')),
                    DropdownMenuItem(value: 'pest_control', child: Text(isArabic ? 'مكافحة الآفات' : 'Pest Control')),
                    DropdownMenuItem(value: 'monitoring', child: Text(isArabic ? 'مراقبة وفحص' : 'Monitoring')),
                    DropdownMenuItem(value: 'other', child: Text(isArabic ? 'أخرى' : 'Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  title: Text(l10n.dueDate),
                  subtitle: Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: repeatCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.repeatEveryDays,
                    hintText: '3, 7, 14...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'ملاحظات إضافية' : 'Notes',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                Navigator.of(ctx).pop();

                final repeatDays = int.tryParse(repeatCtrl.text.trim());
                try {
                  await _service.createCareTask(
                    plantId: widget.plant.id,
                    title: title,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    taskType: selectedType,
                    dueAt: selectedDate,
                    repeatEveryDays: repeatDays,
                  );
                  await _loadTasks();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.save),
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
              onPressed: _showAddTaskDialog,
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
                                                        : task.localizedTaskType(isArabic),
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
                                            if (task.description != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                task.description!,
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
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 28),
                                          tooltip: l10n.markAsCompleted,
                                          onPressed: () => _completeTask(task),
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
      case 'pest_control':
        return Icons.bug_report_rounded;
      case 'monitoring':
        return Icons.visibility_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }
}
