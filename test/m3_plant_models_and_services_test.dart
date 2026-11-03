import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/models/plant.dart';
import 'package:plantsense/models/species.dart';
import 'package:plantsense/models/plant_image.dart';
import 'package:plantsense/models/observation_note.dart';
import 'package:plantsense/services/plant_image_service.dart';

void main() {
  group('Milestone 3 - Models & Validation Tests', () {
    test('Species model correctly serializes and deserializes', () {
      final json = {
        'id': 'spec-1',
        'common_name': 'Sweet Basil',
        'scientific_name': 'Ocimum basilicum',
        'description': 'Aromatic herb',
        'care_instructions': 'Water regularly at the base',
        'ideal_temperature_min': 18.5,
        'ideal_temperature_max': 28.0,
        'ideal_humidity_min': 40.0,
        'ideal_humidity_max': 65.0,
        'ideal_light_conditions': 'Full sun',
        'is_published': true,
        'created_at': '2026-10-01T10:00:00.000Z',
        'updated_at': '2026-10-01T10:00:00.000Z',
      };

      final species = Species.fromJson(json);

      expect(species.id, 'spec-1');
      expect(species.commonName, 'Sweet Basil');
      expect(species.scientificName, 'Ocimum basilicum');
      expect(species.idealTemperatureMin, 18.5);
      expect(species.isPublished, isTrue);

      final encoded = species.toJson();
      expect(encoded['common_name'], 'Sweet Basil');
      expect(encoded['is_published'], isTrue);
    });

    test('Plant model calculates daysSincePlanted and handles joined species', () {
      final plantedDate = DateTime.now().subtract(const Duration(days: 15));
      final json = {
        'id': 'plant-101',
        'owner_id': 'user-1',
        'species_id': 'spec-1',
        'name': 'Tower Alpha Tomato',
        'location': 'Greenhouse Rack 1',
        'planted_on': plantedDate.toIso8601String().split('T').first,
        'notes': 'Planted in rockwool cube',
        'status': 'active',
        'created_at': '2026-10-05T08:00:00.000Z',
        'updated_at': '2026-10-05T08:00:00.000Z',
        'species': {
          'id': 'spec-1',
          'common_name': 'Tomato',
          'scientific_name': 'Solanum lycopersicum',
          'is_published': true,
          'created_at': '2026-10-01T00:00:00.000Z',
          'updated_at': '2026-10-01T00:00:00.000Z',
        },
      };

      final plant = Plant.fromJson(json);

      expect(plant.id, 'plant-101');
      expect(plant.name, 'Tower Alpha Tomato');
      expect(plant.species?.commonName, 'Tomato');
      expect(plant.daysSincePlanted, inInclusiveRange(14, 16));

      final updated = plant.copyWith(name: 'Tower Alpha Cherry Tomato');
      expect(updated.name, 'Tower Alpha Cherry Tomato');
      expect(updated.id, plant.id);
      expect(updated.species?.commonName, 'Tomato');
    });

    test('PlantImage model formats file sizes and preserves signed URLs', () {
      final json = {
        'id': 'img-501',
        'plant_id': 'plant-101',
        'uploaded_by': 'user-1',
        'storage_path': 'user-1/plant-101/growth_01.jpg',
        'source': 'camera',
        'captured_at': '2026-10-15T12:00:00.000Z',
        'width': 1920,
        'height': 1080,
        'file_size_bytes': 2 * 1024 * 1024, // 2 MB
        'mime_type': 'image/jpeg',
        'created_at': '2026-10-15T12:01:00.000Z',
      };

      final img = PlantImage.fromJson(json, signedUrl: 'https://example.com/signed/growth_01.jpg');

      expect(img.id, 'img-501');
      expect(img.source, 'camera');
      expect(img.formattedFileSize, '2.00 MB');
      expect(img.signedUrl, 'https://example.com/signed/growth_01.jpg');
    });

    test('ObservationNote model serializes and deserializes accurately', () {
      final json = {
        'id': 'note-1',
        'plant_id': 'plant-101',
        'author_id': 'user-1',
        'note': 'First flower cluster emerged on the main stem.',
        'observed_at': '2026-10-20T14:30:00.000Z',
        'created_at': '2026-10-20T14:30:00.000Z',
        'updated_at': '2026-10-20T14:30:00.000Z',
      };

      final note = ObservationNote.fromJson(json);

      expect(note.id, 'note-1');
      expect(note.note, contains('flower cluster'));
      expect(note.authorId, 'user-1');

      final encoded = note.toJson();
      expect(encoded['note'], contains('flower cluster'));
    });

    test('PlantImageService rejects images larger than 10 MB', () async {
      final service = PlantImageService();
      // Dummy bytes of 10.5 MB
      final oversizedBytes = Uint8List(11 * 1024 * 1024);

      expect(
        () => service.uploadPlantImage(
          plantId: 'plant-101',
          imageBytes: oversizedBytes,
          fileName: 'oversized.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('10 MB limit'),
        )),
      );
    });

    test('PlantImageService rejects unsupported MIME formats', () async {
      final service = PlantImageService();
      final validBytes = Uint8List(1024); // 1 KB

      expect(
        () => service.uploadPlantImage(
          plantId: 'plant-101',
          imageBytes: validBytes,
          fileName: 'file.gif',
          mimeType: 'image/gif',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Unsupported image format'),
        )),
      );
    });

    test('PlantImageService rejects empty file bytes', () async {
      final service = PlantImageService();
      final emptyBytes = Uint8List(0);

      expect(
        () => service.uploadPlantImage(
          plantId: 'plant-101',
          imageBytes: emptyBytes,
          fileName: 'empty.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('empty'),
        )),
      );
    });
  });
}

