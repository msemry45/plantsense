import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/services/analytics_service.dart';

void main() {
  test('Export real Arabic and English PDFs with embedded typography', () async {
    final regFile = File('assets/fonts/Amiri-Regular.ttf');
    final boldFile = File('assets/fonts/Amiri-Bold.ttf');
    expect(regFile.existsSync(), isTrue);
    expect(boldFile.existsSync(), isTrue);

    final regData = regFile.readAsBytesSync().buffer.asByteData();
    final boldData = boldFile.readAsBytesSync().buffer.asByteData();

    final now = DateTime.now();
    final summariesAr = [
      PlantAnalyticsSummary(
        plantId: 'plant-1',
        plantName: 'خس هيدروبونيك بنظام الزراعة المائية الرأسية المغلقة A1',
        speciesName: 'خس بستاني (Lactuca sativa)',
        ageDays: 24,
        totalInspections: 8,
        healthyCount: 7,
        attentionCount: 1,
        uncertainCount: 0,
        careCompletionRate: 92.0,
        totalTasks: 12,
        completedTasks: 11,
        lastInspectionDate: now.subtract(const Duration(days: 1)),
        lastStatus: 'Healthy',
      ),
      PlantAnalyticsSummary(
        plantId: 'plant-2',
        plantName: 'طماطم شيري معلقة - البرج الرأسي رقم 3',
        speciesName: 'طماطم كرزية (Solanum lycopersicum)',
        ageDays: 45,
        totalInspections: 14,
        healthyCount: 10,
        attentionCount: 4,
        uncertainCount: 0,
        careCompletionRate: 75.0,
        totalTasks: 16,
        completedTasks: 12,
        lastInspectionDate: now.subtract(const Duration(hours: 12)),
        lastStatus: 'Attention Needed',
      ),
      PlantAnalyticsSummary(
        plantId: 'plant-3',
        plantName: 'نعناع بلدي عطري',
        speciesName: 'نعناع (Mentha spicata)',
        ageDays: 15,
        totalInspections: 5,
        healthyCount: 5,
        attentionCount: 0,
        uncertainCount: 0,
        careCompletionRate: 100.0,
        totalTasks: 6,
        completedTasks: 6,
        lastInspectionDate: now.subtract(const Duration(days: 2)),
        lastStatus: 'Healthy',
      ),
    ];

    final summariesEn = [
      PlantAnalyticsSummary(
        plantId: 'plant-1',
        plantName: 'Hydroponic Butterhead Lettuce - Tower Section A1',
        speciesName: 'Garden Lettuce (Lactuca sativa)',
        ageDays: 24,
        totalInspections: 8,
        healthyCount: 7,
        attentionCount: 1,
        uncertainCount: 0,
        careCompletionRate: 92.0,
        totalTasks: 12,
        completedTasks: 11,
        lastInspectionDate: now.subtract(const Duration(days: 1)),
        lastStatus: 'Healthy',
      ),
      PlantAnalyticsSummary(
        plantId: 'plant-2',
        plantName: 'Cherry Tomatoes - Vertical Column 3',
        speciesName: 'Cherry Tomato (Solanum lycopersicum)',
        ageDays: 45,
        totalInspections: 14,
        healthyCount: 10,
        attentionCount: 4,
        uncertainCount: 0,
        careCompletionRate: 75.0,
        totalTasks: 16,
        completedTasks: 12,
        lastInspectionDate: now.subtract(const Duration(hours: 12)),
        lastStatus: 'Attention Needed',
      ),
      PlantAnalyticsSummary(
        plantId: 'plant-3',
        plantName: 'Spearmint Herbal Bed',
        speciesName: 'Spearmint (Mentha spicata)',
        ageDays: 15,
        totalInspections: 5,
        healthyCount: 5,
        attentionCount: 0,
        uncertainCount: 0,
        careCompletionRate: 100.0,
        totalTasks: 6,
        completedTasks: 6,
        lastInspectionDate: now.subtract(const Duration(days: 2)),
        lastStatus: 'Healthy',
      ),
    ];

    final service = AnalyticsService();

    // 1. Export Arabic PDF
    final bytesAr = await service.exportToPdf(
      summariesAr,
      filterTitle: 'آخر 30 يوماً',
      isArabic: true,
      regularFontData: regData,
      boldFontData: boldData,
    );

    final dir = Directory('release');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final fileAr = File('release/svpg_report_ar.pdf');
    fileAr.writeAsBytesSync(bytesAr);
    expect(fileAr.existsSync(), isTrue);
    expect(bytesAr.length, greaterThan(10000));

    // 2. Export English PDF
    final bytesEn = await service.exportToPdf(
      summariesEn,
      filterTitle: 'Last 30 Days',
      isArabic: false,
      regularFontData: regData,
      boldFontData: boldData,
    );

    final fileEn = File('release/svpg_report_en.pdf');
    fileEn.writeAsBytesSync(bytesEn);
    expect(fileEn.existsSync(), isTrue);
    expect(bytesEn.length, greaterThan(10000));
  });
}
