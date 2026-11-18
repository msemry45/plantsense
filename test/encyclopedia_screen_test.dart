import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/l10n/app_localizations.dart';
import 'package:plantsense/models/species.dart';
import 'package:plantsense/screens/encyclopedia/encyclopedia_screen.dart';
import 'package:plantsense/services/species_service.dart';
import 'package:plantsense/services/locale_service.dart';

class _FakeSpeciesService extends SpeciesService {
  final List<Species> speciesList;

  _FakeSpeciesService(this.speciesList);

  @override
  Future<List<Species>> getPublishedSpecies({String? search, bool forceRefresh = false}) async {
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      return speciesList
          .where((s) =>
              s.commonName.toLowerCase().contains(q) ||
              (s.scientificName?.toLowerCase().contains(q) ?? false) ||
              s.localizedName(true).contains(q))
          .toList();
    }
    return speciesList;
  }
}

void main() {
  final testSpecies = [
    Species(
      id: 'sp-1',
      commonName: 'Butterhead Lettuce',
      scientificName: 'Lactuca sativa',
      description: 'محصول ورقي سريع النضج ومثالي للطبقات الرأسية والزراعة المائية.',
      careInstructions: 'الحفاظ على برودة منطقة الجذور ودرجة رطوبة منتظمة.',
      idealTemperatureMin: 15,
      idealTemperatureMax: 22,
      idealHumidityMin: 60,
      idealHumidityMax: 80,
      idealLightConditions: 'ضوء ساطع غير مباشر 12-14 ساعة',
      imagePath: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Romaine_lettuce.jpg/800px-Romaine_lettuce.jpg',
      sourceUrl: 'https://ar.wikipedia.org/wiki/%D8%AE%D8%B3',
      license: 'CC BY-SA 3.0',
      attribution: 'Rainer Zenz (Wikimedia Commons)',
      isPublished: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Species(
      id: 'sp-2',
      commonName: 'Sweet Basil',
      scientificName: 'Ocimum basilicum',
      description: 'نبات عشبي عطري ينمو بكفاءة عالية في الأنظمة الرأسية.',
      careInstructions: 'تقليم القمم النامية دورياً لتحفيز التفرع الجانبي.',
      idealTemperatureMin: 20,
      idealTemperatureMax: 28,
      idealHumidityMin: 50,
      idealHumidityMax: 70,
      imagePath: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Basil-Basilico-Ocimum_basilicum-albahaca.jpg/800px-Basil-Basilico-Ocimum_basilicum-albahaca.jpg',
      sourceUrl: 'https://ar.wikipedia.org/wiki/%D8%B1%D9%8A%D8%AD%D8%A7%D9%86',
      license: 'CC BY-SA 3.0',
      attribution: 'Castielli (Wikimedia Commons)',
      isPublished: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Widget buildWidget({required SpeciesService service, Locale locale = const Locale('ar'), bool isGuest = true}) {
    LocaleService.localeNotifier.value = locale;
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: EncyclopediaScreen(
        speciesService: service,
        isGuest: isGuest,
      ),
    );
  }

  group('EncyclopediaScreen with Wikipedia Attribution Tests', () {
    testWidgets('Renders published species with localized Arabic names', (tester) async {
      final service = _FakeSpeciesService(testSpecies);
      await tester.pumpWidget(buildWidget(service: service, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('موسوعة النباتات الزراعية'), findsOneWidget);
      expect(find.text('خس (Butterhead Lettuce)'), findsOneWidget);
      expect(find.text('ريحان (Sweet Basil)'), findsOneWidget);
      expect(find.text('Lactuca sativa'), findsOneWidget);
      expect(find.text('Ocimum basilicum'), findsOneWidget);
    });

    testWidgets('Renders published species in English', (tester) async {
      final service = _FakeSpeciesService(testSpecies);
      await tester.pumpWidget(buildWidget(service: service, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Plant Encyclopedia'), findsOneWidget);
      expect(find.text('Butterhead Lettuce'), findsOneWidget);
      expect(find.text('Sweet Basil'), findsOneWidget);
    });

    testWidgets('Tapping species opens modal with Wikipedia source, attribution, and license', (tester) async {
      final service = _FakeSpeciesService(testSpecies);
      await tester.pumpWidget(buildWidget(service: service, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Tap on Lettuce card
      await tester.tap(find.text('خس (Butterhead Lettuce)'));
      await tester.pumpAndSettle();

      // Check modal content
      expect(find.text('المصدر: ويكيبيديا'), findsOneWidget);
      expect(find.text('عرض المقال في ويكيبيديا'), findsOneWidget);
      expect(find.textContaining('Rainer Zenz (Wikimedia Commons)'), findsOneWidget);
      expect(find.textContaining('CC BY-SA 3.0'), findsOneWidget);
      expect(find.text('إرشادات العناية'), findsOneWidget);
      expect(find.text('الظروف المثالية للنمو'), findsOneWidget);
    });

    testWidgets('Search filters species by common or scientific name', (tester) async {
      final service = _FakeSpeciesService(testSpecies);
      await tester.pumpWidget(buildWidget(service: service, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Lactuca');
      await tester.pumpAndSettle();

      expect(find.text('خس (Butterhead Lettuce)'), findsOneWidget);
      expect(find.text('ريحان (Sweet Basil)'), findsNothing);
    });
  });
}
