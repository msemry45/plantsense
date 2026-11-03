import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/l10n/app_localizations.dart';
import 'package:plantsense/models/plant.dart';
import 'package:plantsense/models/species.dart';
import 'package:plantsense/models/plant_image.dart';
import 'package:plantsense/models/observation_note.dart';
import 'package:plantsense/models/diagnosis.dart';
import 'package:plantsense/models/user_profile.dart';
import 'package:plantsense/theme/app_theme.dart';
import 'package:plantsense/screens/plants/plant_details_screen.dart';
import 'package:plantsense/services/plant_service.dart';
import 'package:plantsense/services/plant_image_service.dart';
import 'package:plantsense/services/observation_note_service.dart';
import 'package:plantsense/services/diagnosis_service.dart';
import 'package:plantsense/services/auth_service.dart';

class FakePlantService extends Fake implements PlantService {
  @override
  Future<Plant?> getPlantById(String id) async {
    final now = DateTime(2026, 10, 1);
    return Plant(
      id: id,
      ownerId: 'owner-1',
      name: 'طماطم البرج الرأسي',
      speciesId: 'species-1',
      location: 'البرج الرأسي A1',
      status: 'active',
      species: Species(
        id: 'species-1',
        commonName: 'Tomato',
        scientificName: 'Solanum lycopersicum',
        createdAt: now,
        updatedAt: now,
      ),
      plantedOn: now,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class FakePlantImageService extends Fake implements PlantImageService {
  @override
  Future<List<PlantImage>> getPlantImages(String plantId) async {
    final now = DateTime(2026, 11, 1);
    return [
      PlantImage(
        id: 'img-1',
        plantId: plantId,
        uploadedBy: 'owner-1',
        storagePath: 'images/img-1.jpg',
        capturedAt: now,
        signedUrl: 'https://example.com/img-1.jpg',
        createdAt: now,
      ),
    ];
  }
}

class FakeObservationNoteService extends Fake implements ObservationNoteService {
  @override
  Future<List<ObservationNote>> getNotes(String plantId) async {
    final now = DateTime(2026, 11, 2);
    return [
      ObservationNote(
        id: 'note-1',
        plantId: plantId,
        authorId: 'owner-1',
        note: 'نمو طبيعي وممتاز للأوراق',
        observedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

class FakeDiagnosisService extends Fake implements DiagnosisService {
  final Diagnosis? diagnosisToReturn;
  FakeDiagnosisService({this.diagnosisToReturn});

  @override
  Future<Diagnosis?> getLatestDiagnosis(String plantId) async {
    return diagnosisToReturn;
  }
}

class FakeAuthService extends Fake implements AuthService {
  @override
  UserProfile? get currentUserProfile => UserProfile(
        id: 'owner-1',
        username: 'farmer',
        fullName: 'Farmer User',
        role: 'farmer',
        status: 'active',
      );
}

void main() {
  final defaultDiagnosis = Diagnosis(
    id: 'diag-1',
    analysisRequestId: 'req-1',
    plantId: 'plant-123',
    imageId: 'img-1',
    label: 'Healthy',
    severity: 'healthy',
    summary: 'الأوراق خضراء نضرة بدون علامات إجهاد مرئية.',
    recommendations: ['الاستمرار في جدول الري والإضاءة المعتاد.'],
    visibleSigns: ['أوراق نضرة', 'لون طبيعي'],
    confidence: 0.95,
    createdAt: DateTime(2026, 11, 2),
  );

  Widget createSubject({
    required Locale locale,
    Diagnosis? diagnosis,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
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
      locale: locale,
      home: PlantDetailsScreen(
        plantId: 'plant-123',
        plantService: FakePlantService(),
        plantImageService: FakePlantImageService(),
        noteService: FakeObservationNoteService(),
        diagnosisService: FakeDiagnosisService(diagnosisToReturn: diagnosis),
        authService: FakeAuthService(),
      ),
    );
  }

  testWidgets('PlantDetailsScreen with AppTheme renders Arabic layout without exceptions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(
      locale: const Locale('ar'),
      diagnosis: defaultDiagnosis,
    ));

    // Initial pump: shows loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Await async data loading
    await tester.pumpAndSettle();

    // Verify no layout or rendering exceptions occurred
    expect(tester.takeException(), isNull);

    // Verify plant name is rendered and has positive dimensions
    final plantTitle = find.text('طماطم البرج الرأسي');
    expect(plantTitle, findsWidgets);
    final titleSize = tester.getSize(plantTitle.first);
    expect(titleSize.width, greaterThan(0));
    expect(titleSize.height, greaterThan(0));

    // Scroll down to reveal AI diagnosis card
    final aiCardFinder = find.textContaining('فحص حالة الأوراق بالذكاء الاصطناعي');
    await tester.scrollUntilVisible(aiCardFinder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    // Verify no exceptions after scroll
    expect(tester.takeException(), isNull);
    expect(aiCardFinder, findsOneWidget);

    // Check that the AI card has valid non-zero layout size
    final cardSize = tester.getSize(aiCardFinder);
    expect(cardSize.width, greaterThan(100));
    expect(cardSize.height, greaterThan(20));

    // Check reanalyze button is present and laid out properly without infinite width errors
    final reanalyzeButton = find.ancestor(
      of: find.text('إعادة الفحص'),
      matching: find.byWidgetPredicate((w) => w is OutlinedButton),
    );
    expect(reanalyzeButton, findsOneWidget);
    final buttonSize = tester.getSize(reanalyzeButton);
    expect(buttonSize.width, greaterThan(50));
    expect(buttonSize.width, lessThan(400)); // Crucial: must NOT be infinite!
    expect(buttonSize.height, equals(48));

    // Check full report button
    final reportButton = find.ancestor(
      of: find.text('عرض التقرير الكامل'),
      matching: find.byWidgetPredicate((w) => w is ElevatedButton),
    );
    expect(reportButton, findsOneWidget);
    final reportSize = tester.getSize(reportButton);
    expect(reportSize.width, greaterThan(100));
    expect(reportSize.height, greaterThan(30));
  });

  testWidgets('PlantDetailsScreen with AppTheme renders English layout without exceptions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(
      locale: const Locale('en'),
      diagnosis: defaultDiagnosis,
    ));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scroll down to reveal AI diagnosis card
    final aiCardFinder = find.textContaining('AI Leaf Condition Analysis');
    await tester.scrollUntilVisible(aiCardFinder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(aiCardFinder, findsOneWidget);

    final reanalyzeButton = find.ancestor(
      of: find.text('Re-analyze'),
      matching: find.byWidgetPredicate((w) => w is OutlinedButton),
    );
    expect(reanalyzeButton, findsOneWidget);
    final buttonSize = tester.getSize(reanalyzeButton);
    expect(buttonSize.width, greaterThan(50));
    expect(buttonSize.width, lessThan(400));
    expect(buttonSize.height, equals(48));
  });

  testWidgets('PlantDetailsScreen renders without previous diagnosis', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(
      locale: const Locale('ar'),
      diagnosis: null,
    ));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scroll down to reveal AI diagnosis card
    final aiCardFinder = find.textContaining('فحص حالة الأوراق بالذكاء الاصطناعي');
    await tester.scrollUntilVisible(aiCardFinder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(aiCardFinder, findsOneWidget);
    expect(find.textContaining('التقط صورة لورقة النبات لبدء الفحص البصري بالذكاء الاصطناعي'), findsOneWidget);
  });

  testWidgets('PlantDetailsScreen handles pull-to-refresh properly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(
      locale: const Locale('ar'),
      diagnosis: defaultDiagnosis,
    ));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Trigger refresh indicator drag
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('طماطم البرج الرأسي'), findsWidgets);
  });
}
