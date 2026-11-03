import 'package:flutter/material.dart';
import '../../models/diagnosis.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final String plantName;
  final Diagnosis diagnosis;
  final String? imageUrl;

  const DiagnosisResultScreen({
    super.key,
    required this.plantName,
    required this.diagnosis,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;

    // Status styling
    Color statusBg;
    Color statusFg;
    IconData statusIcon;

    if (diagnosis.isHealthy) {
      statusBg = const Color(0xFFE2F3E7);
      statusFg = AppColors.primary;
      statusIcon = Icons.check_circle_rounded;
    } else if (diagnosis.isUncertain) {
      statusBg = const Color(0xFFECEFF1);
      statusFg = const Color(0xFF455A64);
      statusIcon = Icons.help_outline_rounded;
    } else {
      statusBg = const Color(0xFFFFF3E0);
      statusFg = const Color(0xFFE65100);
      statusIcon = Icons.warning_amber_rounded;
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n.analysisResultTitle),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plant Name & Date header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightGreen.withAlpha(140)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.lightGreen,
                    child: Icon(Icons.psychology_outlined,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plantName,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${diagnosis.createdAt.year}-${diagnosis.createdAt.month.toString().padLeft(2, '0')}-${diagnosis.createdAt.day.toString().padLeft(2, '0')} • ${diagnosis.createdAt.hour.toString().padLeft(2, '0')}:${diagnosis.createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.dark.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (diagnosis.isCached) ...[
                    Tooltip(
                      message: l10n.cachedDiagnosisNotice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withAlpha(120),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              isArabic ? 'سابق' : 'Cached',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      diagnosis.rawResponse?['request_language'] == 'en'
                          ? (isArabic ? 'اللغة الأصلية: EN' : 'Original: EN')
                          : (isArabic ? 'اللغة الأصلية: عربي' : 'Original: AR'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Status Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusFg.withOpacity(0.35)),
              ),
              child: Column(
                children: [
                  Icon(statusIcon, color: statusFg, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    diagnosis.localizedStatus(isArabic),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: statusFg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${l10n.severityLabel}: ${diagnosis.localizedSeverity(isArabic)}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Visible Signs Observed Section
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.lightGreen.withAlpha(140)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.visibleSignsLabel,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (diagnosis.visibleSigns.isEmpty)
                      Text(
                        l10n.noVisibleSignsFound,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.dark.withOpacity(0.65),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: diagnosis.visibleSigns.map((sign) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen.withAlpha(140),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              sign,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Confidence Note / Summary
            if (diagnosis.summary != null && diagnosis.summary!.trim().isNotEmpty) ...[
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.lightGreen.withAlpha(140)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notes_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.confidenceNoteLabel,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        diagnosis.summary!,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recommendations List
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.lightGreen.withAlpha(140)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tips_and_updates_outlined,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.recommendationsLabel,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (diagnosis.recommendations.isEmpty)
                      Text(
                        l10n.noRecommendations,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.dark.withOpacity(0.65),
                        ),
                      )
                    else
                      ...diagnosis.recommendations.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final rec = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Center(
                                  child: Text(
                                    '$idx',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 14,
                                    height: 1.45,
                                    color: AppColors.dark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Advisory Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.disclaimerLabel,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          diagnosis.disclaimer ?? l10n.disclaimerDefault,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.brown.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Done / Return Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
  }
}
