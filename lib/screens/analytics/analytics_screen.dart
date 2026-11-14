import 'package:flutter/material.dart';
import '../../models/plant.dart';
import '../../services/analytics_service.dart';
import '../../services/plant_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class AnalyticsScreen extends StatefulWidget {
  final AnalyticsService? analyticsService;
  final PlantService? plantService;
  final bool isViewer;

  const AnalyticsScreen({
    super.key,
    this.analyticsService,
    this.plantService,
    this.isViewer = false,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsService _analyticsService;
  late final PlantService _plantService;

  List<Plant> _plants = [];
  List<PlantAnalyticsSummary> _summaries = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  String? _selectedPlantId;
  int? _selectedDays = 30; // 7, 30, 90, null (all)

  // Comparison between 2 plants
  PlantAnalyticsSummary? _comparePlantA;
  PlantAnalyticsSummary? _comparePlantB;
  bool _showComparison = false;

  @override
  void initState() {
    super.initState();
    _analyticsService = widget.analyticsService ?? AnalyticsService();
    _plantService = widget.plantService ?? PlantService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plants = await _plantService.getPlants();
      final summaries = await _analyticsService.getAnalyticsSummary(
        plantId: _selectedPlantId,
        daysRange: _selectedDays,
      );

      if (mounted) {
        setState(() {
          _plants = plants;
          _summaries = summaries;
          if (_summaries.length >= 2) {
            _comparePlantA = _summaries[0];
            _comparePlantB = _summaries[1];
          } else if (_summaries.isNotEmpty) {
            _comparePlantA = _summaries[0];
            _comparePlantB = null;
          }
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

  void _exportCsv() {
    final l10n = context.l10n;
    final csv = _analyticsService.exportToCsv(_summaries, isArabic: l10n.isArabic);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.table_chart_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.exportCsv),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(l10n.exportSuccess),
                ),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final l10n = context.l10n;
    final filterText = _selectedDays != null
        ? '$_selectedDays ${l10n.days}'
        : (l10n.isArabic ? 'كافة الفترات' : 'All Time');

    try {
      final pdfBytes = await _analyticsService.exportToPdf(
        _summaries,
        filterTitle: filterText,
        isArabic: l10n.isArabic,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(l10n.exportPdf),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 48),
                const SizedBox(height: 12),
                Text(
                  l10n.isArabic
                      ? 'تم إنشاء تقرير PDF بنجاح بحجم ${pdfBytes.lengthInBytes} بايت.'
                      : 'PDF report generated successfully (${pdfBytes.lengthInBytes} bytes).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.isArabic
                    ? 'يحتوي التقرير على كافة المؤشرات والبيانات المطابقة للفترة المختارة على الشاشة.'
                    : 'Report includes all metrics and filtered on-screen data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.done),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;

    final totalInspections = _summaries.fold<int>(0, (sum, i) => sum + i.totalInspections);
    final overallCareRate = _summaries.isNotEmpty
        ? _summaries.fold<double>(0, (sum, i) => sum + i.careCompletionRate) / _summaries.length
        : 0.0;
    final totalHealthy = _summaries.fold<int>(0, (sum, i) => sum + i.healthyCount);
    final healthRatio = totalInspections > 0
        ? (totalHealthy / totalInspections) * 100.0
        : 100.0;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n.analyticsTitle),
        actions: const [
          LanguageToggleButton(),
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
                        onPressed: _loadData,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Filters Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.lightGreen.withAlpha(120)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'فلترة البيانات المعروضة' : 'Filter Displayed Data',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    value: _selectedPlantId,
                                    decoration: InputDecoration(
                                      labelText: l10n.filterByPlant,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(isArabic ? 'كافة النباتات' : 'All Plants'),
                                      ),
                                      ..._plants.map((p) => DropdownMenuItem(
                                            value: p.id,
                                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                                          )),
                                    ],
                                    onChanged: (val) {
                                      setState(() => _selectedPlantId = val);
                                      _loadData();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    value: _selectedDays,
                                    decoration: InputDecoration(
                                      labelText: l10n.filterByDate,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    items: [
                                      DropdownMenuItem(value: 7, child: Text(isArabic ? 'آخر 7 أيام' : 'Last 7 Days')),
                                      DropdownMenuItem(value: 30, child: Text(isArabic ? 'آخر 30 يوماً' : 'Last 30 Days')),
                                      DropdownMenuItem(value: 90, child: Text(isArabic ? 'آخر 90 يوماً' : 'Last 90 Days')),
                                      DropdownMenuItem(value: null, child: Text(isArabic ? 'كافة الفترات' : 'All Time')),
                                    ],
                                    onChanged: (val) {
                                      setState(() => _selectedDays = val);
                                      _loadData();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // KPI Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              Icons.psychology_outlined,
                              '$totalInspections',
                              l10n.inspectionsCount,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              Icons.favorite_outline_rounded,
                              '${healthRatio.toStringAsFixed(0)}%',
                              l10n.healthRatio,
                              const Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              Icons.task_alt_rounded,
                              '${overallCareRate.toStringAsFixed(0)}%',
                              l10n.careCompletionRate,
                              const Color(0xFF00796B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Export Actions Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _exportCsv,
                              icon: const Icon(Icons.table_chart_outlined, size: 18),
                              label: Text(l10n.exportCsv),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportPdf,
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                              label: Text(l10n.exportPdf),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Compare Two Plants Section Toggle
                      Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.compare_arrows_rounded, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.compareTrends,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _showComparison,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) => setState(() => _showComparison = val),
                                  ),
                                ],
                              ),
                              if (_showComparison && _summaries.length >= 2) ...[
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<PlantAnalyticsSummary>(
                                        value: _comparePlantA,
                                        decoration: InputDecoration(labelText: l10n.selectPlantA),
                                        items: _summaries.map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.plantName, overflow: TextOverflow.ellipsis),
                                        )).toList(),
                                        onChanged: (val) => setState(() => _comparePlantA = val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<PlantAnalyticsSummary>(
                                        value: _comparePlantB,
                                        decoration: InputDecoration(labelText: l10n.selectPlantB),
                                        items: _summaries.map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.plantName, overflow: TextOverflow.ellipsis),
                                        )).toList(),
                                        onChanged: (val) => setState(() => _comparePlantB = val),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_comparePlantA != null && _comparePlantB != null) ...[
                                  _buildComparisonTable(_comparePlantA!, _comparePlantB!, isArabic),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Detailed Plants Table List
                      Text(
                        isArabic ? 'سجل بيانات النباتات المحفوظة' : 'Saved Plant Performance Records',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      ..._summaries.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppColors.lightGreen.withAlpha(120)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.plantName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${l10n.plantAge}: ${item.ageDays} ${l10n.days}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.speciesName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.speciesName!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatColumn(l10n.inspectionsCount, '${item.totalInspections}'),
                                  _buildStatColumn(isArabic ? 'سليمة' : 'Healthy', '${item.healthyCount}'),
                                  _buildStatColumn(isArabic ? 'إجهاد' : 'Attention', '${item.attentionCount}'),
                                  _buildStatColumn(l10n.careCompletionRate, '${item.careCompletionRate.toStringAsFixed(0)}%'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildComparisonTable(PlantAnalyticsSummary a, PlantAnalyticsSummary b, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
            children: [
              Padding(padding: const EdgeInsets.all(6), child: Text(isArabic ? 'المؤشر' : 'Metric', style: const TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: const EdgeInsets.all(6), child: Text(a.plantName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
              Padding(padding: const EdgeInsets.all(6), child: Text(b.plantName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B)))),
            ],
          ),
          _buildCompareRow(isArabic ? 'العمر' : 'Age', '${a.ageDays} يوم', '${b.ageDays} يوم'),
          _buildCompareRow(isArabic ? 'عدد الفحوصات' : 'Inspections', '${a.totalInspections}', '${b.totalInspections}'),
          _buildCompareRow(isArabic ? 'الحالات السليمة' : 'Healthy', '${a.healthyCount}', '${b.healthyCount}'),
          _buildCompareRow(isArabic ? 'حالات الإجهاد' : 'Attention', '${a.attentionCount}', '${b.attentionCount}'),
          _buildCompareRow(isArabic ? 'نسبة إنجاز العناية' : 'Care Rate', '${a.careCompletionRate.toStringAsFixed(0)}%', '${b.careCompletionRate.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  TableRow _buildCompareRow(String metric, String valA, String valB) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: Text(metric, style: const TextStyle(fontSize: 12))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: Text(valA, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: Text(valB, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    );
  }
}
