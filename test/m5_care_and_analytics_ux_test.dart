import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/models/care_task.dart';
import 'package:plantsense/models/plant.dart';
import 'package:plantsense/screens/analytics/analytics_screen.dart';
import 'package:plantsense/services/plant_service.dart';
import 'package:plantsense/screens/plants/care_tasks_screen.dart';
import 'package:plantsense/services/analytics_service.dart';
import 'package:plantsense/services/care_task_service.dart';
import 'package:plantsense/services/locale_service.dart';
import 'package:plantsense/l10n/app_localizations.dart';

class FakeCareTaskService extends CareTaskService {
  final List<CareTask> tasks;
  int completeCallCount = 0;
  int createCallCount = 0;
  int updateCallCount = 0;
  Map<String, dynamic>? lastCreatedPayload;
  Map<String, dynamic>? lastUpdatedPayload;

  FakeCareTaskService({required this.tasks});

  @override
  Future<List<CareTask>> getCareTasksForPlant(String plantId) async {
    return List.from(tasks);
  }

  @override
  Future<CareTask> completeCareTask(CareTask task) async {
    completeCallCount++;
    final idx = tasks.indexWhere((t) => t.id == task.id);
    CareTask completedTask = task.copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
    );
    if (idx != -1) {
      tasks[idx] = completedTask;
    }

    if (task.repeatEveryDays != null && task.repeatEveryDays! > 0) {
      final originId = (task.parentTaskId != null && task.parentTaskId!.isNotEmpty)
          ? task.parentTaskId!
          : task.id;

      final alreadyPending = tasks.any((t) =>
          t.plantId == task.plantId &&
          t.status == 'pending' &&
          (t.parentTaskId == originId || t.parentTaskId == task.id));

      if (!alreadyPending) {
        final nextTask = CareTask(
          id: 'task-next-${tasks.length + 1}',
          plantId: task.plantId,
          createdBy: task.createdBy,
          title: task.title,
          description: task.description,
          taskType: task.taskType,
          dueAt: DateTime.now().add(Duration(days: task.repeatEveryDays!)),
          repeatEveryDays: task.repeatEveryDays,
          status: 'pending',
          parentTaskId: originId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        tasks.add(nextTask);
      }
    }

    return idx != -1 ? tasks[idx] : completedTask;
  }

  @override
  Future<CareTask> createCareTask({
    required String plantId,
    required String title,
    String? description,
    String taskType = 'other',
    DateTime? dueAt,
    int? repeatEveryDays,
    String? parentTaskId,
  }) async {
    createCallCount++;
    lastCreatedPayload = {
      'plantId': plantId,
      'title': title,
      'description': description,
      'taskType': taskType,
      'dueAt': dueAt,
      'repeatEveryDays': repeatEveryDays,
      'parentTaskId': parentTaskId,
    };
    final newTask = CareTask(
      id: 'task-new-${tasks.length + 1}',
      plantId: plantId,
      createdBy: 'user-1',
      title: title,
      description: description,
      taskType: taskType,
      dueAt: dueAt,
      repeatEveryDays: repeatEveryDays,
      status: 'pending',
      parentTaskId: parentTaskId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    tasks.add(newTask);
    return newTask;
  }

  @override
  Future<CareTask> updateCareTask({
    required String taskId,
    required String title,
    String? description,
    String taskType = 'other',
    DateTime? dueAt,
    int? repeatEveryDays,
  }) async {
    updateCallCount++;
    lastUpdatedPayload = {
      'taskId': taskId,
      'title': title,
      'description': description,
      'taskType': taskType,
      'dueAt': dueAt,
      'repeatEveryDays': repeatEveryDays,
    };
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      tasks[idx] = tasks[idx].copyWith(
        title: title,
        description: description,
        taskType: taskType,
        dueAt: dueAt,
        repeatEveryDays: repeatEveryDays,
        updatedAt: DateTime.now(),
      );
      return tasks[idx];
    }
    throw Exception('Task not found');
  }
}

void main() {
  final testPlant = Plant(
    id: 'p-1',
    ownerId: 'u-1',
    name: 'خس البرج الرأسي A',
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    updatedAt: DateTime.now(),
  );

  Widget createCareTestWidget(CareTaskService fakeService, {Locale locale = const Locale('ar')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      home: CareTasksScreen(
        plant: testPlant,
        careTaskService: fakeService,
      ),
    );
  }

  group('M5 — Care Tasks Screen UI & Form Tests', () {
    testWidgets('Renders upcoming tasks and shows custom task types properly', (tester) async {
      final fakeService = FakeCareTaskService(tasks: [
        CareTask(
          id: 't-1',
          plantId: 'p-1',
          createdBy: 'u-1',
          title: 'رش مغذي ورقي',
          description: '[نوع: تغذية ورقية مخصصة] رش رذاذ خفيف بعد الغروب',
          taskType: 'other',
          dueAt: DateTime.now().add(const Duration(days: 2)),
          repeatEveryDays: 7,
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createCareTestWidget(fakeService));
      await tester.pumpAndSettle();

      // Verify custom task type is displayed
      expect(find.text('رش مغذي ورقي'), findsOneWidget);
      expect(find.text('تغذية ورقية مخصصة'), findsOneWidget);
      expect(find.text('رش رذاذ خفيف بعد الغروب'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('Completing a task moves to completed tab and shows next due date for recurring task', (tester) async {
      final fakeService = FakeCareTaskService(tasks: [
        CareTask(
          id: 't-recurring',
          plantId: 'p-1',
          createdBy: 'u-1',
          title: 'ري دوري هيدروبونيك',
          taskType: 'watering',
          dueAt: DateTime.now().add(const Duration(days: 1)),
          repeatEveryDays: 3,
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createCareTestWidget(fakeService));
      await tester.pumpAndSettle();

      // Tap complete button
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(fakeService.completeCallCount, 1);
      // SnackBar shows success with next due date
      expect(find.textContaining('الموعد القادم:'), findsOneWidget);
      // The completed task is in completed tab
      expect(find.text('ري دوري هيدروبونيك'), findsOneWidget);
    });

    testWidgets('Task form validates empty title and invalid repeat days', (tester) async {
      final fakeService = FakeCareTaskService(tasks: []);

      await tester.pumpWidget(createCareTestWidget(fakeService));
      await tester.pumpAndSettle();

      // Tap Add Task FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Leave title empty and press save
      await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(find.text('يرجى إدخال عنوان المهمة'), findsOneWidget);
      expect(fakeService.createCallCount, 0);

      // Verify recurring toggle defaults to OFF (false)
      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

      // Enter title
      await tester.enterText(find.widgetWithText(TextFormField, 'عنوان المهمة *'), 'تقليم الأوراق');

      // Toggle recurring to ON
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

      // Enter invalid repeat days (-2)
      await tester.enterText(find.widgetWithText(TextFormField, 'التكرار كل (أيام) *'), '-2');

      await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(find.text('أدخل عدد أيام صحيح أكبر من 0'), findsOneWidget);
      expect(fakeService.createCallCount, 0);
    });

    testWidgets('Selecting Other task type requires custom type name and saves format [نوع: ...]', (tester) async {
      final fakeService = FakeCareTaskService(tasks: []);

      await tester.pumpWidget(createCareTestWidget(fakeService));
      await tester.pumpAndSettle();

      // Tap Add Task FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill title
      await tester.enterText(find.widgetWithText(TextFormField, 'عنوان المهمة *'), 'فحص حموضة الماء');

      // Select 'أخرى' in dropdown
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'نوع المهمة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('أخرى').last);
      await tester.pumpAndSettle();

      // Verify custom type field appears
      expect(find.text('اسم نوع المهمة المخصص *'), findsOneWidget);

      // Try saving without custom type name
      await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(find.text('يرجى كتابة اسم نوع المهمة المخصص'), findsOneWidget);

      // Enter custom type name
      await tester.enterText(find.widgetWithText(TextFormField, 'اسم نوع المهمة المخصص *'), 'فحص pH/EC');
      await tester.enterText(find.widgetWithText(TextFormField, 'ملاحظات إضافية (اختياري)'), 'التأكد من pH بين 5.8 و 6.2');

      await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(fakeService.createCallCount, 1);
      expect(fakeService.lastCreatedPayload?['taskType'], 'other');
      expect(fakeService.lastCreatedPayload?['description'], '[نوع: فحص pH/EC] التأكد من pH بين 5.8 و 6.2');
    });

    testWidgets('Editing task updates existing task without duplicating', (tester) async {
      final existing = CareTask(
        id: 't-edit-1',
        plantId: 'p-1',
        createdBy: 'u-1',
        title: 'ري قديم',
        description: 'ملاحظة قديمة',
        taskType: 'watering',
        dueAt: DateTime.now().add(const Duration(days: 1)),
        repeatEveryDays: 2,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final fakeService = FakeCareTaskService(tasks: [existing]);

      await tester.pumpWidget(createCareTestWidget(fakeService));
      await tester.pumpAndSettle();

      // Tap Edit button
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('تعديل مهمة عناية'), findsOneWidget);

      // Change title
      await tester.enterText(find.widgetWithText(TextFormField, 'عنوان المهمة *'), 'ري معدل مكثف');
      await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(fakeService.updateCallCount, 1);
      expect(fakeService.lastUpdatedPayload?['taskId'], 't-edit-1');
      expect(fakeService.lastUpdatedPayload?['title'], 'ري معدل مكثف');
    });
  });

  group('M5 — Analytics Responsive Comparison UI Tests', () {
    testWidgets('Renders comparison dropdowns in Column on narrow screen and shows table without overflow', (tester) async {
      // Set narrow screen size (360 x 800)
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const summaryA = PlantAnalyticsSummary(
        plantId: 'p-1',
        plantName: 'خس هيدروبونيك نظام مغلق A1 مع اسم طويل جداً لتجربة الاختصار',
        speciesName: 'خس بستاني',
        ageDays: 30,
        totalInspections: 10,
        healthyCount: 8,
        attentionCount: 2,
        uncertainCount: 0,
        careCompletionRate: 85.0,
        totalTasks: 10,
        completedTasks: 8,
      );

      const summaryB = PlantAnalyticsSummary(
        plantId: 'p-2',
        plantName: 'طماطم شيري برج رأسي B2 مع اسم طويل ممتد للتأكد من عدم الفيض',
        speciesName: 'طماطم كرزية',
        ageDays: 45,
        totalInspections: 12,
        healthyCount: 9,
        attentionCount: 3,
        uncertainCount: 0,
        careCompletionRate: 90.0,
        totalTasks: 12,
        completedTasks: 11,
      );

      final fakeAnalytics = FakeAnalyticsService(summaries: [summaryA, summaryB]);
      final fakePlants = FakePlantService();

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: AnalyticsScreen(
          analyticsService: fakeAnalytics,
          plantService: fakePlants,
        ),
      ));

      await tester.pumpAndSettle();

      // Scroll to comparison section
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.scrollUntilVisible(switchFinder, 200);
      await tester.pumpAndSettle();

      // Turn on comparison switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // In narrow view (< 420 px), dropdowns must be inside a Column
      expect(find.byType(DropdownButtonFormField<PlantAnalyticsSummary>), findsNWidgets(2));

      // Both dropdowns are pre-selected to summaryA and summaryB
      // Verify comparison table appears with no RenderFlex overflow
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('العمر'), findsOneWidget);
      expect(find.text('30 يوم'), findsOneWidget);
      expect(find.text('45 يوم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AnalyticsScreen displays "لا توجد فحوصات" when inspections are 0', (tester) async {
      LocaleService.localeNotifier.value = const Locale('ar');
      const zeroInspectionsSummary = PlantAnalyticsSummary(
        plantId: 'plant-1',
        plantName: 'طماطم شيري',
        ageDays: 10,
        totalInspections: 0,
        healthyCount: 0,
        attentionCount: 0,
        uncertainCount: 0,
        careCompletionRate: 80.0,
        totalTasks: 5,
        completedTasks: 4,
      );

      final fakeAnalyticsZero = FakeAnalyticsService(summaries: [zeroInspectionsSummary]);
      final fakePlants = FakePlantService();

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: AnalyticsScreen(
          analyticsService: fakeAnalyticsZero,
          plantService: fakePlants,
        ),
      ));
      await tester.pumpAndSettle();

      // Must display "لا توجد فحوصات" in KPI card instead of "100%"
      expect(find.text('لا توجد فحوصات'), findsOneWidget);
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('AnalyticsScreen displays "0%" when inspections exist but none are healthy', (tester) async {
      LocaleService.localeNotifier.value = const Locale('ar');
      const zeroHealthySummary = PlantAnalyticsSummary(
        plantId: 'plant-2',
        plantName: 'ريحان مجهد',
        ageDays: 15,
        totalInspections: 4,
        healthyCount: 0,
        attentionCount: 4,
        uncertainCount: 0,
        careCompletionRate: 50.0,
        totalTasks: 4,
        completedTasks: 2,
      );

      final fakeAnalyticsUnhealthy = FakeAnalyticsService(summaries: [zeroHealthySummary]);
      final fakePlants = FakePlantService();

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: AnalyticsScreen(
          analyticsService: fakeAnalyticsUnhealthy,
          plantService: fakePlants,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('لا توجد فحوصات'), findsNothing);
    });

    test('AnalyticsService exportToCsv outputs "لا توجد فحوصات" when plant has 0 inspections', () {
      const summary = PlantAnalyticsSummary(
        plantId: 'plant-zero',
        plantName: 'نبتة جديدة بدون فحص',
        speciesName: 'طماطم',
        ageDays: 5,
        totalInspections: 0,
        healthyCount: 0,
        attentionCount: 0,
        uncertainCount: 0,
        careCompletionRate: 0.0,
        totalTasks: 0,
        completedTasks: 0,
      );

      final service = AnalyticsService();
      final csvArabic = service.exportToCsv([summary], isArabic: true);
      expect(csvArabic.contains('لا توجد فحوصات'), isTrue);

      final csvEnglish = service.exportToCsv([summary], isArabic: false);
      expect(csvEnglish.contains('No inspections'), isTrue);
    });
  });
}

class FakePlantService extends Fake implements PlantService {
  @override
  Future<List<Plant>> getPlants({String? search, String? status = 'active'}) async => [];
}

class FakeAnalyticsService extends Fake implements AnalyticsService {
  final List<PlantAnalyticsSummary> summaries;
  FakeAnalyticsService({required this.summaries});

  @override
  Future<List<PlantAnalyticsSummary>> getAnalyticsSummary({
    String? plantId,
    String? speciesId,
    int? daysRange,
    bool isArabic = true,
  }) async {
    return summaries;
  }
}

