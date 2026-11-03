import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotenv/dotenv.dart';
import 'package:plantsense/services/plant_service.dart';
import 'package:plantsense/services/plant_image_service.dart';
import 'package:plantsense/services/observation_note_service.dart';
import 'package:plantsense/services/species_service.dart';

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

  test('Live M3 Verification: Full Plant Lifecycle, Private Storage, Notes & Access Control', () async {
    final farmerClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final viewerClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    // 1. Sign In Farmer
    final farmerAuth = await farmerClient.auth.signInWithPassword(
      email: farmerEmail,
      password: farmerPassword,
    );
    expect(farmerAuth.user, isNotNull);
    final farmerId = farmerAuth.user!.id;

    // Clean any residual test plants from previous runs
    await farmerClient.from('plants').delete().eq('name', 'Test Raw Plant');
    await farmerClient.from('plants').delete().eq('name', 'Live Verified Test Tomato');

    // 2. Query Published Species
    final speciesService = SpeciesService(client: farmerClient);
    final speciesList = await speciesService.getPublishedSpecies();
    expect(speciesList, isNotEmpty);
    final selectedSpecies = speciesList.first;
    expect(selectedSpecies.isPublished, isTrue);

    // 3. Farmer creates a plant
    final plantService = PlantService(client: farmerClient);
    final plant = await plantService.createPlant(
      name: 'Live Verified Test Tomato',
      speciesId: selectedSpecies.id,
      location: 'Greenhouse Bed 4',
      plantedOn: DateTime.now().subtract(const Duration(days: 10)),
      notes: 'Initial test plant for M3 end-to-end verification.',
    );
    expect(plant.id, isNotNull);
    expect(plant.ownerId, farmerId);
    expect(plant.name, 'Live Verified Test Tomato');

    String? uploadedImageId;
    String? storagePath;

    try {
      // 4. Farmer uploads private growth image to `plant-images` bucket
      final imageService = PlantImageService(client: farmerClient);
      final dummyJpgBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0xFF, 0xD9
      ]);

      final plantImage = await imageService.uploadPlantImage(
        plantId: plant.id,
        imageBytes: dummyJpgBytes,
        fileName: 'live_test.jpg',
        source: 'camera',
        mimeType: 'image/jpeg',
      );
      uploadedImageId = plantImage.id;
      storagePath = plantImage.storagePath;

      expect(plantImage.id, isNotNull);
      expect(plantImage.plantId, plant.id);
      expect(plantImage.uploadedBy, farmerId);
      expect(plantImage.storagePath, startsWith('$farmerId/${plant.id}/'));
      expect(plantImage.signedUrl, isNotNull);

      // 5. Farmer adds an observation note
      final noteService = ObservationNoteService(client: farmerClient);
      final note = await noteService.addNote(
        plantId: plant.id,
        note: 'First flower bud observed during live check.',
      );
      expect(note.id, isNotNull);
      expect(note.authorId, farmerId);

      // 6. Sign In Viewer
      final viewerAuth = await viewerClient.auth.signInWithPassword(
        email: viewerEmail,
        password: viewerPassword,
      );
      expect(viewerAuth.user, isNotNull);
      final viewerId = viewerAuth.user!.id;

      // 7. Verify Viewer CANNOT read unpermitted plant (RLS Isolation)
      final viewerPlantService = PlantService(client: viewerClient);
      final viewerPlants = await viewerPlantService.getPlants();
      expect(
        viewerPlants.any((p) => p.id == plant.id),
        isFalse,
        reason: 'Viewer should not see unpermitted farmer plant',
      );

      // Verify Viewer CANNOT mutate unshared plant
      bool viewerMutationDenied = false;
      try {
        await viewerPlantService.updatePlant(
          id: plant.id,
          name: 'Hacked by Viewer',
        );
      } catch (_) {
        viewerMutationDenied = true;
      }
      expect(viewerMutationDenied, isTrue);

      // 8. Farmer grants explicit read access to Viewer via `plant_access`
      await farmerClient.from('plant_access').insert({
        'plant_id': plant.id,
        'viewer_id': viewerId,
        'granted_by': farmerId,
      });

      // 9. Permitted Viewer CAN now read the plant and image metadata
      final permittedPlant = await viewerPlantService.getPlantById(plant.id);
      expect(permittedPlant, isNotNull);
      expect(permittedPlant?.name, 'Live Verified Test Tomato');

      final viewerImageService = PlantImageService(client: viewerClient);
      final permittedImages = await viewerImageService.getPlantImages(plant.id);
      expect(permittedImages.any((img) => img.id == uploadedImageId), isTrue);

      // 10. Permitted Viewer STILL CANNOT mutate (delete or update)
      // Attempt unauthorized delete by viewer
      await viewerPlantService.deletePlant(plant.id);
      final checkAfterDelete = await plantService.getPlantById(plant.id);
      expect(checkAfterDelete, isNotNull, reason: 'Viewer delete attempt must not delete owner plant');

      // Attempt unauthorized update by viewer
      try {
        await viewerPlantService.updatePlant(id: plant.id, name: 'Hacked by Viewer');
      } catch (_) {}
      final checkAfterUpdate = await plantService.getPlantById(plant.id);
      expect(checkAfterUpdate?.name, 'Live Verified Test Tomato', reason: 'Viewer cannot alter plant name');

    } finally {
      // Clean up test data thoroughly
      try {
        if (storagePath != null) {
          await farmerClient.storage.from('plant-images').remove([storagePath]);
        }
        await plantService.deletePlant(plant.id);
      } catch (e) {
        // Log cleanup info
        // ignore: avoid_print
        print('Cleanup notice: $e');
      }
    }
  });
}
