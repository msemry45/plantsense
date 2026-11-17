import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/l10n/app_localizations.dart';
import 'package:plantsense/screens/register_screen.dart';
import 'package:plantsense/services/auth_service.dart';
import 'package:plantsense/services/locale_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends ChangeNotifier implements AuthService {
  Exception? errorToThrow;
  int signUpCallCount = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastUsername;
  String? lastFullName;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    signUpCallCount++;
    lastEmail = email;
    lastPassword = password;
    lastUsername = username;
    lastFullName = fullName;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockAuthService mockAuth;

  setUp(() {
    LocaleService.localeNotifier.value = const Locale('ar');
    mockAuth = _MockAuthService();
  });

  Widget createWidget({Locale locale = const Locale('ar')}) {
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
      home: RegisterScreen(authService: mockAuth),
    );
  }

  group('RegisterScreen Form Validation & Error Handling', () {
    testWidgets('Empty form blocks network request and shows required name validation', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Must not call signUp on backend
      expect(mockAuth.signUpCallCount, 0);
      expect(find.text('يرجى إدخال الاسم الكامل.'), findsOneWidget);
    });

    testWidgets('Validates username minimum length and format before sending request', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter full name
      await tester.enterText(find.byType(TextField).at(0), 'أحمد علي');
      // Enter short username
      await tester.enterText(find.byType(TextField).at(1), 'ah');

      final buttonFinder = find.byType(ElevatedButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(mockAuth.signUpCallCount, 0);
      expect(find.text('اسم المستخدم يجب أن يتكون من 3 أحرف أو أرقام على الأقل.'), findsOneWidget);
    });

    testWidgets('Validates invalid email format before sending request', (tester) async {
      await tester.pumpWidget(createWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'johndoe');
      await tester.enterText(find.byType(TextField).at(2), 'invalid-email');

      final buttonFinder = find.byType(ElevatedButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(mockAuth.signUpCallCount, 0);
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Validates password length and password match before sending request', (tester) async {
      await tester.pumpWidget(createWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'johndoe');
      await tester.enterText(find.byType(TextField).at(2), 'john@example.com');
      await tester.enterText(find.byType(TextField).at(3), '123'); // short password
      await tester.enterText(find.byType(TextField).at(4), '123');

      final buttonFinder = find.byType(ElevatedButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(mockAuth.signUpCallCount, 0);
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);

      // Fix length but mismatch
      await tester.enterText(find.byType(TextField).at(3), 'password123');
      await tester.enterText(find.byType(TextField).at(4), 'mismatch456');

      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(mockAuth.signUpCallCount, 0);
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('Maps duplicate username error gracefully without raw exception', (tester) async {
      mockAuth.errorToThrow = const AuthException('username already taken', statusCode: '400');

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'مزارع تجريبي');
      await tester.enterText(find.byType(TextField).at(1), 'existing_user');
      await tester.enterText(find.byType(TextField).at(2), 'farmer@example.com');
      await tester.enterText(find.byType(TextField).at(3), 'secret123');
      await tester.enterText(find.byType(TextField).at(4), 'secret123');

      final buttonFinder = find.byType(ElevatedButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(mockAuth.signUpCallCount, 1);
      expect(find.text('اسم المستخدم محجوز بالفعل. يرجى اختيار اسم آخر.'), findsOneWidget);
    });

    testWidgets('Maps network socket exception to clear connection error', (tester) async {
      mockAuth.errorToThrow = const SocketException('Failed host lookup');

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'مزارع تجريبي');
      await tester.enterText(find.byType(TextField).at(1), 'new_farmer');
      await tester.enterText(find.byType(TextField).at(2), 'farmer@example.com');
      await tester.enterText(find.byType(TextField).at(3), 'secret123');
      await tester.enterText(find.byType(TextField).at(4), 'secret123');

      final buttonFinder = find.byType(ElevatedButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(mockAuth.signUpCallCount, 1);
      expect(find.text('تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.'), findsOneWidget);
    });

    testWidgets('Submits valid form and calls signUp successfully', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'مزارع تجريبي');
      await tester.enterText(find.byType(TextField).at(1), 'farmer_good');
      await tester.enterText(find.byType(TextField).at(2), 'farmer@example.com');
      await tester.enterText(find.byType(TextField).at(3), 'secret123');
      await tester.enterText(find.byType(TextField).at(4), 'secret123');

      final buttonFinder = find.byType(ElevatedButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(mockAuth.signUpCallCount, 1);
      expect(mockAuth.lastEmail, 'farmer@example.com');
      expect(mockAuth.lastUsername, 'farmer_good');
      expect(mockAuth.lastFullName, 'مزارع تجريبي');
      expect(mockAuth.lastPassword, 'secret123');
    });
  });
}
