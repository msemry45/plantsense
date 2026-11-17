import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env is intentionally not bundled in release assets to prevent secret leakage.
  }

  const defaultUrl = 'https://tpsguqbyqlvsxrshwcks.supabase.co';
  const defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRwc2d1cWJ5cWx2c3hyc2h3Y2tzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0NjkzMjYsImV4cCI6MjEwNjA0NTMyNn0.o3OZuatIiUlcdbdxCC7KUVwOvpOeNEH3geKU4LFKl-4';

  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '')
      .isNotEmpty
      ? const String.fromEnvironment('SUPABASE_URL')
      : ((dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null) ?? defaultUrl);

  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '')
      .isNotEmpty
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : ((dotenv.isInitialized ? dotenv.env['SUPABASE_ANON_KEY'] : null) ?? defaultAnonKey);

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await LocaleService.init();

  final authService = AuthService();

  runApp(SVPGApp(authService: authService));
}

class SVPGApp extends StatefulWidget {
  final AuthService authService;

  const SVPGApp({super.key, required this.authService});

  @override
  State<SVPGApp> createState() => _SVPGAppState();
}

class _SVPGAppState extends State<SVPGApp> {
  late final _router = createRouter(widget.authService);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp.router(
          title: 'SVPG',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        );
      },
    );
  }
}
