import 'dart:convert';

/// Represents a multimodal AI plant leaf condition analysis result
/// aligned with the Thesis Data Dictionary and public.diagnoses schema.
class Diagnosis {
  final String id;
  final String analysisRequestId;
  final String plantId;
  final String imageId;
  final String label; // "Healthy" | "Attention Needed" | "Uncertain"
  final String? summary; // Confidence note or brief summary
  final double? confidence;
  final String severity; // "healthy" | "low" | "medium" | "high" | "unknown"
  final List<String> recommendations;
  final List<String> visibleSigns;
  final String? disclaimer;
  final Map<String, dynamic>? rawResponse;
  final DateTime createdAt;
  final bool isCached;

  const Diagnosis({
    required this.id,
    required this.analysisRequestId,
    required this.plantId,
    required this.imageId,
    required this.label,
    this.summary,
    this.confidence,
    required this.severity,
    required this.recommendations,
    this.visibleSigns = const [],
    this.disclaimer,
    this.rawResponse,
    required this.createdAt,
    this.isCached = false,
  });

  /// Factory constructor to parse from database row or Edge Function response
  factory Diagnosis.fromJson(Map<dynamic, dynamic> rawJson, {bool isCached = false}) {
    final json = Map<String, dynamic>.from(rawJson);

    // Determine raw response or result object safely
    Map<String, dynamic>? raw;
    if (json['raw_response'] != null) {
      if (json['raw_response'] is Map) {
        raw = Map<String, dynamic>.from(json['raw_response'] as Map);
      } else if (json['raw_response'] is String) {
        try {
          final decoded = jsonDecode(json['raw_response'] as String);
          if (decoded is Map) {
            raw = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    } else if (json['result'] != null && json['result'] is Map) {
      raw = Map<String, dynamic>.from(json['result'] as Map);
    }

    // Extract recommendations
    final recList = <String>[];
    final recSource = json['recommendations'] ?? raw?['recommendations'];
    if (recSource is List) {
      for (final item in recSource) {
        if (item != null && item.toString().trim().isNotEmpty) {
          recList.add(item.toString().trim());
        }
      }
    }

    // Extract visible signs
    final signsList = <String>[];
    final signsSource = json['visible_signs'] ?? raw?['visible_signs'];
    if (signsSource is List) {
      for (final item in signsSource) {
        if (item != null && item.toString().trim().isNotEmpty) {
          signsList.add(item.toString().trim());
        }
      }
    }

    // Extract disclaimer & confidence note
    final disclaimer = json['disclaimer'] as String? ??
        raw?['disclaimer'] as String? ??
        'هذا التحليل استرشادي مبني على الصورة فقط ولا يُعد تشخيصاً زراعياً نهائياً.';
    final confidenceNote = json['confidence_note'] as String? ??
        raw?['confidence_note'] as String? ??
        json['summary'] as String?;

    // Determine label / health status
    final labelValue = json['health_status'] as String? ??
        raw?['health_status'] as String? ??
        json['label'] as String? ??
        'Uncertain';

    // Determine severity
    final sevStr = (json['severity'] as String? ?? raw?['severity'] as String? ?? 'unknown').toLowerCase();
    String normalizedSeverity;
    if (sevStr.contains('none') || sevStr.contains('healthy')) {
      normalizedSeverity = 'healthy';
    } else if (sevStr.contains('low')) {
      normalizedSeverity = 'low';
    } else if (sevStr.contains('med')) {
      normalizedSeverity = 'medium';
    } else if (sevStr.contains('high')) {
      normalizedSeverity = 'high';
    } else {
      normalizedSeverity = 'unknown';
    }

    // Date
    DateTime parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // Confidence numeric
    double? conf;
    if (json['confidence'] != null) {
      conf = double.tryParse(json['confidence'].toString());
    }

    return Diagnosis(
      id: (json['id'] ?? json['diagnosis_id'] ?? '').toString(),
      analysisRequestId: (json['analysis_request_id'] ?? json['request_id'] ?? '').toString(),
      plantId: (json['plant_id'] ?? '').toString(),
      imageId: (json['image_id'] ?? '').toString(),
      label: labelValue,
      summary: confidenceNote,
      confidence: conf,
      severity: normalizedSeverity,
      recommendations: recList,
      visibleSigns: signsList,
      disclaimer: disclaimer,
      rawResponse: raw,
      createdAt: parsedDate,
      isCached: isCached || json['cached'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'analysis_request_id': analysisRequestId,
      'plant_id': plantId,
      'image_id': imageId,
      'label': label,
      'summary': summary,
      'confidence': confidence,
      'severity': severity,
      'recommendations': recommendations,
      'raw_response': rawResponse,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Visual status indicators
  bool get isHealthy =>
      label.toLowerCase().contains('healthy') ||
      label.contains('سليم') ||
      severity == 'healthy';

  bool get isUncertain =>
      label.toLowerCase().contains('uncertain') ||
      label.contains('غير مؤكد') ||
      severity == 'unknown';

  bool get needsAttention => !isHealthy && !isUncertain;

  String localizedStatus(bool isArabic) {
    if (isHealthy) return isArabic ? 'سليم' : 'Healthy';
    if (isUncertain) return isArabic ? 'غير مؤكد' : 'Uncertain';
    return isArabic ? 'يحتاج عناية' : 'Attention Needed';
  }

  String localizedSeverity(bool isArabic) {
    switch (severity) {
      case 'healthy':
        return isArabic ? 'سليم (لا توجد أعراض)' : 'None (Healthy)';
      case 'low':
        return isArabic ? 'منخفض' : 'Low';
      case 'medium':
        return isArabic ? 'متوسط' : 'Medium';
      case 'high':
        return isArabic ? 'مرتفع' : 'High';
      case 'unknown':
      default:
        return isArabic ? 'غير محدد' : 'Uncertain';
    }
  }
}
