import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/screens/forgot_password_screen.dart';
import 'package:plantsense/services/auth_service.dart';
import 'package:plantsense/services/locale_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends ChangeNotifier implements AuthService {
  Exception? errorToThrow;
  String? lastEmailReset;

  @override
  Future<void> resetPassword(String email) async {
    lastEmailReset = email;
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
    LocaleService.localeNotifier.value = const Locale('en');
    mockAuth = _MockAuthService();
  });

  tearDown(() {
    LocaleService.localeNotifier.value = const Locale('ar');
  });

  testWidgets('displays form view initially and validates empty email',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ForgotPasswordScreen(authService: mockAuth),
    ));

    expect(find.text('Reset Your Password'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Tap send with empty email
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(mockAuth.lastEmailReset, isNull);
  });

  testWidgets(
      'successful submission shows non-enumerating confirmation view',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ForgotPasswordScreen(authService: mockAuth),
    ));

    await tester.enterText(find.byType(TextField), 'farmer@plantsense.org');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(mockAuth.lastEmailReset, 'farmer@plantsense.org');
    expect(find.text('Check Your Email'), findsOneWidget);
    expect(
      find.text(
          'If an account exists with that email address, a password reset link has been sent.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'network failure shows retryable connection error and keeps form intact',
      (tester) async {
    mockAuth.errorToThrow = const SocketException('No route to host');

    await tester.pumpWidget(MaterialApp(
      home: ForgotPasswordScreen(authService: mockAuth),
    ));

    await tester.enterText(find.byType(TextField), 'farmer@plantsense.org');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    // Verify error SnackBar was shown
    expect(
      find.text(
          'Network error: Unable to connect. Please check your internet connection and try again.'),
      findsOneWidget,
    );

    // Form is still visible and ready for retry
    expect(find.text('Reset Your Password'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets(
      'rate limit (429) shows too many requests notice and does not show false success',
      (tester) async {
    mockAuth.errorToThrow = const AuthException(
      'email rate limit exceeded',
      statusCode: '429',
    );

    await tester.pumpWidget(MaterialApp(
      home: ForgotPasswordScreen(authService: mockAuth),
    ));

    await tester.enterText(find.byType(TextField), 'farmer@plantsense.org');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(
      find.text('Too many requests. Please wait a moment before trying again.'),
      findsOneWidget,
    );

    // Does NOT show false success view
    expect(find.text('Check Your Email'), findsNothing);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets('displays form view in Arabic when locale is ar', (tester) async {
    LocaleService.localeNotifier.value = const Locale('ar');
    await tester.pumpWidget(MaterialApp(
      home: ForgotPasswordScreen(authService: mockAuth),
    ));

    expect(find.text('استعادة كلمة المرور'), findsOneWidget);
    expect(find.text('إرسال رابط الاستعادة'), findsOneWidget);
  });
}
