import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant.dart';
import '../models/diagnosis.dart';
import '../models/care_task.dart';

class PlantAnalyticsSummary {
  final String plantId;
  final String plantName;
  final String? speciesName;
  final int ageDays;
  final int totalInspections;
  final int healthyCount;
  final int attentionCount;
  final int uncertainCount;
  final double careCompletionRate;
  final int totalTasks;
  final int completedTasks;
  final DateTime? lastInspectionDate;
  final String? lastStatus;

  const PlantAnalyticsSummary({
    required this.plantId,
    required this.plantName,
    this.speciesName,
    required this.ageDays,
    required this.totalInspections,
    required this.healthyCount,
    required this.attentionCount,
    required this.uncertainCount,
    required this.careCompletionRate,
    required this.totalTasks,
    required this.completedTasks,
    this.lastInspectionDate,
    this.lastStatus,
  });
}

class AnalyticsService {
  final SupabaseClient? _clientInstance;

  AnalyticsService({SupabaseClient? client}) : _clientInstance = client;

  SupabaseClient get _client => _clientInstance ?? Supabase.instance.client;

  /// Fetch and aggregate real historical data for plants
  Future<List<PlantAnalyticsSummary>> getAnalyticsSummary({
    String? plantId,
    String? speciesId,
    int? daysRange,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // 1. Fetch plants
    var plantQuery = _client.from('plants').select('*, species(*)');
    if (plantId != null && plantId.isNotEmpty) {
      plantQuery = plantQuery.eq('id', plantId);
    }
    if (speciesId != null && speciesId.isNotEmpty) {
      plantQuery = plantQuery.eq('species_id', speciesId);
    }

    final plantRows = await plantQuery.order('created_at', ascending: false);
    final plants = plantRows.map((r) => Plant.fromJson(r)).toList();

    if (plants.isEmpty) return [];

    final plantIds = plants.map((p) => p.id).toList();

    // 2. Fetch diagnoses
    var diagQuery = _client
        .from('diagnoses')
        .select()
        .inFilter('plant_id', plantIds);

    if (daysRange != null && daysRange > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: daysRange));
      diagQuery = diagQuery.gte('created_at', cutoff.toIso8601String());
    }

    final diagRows = await diagQuery.order('created_at', ascending: false);
    final diagnoses = diagRows.map((r) => Diagnosis.fromJson(r)).toList();

    // 3. Fetch care tasks
    var taskQuery = _client
        .from('care_tasks')
        .select()
        .inFilter('plant_id', plantIds);

    if (daysRange != null && daysRange > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: daysRange));
      taskQuery = taskQuery.gte('created_at', cutoff.toIso8601String());
    }

    final taskRows = await taskQuery;
    final tasks = taskRows.map((r) => CareTask.fromJson(r)).toList();

    // 4. Aggregate metrics per plant
    final summaries = <PlantAnalyticsSummary>[];
    final now = DateTime.now();

    for (final plant in plants) {
      final plantDiags = diagnoses.where((d) => d.plantId == plant.id).toList();
      final plantTasks = tasks.where((t) => t.plantId == plant.id).toList();

      final healthy = plantDiags.where((d) => d.isHealthy).length;
      final attention = plantDiags.where((d) => d.needsAttention).length;
      final uncertain = plantDiags.where((d) => d.isUncertain).length;

      final completedTasksCount = plantTasks.where((t) => t.isCompleted).length;
      final totalTasksCount = plantTasks.length;
      final completionRate = totalTasksCount > 0
          ? (completedTasksCount / totalTasksCount) * 100.0
          : 0.0;

      final ageDays = plant.daysSincePlanted ?? now.difference(plant.createdAt).inDays;

      summaries.add(PlantAnalyticsSummary(
        plantId: plant.id,
        plantName: plant.name,
        speciesName: plant.species?.commonName,
        ageDays: ageDays < 0 ? 0 : ageDays,
        totalInspections: plantDiags.length,
        healthyCount: healthy,
        attentionCount: attention,
        uncertainCount: uncertain,
        careCompletionRate: completionRate,
        totalTasks: totalTasksCount,
        completedTasks: completedTasksCount,
        lastInspectionDate: plantDiags.isNotEmpty ? plantDiags.first.createdAt : null,
        lastStatus: plantDiags.isNotEmpty ? plantDiags.first.label : null,
      ));
    }

    return summaries;
  }

  /// Generate RFC 4180 compliant CSV string with UTF-8 BOM
  String exportToCsv(List<PlantAnalyticsSummary> items, {bool isArabic = true}) {
    final buffer = StringBuffer();
    // UTF-8 BOM so Excel opens Arabic correctly
    buffer.write('\uFEFF');

    if (isArabic) {
      buffer.writeln(
          'اسم النبات,النوع الزراعي,العمر (أيام),عدد الفحوصات,الحالات السليمة,حالات بحاجة لاهتمام,غير مؤكد,نسبة إنجاز العناية %,إجمالي المهام,المهام المنجزة,تاريخ آخر فحص,آخر حالة');
    } else {
      buffer.writeln(
          'Plant Name,Species,Age (Days),Total Inspections,Healthy,Attention Needed,Uncertain,Care Completion Rate %,Total Tasks,Completed Tasks,Last Inspection Date,Last Status');
    }

    for (final item in items) {
      final lastDate = item.lastInspectionDate != null
          ? '${item.lastInspectionDate!.year}-${item.lastInspectionDate!.month.toString().padLeft(2, '0')}-${item.lastInspectionDate!.day.toString().padLeft(2, '0')}'
          : '-';

      final row = [
        _escapeCsv(item.plantName),
        _escapeCsv(item.speciesName ?? '-'),
        item.ageDays.toString(),
        item.totalInspections.toString(),
        item.healthyCount.toString(),
        item.attentionCount.toString(),
        item.uncertainCount.toString(),
        '${item.careCompletionRate.toStringAsFixed(1)}%',
        item.totalTasks.toString(),
        item.completedTasks.toString(),
        lastDate,
        _escapeCsv(item.lastStatus ?? '-'),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Generate structured PDF document bytes
  Future<Uint8List> exportToPdf(
    List<PlantAnalyticsSummary> items, {
    required String filterTitle,
    bool isArabic = true,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final totalPlants = items.length;
          final totalInspections = items.fold<int>(0, (sum, i) => sum + i.totalInspections);
          final avgCare = items.isNotEmpty
              ? items.fold<double>(0, (sum, i) => sum + i.careCompletionRate) / items.length
              : 0.0;

          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SVPG — Smart Vertical Plant Growth Monitoring',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Growth Analytics & Performance Report',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),
            pw.Text('Filter Period: $filterTitle',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 16),

            // Summary KPI Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildKpiCard('Total Plants', '$totalPlants'),
                _buildKpiCard('Total Leaf Inspections', '$totalInspections'),
                _buildKpiCard('Avg Care Completion', '${avgCare.toStringAsFixed(1)}%'),
              ],
            ),

            pw.SizedBox(height: 20),

            // Table
            pw.TableHelper.fromTextArray(
              headers: [
                'Plant',
                'Species',
                'Age (days)',
                'Inspections',
                'Healthy',
                'Attention',
                'Care %',
                'Last Status'
              ],
              data: items.map((i) {
                return [
                  i.plantName,
                  i.speciesName ?? '-',
                  '${i.ageDays}',
                  '${i.totalInspections}',
                  '${i.healthyCount}',
                  '${i.attentionCount}',
                  '${i.careCompletionRate.toStringAsFixed(0)}%',
                  i.lastStatus ?? '-',
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1B4D3E)),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),

            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              'SVPG Academic Monitoring System • Real Saved Historical Data • Ground Truth Measurements',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildKpiCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
