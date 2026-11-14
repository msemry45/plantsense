import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/l10n/app_localizations.dart';
import 'package:plantsense/screens/reset_password_screen.dart';
import 'package:plantsense/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Fake implements SupabaseClient {
  final MockGoTrueClient _auth;
  MockSupabaseClient(this._auth);

  @override
  GoTrueClient get auth => _auth;
}

class MockGoTrueClient extends Fake implements GoTrueClient {
  User? _mockUser;
  bool updatePasswordCalled = false;
  String? updatedPassword;

  @override
  User? get currentUser => _mockUser;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<UserResponse> updateUser(UserAttributes attributes,
      {String? emailRedirectTo}) async {
    updatePasswordCalled = true;
    updatedPassword = attributes.password;
    return UserResponse.fromJson({
      'user': {
        'id': 'test-user-id',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': DateTime.now().toIso8601String(),
      }
    });
  }
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late AuthService authService;

  setUp(() {
    mockAuth = MockGoTrueClient();
    mockSupabase = MockSupabaseClient(mockAuth);
    authService = AuthService(client: mockSupabase);
  });

  Widget createWidget({Locale locale = const Locale('ar')}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ResetPasswordScreen(authService: authService),
    );
  }

  testWidgets('ResetPasswordScreen displays fields and validates matching passwords',
      (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Verify title and input fields are present
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Enter mismatching passwords
    await tester.enterText(find.byType(TextFormField).first, '123456');
    await tester.enterText(find.byType(TextFormField).last, '654321');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
    expect(mockAuth.updatePasswordCalled, isFalse);

    // Enter matching passwords
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(mockAuth.updatePasswordCalled, isTrue);
    expect(mockAuth.updatedPassword, equals('123456'));

    // Check success view
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
