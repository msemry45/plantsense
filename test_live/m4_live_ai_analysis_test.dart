// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotenv/dotenv.dart';
import 'package:plantsense/services/auth_service.dart';
import 'package:plantsense/services/plant_service.dart';
import 'package:plantsense/services/plant_image_service.dart';
import 'package:plantsense/services/species_service.dart';
import 'package:plantsense/services/diagnosis_service.dart';

void main() {
  late String supabaseUrl;
  late String supabaseKey;
  late String farmerEmail;
  late String farmerPassword;
  late String viewerEmail;
  late String viewerPassword;

  setUpAll(() {
    final env = DotEnv(includePlatformEnvironment: true)..load(['.env.test']);
    supabaseUrl = env['SUPABASE_URL']!;
    supabaseKey = env['SUPABASE_ANON_KEY']!;
    farmerEmail = env['TEST_FARMER_EMAIL']!;
    farmerPassword = env['TEST_FARMER_PASSWORD']!;
    viewerEmail = env['TEST_VIEWER_EMAIL'] ?? 'viewer@test.com';
    viewerPassword = env['TEST_VIEWER_PASSWORD'] ?? 'password123';
  });

  test('Live M4 Verification: Signup Without 429, Custom Species, and 4 Visual Leaf Cases', () async {
    final anonClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    // =========================================================================
    // STEP 1: Verify New User Registration (Bypassing 429 SMTP rate limit)
    // =========================================================================
    print('\n--- STEP 1: Register New User via AuthService (Zero 429) ---');
    final authService = AuthService(client: anonClient);
    final uniqueTimestamp = DateTime.now().millisecondsSinceEpoch;
    final newEmail = 'farmer_live_$uniqueTimestamp@plantsense.test';
    final newUsername = 'farmer_$uniqueTimestamp';
    final newPassword = 'Password_123!';

    await authService.signUp(
      email: newEmail,
      password: newPassword,
      username: newUsername,
      fullName: 'مزارع تجريبي حي M4',
    );
    print('1. New user registration succeeded without 429!');
    print('   -> Email: $newEmail, Username: $newUsername');

    // Verify immediate sign-in with the new credentials
    final testUserClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final newAuthRes = await testUserClient.auth.signInWithPassword(
      email: newEmail,
      password: newPassword,
    );
    expect(newAuthRes.user, isNotNull);
    expect(newAuthRes.user!.email, newEmail);
    print('   -> Immediate sign-in confirmed with JWT token generated: ${newAuthRes.user!.id}');

    // =========================================================================
    // STEP 2: Authenticate Standard Farmer
    // =========================================================================
    print('\n--- STEP 2: Authenticate Standard Farmer & Setup Services ---');
    final farmerClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final farmerAuth = await farmerClient.auth.signInWithPassword(
      email: farmerEmail,
      password: farmerPassword,
    );
    expect(farmerAuth.user, isNotNull);
    final farmerId = farmerAuth.user!.id;
    print('2. Farmer authenticated: $farmerId ($farmerEmail)');

    final speciesService = SpeciesService(client: farmerClient);
    final plantService = PlantService(client: farmerClient);
    final imageService = PlantImageService(client: farmerClient);
    final diagnosisService = DiagnosisService(client: farmerClient);

    // =========================================================================
    // STEP 3: Manual Agricultural Species Addition
    // =========================================================================
    print('\n--- STEP 3: Manual Agricultural Species Addition ---');
    final customSpeciesName = 'نعناع جبلي مخصص $uniqueTimestamp';
    final customSpecies = await speciesService.createCustomSpecies(
      customSpeciesName,
      scientificName: 'Mentha microphylla',
    );
    expect(customSpecies.id, isNotEmpty);
    expect(customSpecies.commonName, customSpeciesName);
    expect(customSpecies.isPublished, isTrue);
    print('3. Added custom agricultural species successfully:');
    print('   -> ID: ${customSpecies.id}, Common: ${customSpecies.commonName}, Sci: ${customSpecies.scientificName}');

    // Create a plant using this custom species
    final customPlant = await plantService.createPlant(
      name: 'حوض نعناع الجبل 01',
      speciesId: customSpecies.id,
      location: 'البرج العمودي الجنوبي',
      plantedOn: DateTime.now().subtract(const Duration(days: 10)),
      notes: 'تمت إضافته بالنوع الزراعي المخصص يدوياً.',
    );
    expect(customPlant.id, isNotNull);
    print('   -> Plant linked to custom species: ${customPlant.name} (ID: ${customPlant.id})');

    // =========================================================================
    // STEP 4: Run 4 Distinct Real Image Analysis Cases
    // =========================================================================
    print('\n--- STEP 4: 4 Distinct Real Image Analysis Cases ---');
    final resultsTable = <Map<String, String>>[];

    // --- CASE 1: Visibly Healthy Tomato Leaf ---
    print('\n>> Case 1: Visibly Healthy Leaf (assets/test_plants/tomato_healthy.jpg)');
    final healthyBytes = await File('assets/test_plants/tomato_healthy.jpg').readAsBytes();
    final imgHealthy = await imageService.uploadPlantImage(
      plantId: customPlant.id,
      imageBytes: healthyBytes,
      fileName: 'case1_healthy_leaf.jpg',
      source: 'camera',
      mimeType: 'image/jpeg',
      capturedAt: DateTime.now(),
    );
    expect(imgHealthy.id, isNotNull);

    final diagHealthy = await diagnosisService.analyzePlantImage(
      plantId: customPlant.id,
      imageId: imgHealthy.id,
      speciesCommon: 'طماطم كرزية',
      language: 'ar',
    );
    expect(diagHealthy.id, isNotEmpty);
    expect(diagHealthy.imageId, imgHealthy.id);
    expect(diagHealthy.isHealthy, isTrue);
    expect(diagHealthy.isCached, isFalse);

    resultsTable.add({
      'case': '1. حالة سليمة ظاهرياً (Healthy)',
      'image': 'tomato_healthy.jpg',
      'expected': 'Healthy / شدة: None / عدم ظهور علامات إجهاد واضحة',
      'actual_status': diagHealthy.label,
      'actual_severity': diagHealthy.severity,
      'notes': diagHealthy.summary ?? '',
    });
    print('   [Result Case 1] Status: ${diagHealthy.label}, Severity: ${diagHealthy.severity}');
    print('   Summary: ${diagHealthy.summary}');

    // Test Idempotency for Case 1
    final diagHealthyCached = await diagnosisService.analyzePlantImage(
      plantId: customPlant.id,
      imageId: imgHealthy.id,
      language: 'ar',
    );
    expect(diagHealthyCached.id, diagHealthy.id);
    expect(diagHealthyCached.isCached, isTrue);
    print('   -> Idempotency verified: 2nd call returned existing diagnosis (isCached: true)');

    // --- CASE 2: Stressed Leaf with Chlorosis ---
    print('\n>> Case 2: Clear Stress Signs (assets/test_plants/leaf_stressed_chlorosis.jpg)');
    final stressedBytes = await File('assets/test_plants/leaf_stressed_chlorosis.jpg').readAsBytes();
    final imgStressed = await imageService.uploadPlantImage(
      plantId: customPlant.id,
      imageBytes: stressedBytes,
      fileName: 'case2_chlorosis_leaf.jpg',
      source: 'camera',
      mimeType: 'image/jpeg',
      capturedAt: DateTime.now(),
    );
    expect(imgStressed.id, isNotNull);

    final diagStressed = await diagnosisService.analyzePlantImage(
      plantId: customPlant.id,
      imageId: imgStressed.id,
      speciesCommon: 'طماطم',
      language: 'ar',
    );
    expect(diagStressed.id, isNotEmpty);
    expect(diagStressed.needsAttention, isTrue);
    expect(diagStressed.visibleSigns, isNotEmpty);

    resultsTable.add({
      'case': '2. علامات إجهاد واضحة (Stress/Chlorosis)',
      'image': 'leaf_stressed_chlorosis.jpg',
      'expected': 'Attention Needed / شدة: Low-High / اصفرار أو إجهاد',
      'actual_status': diagStressed.label,
      'actual_severity': diagStressed.severity,
      'notes': '${diagStressed.visibleSigns.join(", ")} - ${diagStressed.summary}',
    });
    print('   [Result Case 2] Status: ${diagStressed.label}, Severity: ${diagStressed.severity}');
    print('   Signs: ${diagStressed.visibleSigns}');
    print('   Summary: ${diagStressed.summary}');

    // --- CASE 3: Blurry Leaf Photo ---
    print('\n>> Case 3: Blurry Leaf (assets/test_plants/blurry_leaf.jpg)');
    final blurryBytes = await File('assets/test_plants/blurry_leaf.jpg').readAsBytes();
    final imgBlurry = await imageService.uploadPlantImage(
      plantId: customPlant.id,
      imageBytes: blurryBytes,
      fileName: 'case3_blurry_leaf.jpg',
      source: 'gallery',
      mimeType: 'image/jpeg',
      capturedAt: DateTime.now(),
    );
    expect(imgBlurry.id, isNotNull);

    final diagBlurry = await diagnosisService.analyzePlantImage(
      plantId: customPlant.id,
      imageId: imgBlurry.id,
      speciesCommon: 'نعناع',
      language: 'ar',
    );
    expect(diagBlurry.id, isNotEmpty);
    expect(diagBlurry.isUncertain, isTrue);

    resultsTable.add({
      'case': '3. صورة ضبابية (Blurry Leaf)',
      'image': 'blurry_leaf.jpg',
      'expected': 'Uncertain / شدة: Uncertain / طلب صورة أوضح وأقرب',
      'actual_status': diagBlurry.label,
      'actual_severity': diagBlurry.severity,
      'notes': diagBlurry.summary ?? '',
    });
    print('   [Result Case 3] Status: ${diagBlurry.label}, Severity: ${diagBlurry.severity}');
    print('   Summary: ${diagBlurry.summary}');

    // --- CASE 4: Non-Plant Image ---
    print('\n>> Case 4: Non-Plant Object (assets/test_plants/non_plant_object.jpg)');
    final nonPlantBytes = await File('assets/test_plants/non_plant_object.jpg').readAsBytes();
    final imgNonPlant = await imageService.uploadPlantImage(
      plantId: customPlant.id,
      imageBytes: nonPlantBytes,
      fileName: 'case4_non_plant_object.jpg',
      source: 'gallery',
      mimeType: 'image/jpeg',
      capturedAt: DateTime.now(),
    );
    expect(imgNonPlant.id, isNotNull);

    final diagNonPlant = await diagnosisService.analyzePlantImage(
      plantId: customPlant.id,
      imageId: imgNonPlant.id,
      language: 'ar',
    );
    expect(diagNonPlant.id, isNotEmpty);
    expect(diagNonPlant.isUncertain, isTrue);

    resultsTable.add({
      'case': '4. صورة غير نباتية (Non-Plant Object)',
      'image': 'non_plant_object.jpg',
      'expected': 'Uncertain / شدة: Uncertain / عدم وجود نبات قابل للفحص',
      'actual_status': diagNonPlant.label,
      'actual_severity': diagNonPlant.severity,
      'notes': diagNonPlant.summary ?? '',
    });
    print('   [Result Case 4] Status: ${diagNonPlant.label}, Severity: ${diagNonPlant.severity}');
    print('   Summary: ${diagNonPlant.summary}');

    // =========================================================================
    // STEP 5: Persistence Across Fresh Client Session (App Restart Simulation)
    // =========================================================================
    print('\n--- STEP 5: Persistence & Linkage Across Restart ---');
    final freshClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    await freshClient.auth.signInWithPassword(
      email: farmerEmail,
      password: farmerPassword,
    );
    final freshDiagnosisService = DiagnosisService(client: freshClient);
    final freshImageService = PlantImageService(client: freshClient);

    final persistedDiagnoses = await freshDiagnosisService.getPlantDiagnosesHistory(customPlant.id);
    expect(persistedDiagnoses.length, 4);
    print('5. Diagnoses persisted in database across new client: ${persistedDiagnoses.length} records found.');

    final persistedImages = await freshImageService.getPlantImages(customPlant.id);
    expect(persistedImages.length, 4);
    print('   -> Images persisted: ${persistedImages.length} images.');
    for (final img in persistedImages) {
      expect(img.signedUrl, isNotNull);
      expect(img.signedUrl, isNotEmpty);
    }
    print('   -> All 4 signed URLs generated successfully from private Storage.');

    // Verify linkage of each diagnosis to its exact image_id
    expect(persistedDiagnoses.any((d) => d.imageId == imgHealthy.id), isTrue);
    expect(persistedDiagnoses.any((d) => d.imageId == imgStressed.id), isTrue);
    expect(persistedDiagnoses.any((d) => d.imageId == imgBlurry.id), isTrue);
    expect(persistedDiagnoses.any((d) => d.imageId == imgNonPlant.id), isTrue);
    print('   -> Each diagnosis correctly linked to its distinct image_id!');

    // =========================================================================
    // STEP 6: Print Markdown Results Table
    // =========================================================================
    print('\n========================================================================================');
    print('جدول نتائج رحلة التحليل البصري لحالات النبات الأربعة (M4 Analysis Journey Table):');
    print('========================================================================================');
    print('| الحالة المختبرة | ملف الصورة | النتيجة المتوقعة | الحالة الفعلية | الشدة الفعلية | الملاحظة وخلاصة النموذج |');
    print('|---|---|---|---|---|---|');
    for (final r in resultsTable) {
      print('| ${r['case']} | `${r['image']}` | ${r['expected']} | **${r['actual_status']}** | ${r['actual_severity']} | ${r['notes']} |');
    }
    print('========================================================================================\n');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
