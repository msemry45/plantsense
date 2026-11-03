import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/models/diagnosis.dart';

void main() {
  group('Diagnosis Model Tests (Milestone 4)', () {
    test('parses successfully from Edge Function JSON response', () {
      final json = {
        'request_id': 'req-123',
        'diagnosis_id': 'diag-456',
        'plant_id': 'plant-789',
        'image_id': 'img-001',
        'status': 'completed',
        'cached': false,
        'result': {
          'health_status': 'Attention Needed',
          'visible_signs': ['اصفرار في أطراف الأوراق', 'ذبول طفيف'],
          'severity': 'Medium',
          'confidence_note': 'يظهر على النبتة علامات إجهاد نقص عناصر أو عدم انتظام في الري.',
          'recommendations': [
            'التحقق من مستوى المحلول المغذي ودرجة الحموضة pH.',
            'فحص تصريف المياه والتأكد من عدم تعفن الجذور.'
          ],
          'disclaimer': 'هذا التحليل استرشادي مبني على الصورة فقط ولا يُعد تشخيصاً زراعياً نهائياً.'
        }
      };

      final diagnosis = Diagnosis.fromJson(json);

      expect(diagnosis.id, 'diag-456');
      expect(diagnosis.analysisRequestId, 'req-123');
      expect(diagnosis.plantId, 'plant-789');
      expect(diagnosis.imageId, 'img-001');
      expect(diagnosis.label, 'Attention Needed');
      expect(diagnosis.severity, 'medium');
      expect(diagnosis.needsAttention, isTrue);
      expect(diagnosis.isHealthy, isFalse);
      expect(diagnosis.isUncertain, isFalse);
      expect(diagnosis.visibleSigns.length, 2);
      expect(diagnosis.visibleSigns.first, 'اصفرار في أطراف الأوراق');
      expect(diagnosis.recommendations.length, 2);
      expect(diagnosis.isCached, isFalse);
      expect(diagnosis.localizedStatus(true), 'يحتاج عناية');
      expect(diagnosis.localizedStatus(false), 'Attention Needed');
      expect(diagnosis.localizedSeverity(true), 'متوسط');
      expect(diagnosis.localizedSeverity(false), 'Medium');
    });

    test('parses healthy leaf diagnosis correctly', () {
      final json = {
        'id': 'diag-healthy',
        'analysis_request_id': 'req-healthy',
        'plant_id': 'plant-001',
        'image_id': 'img-002',
        'label': 'Healthy',
        'severity': 'healthy',
        'summary': 'الأوراق خضراء نضرة بدون علامات إجهاد مرئية.',
        'recommendations': ['الاستمرار في جدول الري والإضاءة المعتاد.'],
        'raw_response': {
          'health_status': 'Healthy',
          'visible_signs': ['لون أخضر متجانس', 'نضارة طبيعية'],
          'severity': 'None',
          'confidence_note': 'الأوراق خضراء نضرة بدون علامات إجهاد مرئية.',
          'recommendations': ['الاستمرار في جدول الري والإضاءة المعتاد.'],
          'disclaimer': 'هذا التحليل استرشادي مبني على الصورة فقط.'
        },
        'created_at': '2026-11-03T07:00:00Z',
      };

      final diagnosis = Diagnosis.fromJson(json);

      expect(diagnosis.isHealthy, isTrue);
      expect(diagnosis.needsAttention, isFalse);
      expect(diagnosis.isUncertain, isFalse);
      expect(diagnosis.localizedStatus(true), 'سليم');
      expect(diagnosis.localizedStatus(false), 'Healthy');
      expect(diagnosis.localizedSeverity(true), 'سليم (لا توجد أعراض)');
    });

    test('parses uncertain / non-plant leaf diagnosis correctly', () {
      final json = {
        'diagnosis_id': 'diag-uncertain',
        'request_id': 'req-uncertain',
        'plant_id': 'plant-002',
        'image_id': 'img-003',
        'cached': true,
        'result': {
          'health_status': 'Uncertain',
          'visible_signs': ['عدم وضوح تفاصيل الورقة', 'تشويش في الإضاءة'],
          'severity': 'Uncertain',
          'confidence_note': 'الصورة غير واضحة بما يكفي لتقييم صحة الأوراق.',
          'recommendations': [
            'إعادة التقاط صورة قريبة وواضحة للأوراق في إضاءة جيدة.'
          ],
          'disclaimer': 'هذا التحليل استرشادي.'
        }
      };

      final diagnosis = Diagnosis.fromJson(json, isCached: true);

      expect(diagnosis.isUncertain, isTrue);
      expect(diagnosis.isHealthy, isFalse);
      expect(diagnosis.needsAttention, isFalse);
      expect(diagnosis.isCached, isTrue);
      expect(diagnosis.localizedStatus(true), 'غير مؤكد');
      expect(diagnosis.localizedStatus(false), 'Uncertain');
      expect(diagnosis.localizedSeverity(true), 'غير محدد');
      expect(diagnosis.localizedSeverity(false), 'Uncertain');
    });

    test('handles fallback gracefully when raw fields are missing', () {
      final json = <String, dynamic>{
        'id': 'diag-minimal',
        'analysis_request_id': 'req-minimal',
        'plant_id': 'plant-min',
        'image_id': 'img-min',
        'label': 'Unknown',
      };

      final diagnosis = Diagnosis.fromJson(json);

      expect(diagnosis.id, 'diag-minimal');
      expect(diagnosis.label, 'Unknown');
      expect(diagnosis.severity, 'unknown');
      expect(diagnosis.visibleSigns, isEmpty);
      expect(diagnosis.recommendations, isEmpty);
      expect(diagnosis.disclaimer, isNotEmpty);
    });
  });
}
