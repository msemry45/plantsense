import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/models/user_profile.dart';
import 'package:plantsense/router.dart';
import 'package:plantsense/services/auth_service.dart';
import 'package:plantsense/services/locale_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _user = User(
  id: 'account-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-10-20T00:00:00Z',
);

UserProfile _profile({
  String id = 'account-1',
  String role = 'admin',
  String status = 'active',
}) =>
    UserProfile(id: id, role: role, status: status, username: 'test-user');

class _AuthState extends ChangeNotifier implements AuthService {
  @override
  User? user;
  @override
  UserProfile? profile;
  @override
  bool isLoading;

  _AuthState({this.user, this.profile, this.isLoading = false});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    LocaleService.localeNotifier.value = const Locale('en');
  });

  tearDown(() {
    LocaleService.localeNotifier.value = const Locale('ar');
  });

  final cases = [
    (
      name: 'loading cannot render an admin deep link',
      auth: _AuthState(user: _user, profile: _profile(), isLoading: true),
      path: '/admin/users',
      expected: '/splash',
    ),
    (
      name: 'a missing profile cannot enter the admin screen',
      auth: _AuthState(user: _user),
      path: '/admin/users',
      expected: '/splash',
    ),
    (
      name: 'a profile from a different account cannot grant admin access',
      auth: _AuthState(user: _user, profile: _profile(id: 'other-account')),
      path: '/admin/users',
      expected: '/splash',
    ),
    (
      name: 'an unknown role cannot enter protected routes',
      auth: _AuthState(user: _user, profile: _profile(role: 'unknown')),
      path: '/',
      expected: '/splash',
    ),
    (
      name: 'an unknown account status cannot enter protected routes',
      auth: _AuthState(user: _user, profile: _profile(status: 'unknown')),
      path: '/',
      expected: '/splash',
    ),
    for (final role in ['farmer', 'viewer'])
      (
        name: '$role cannot enter the admin screen',
        auth: _AuthState(user: _user, profile: _profile(role: role)),
        path: '/admin/users',
        expected: '/',
      ),
    (
      name: 'an active admin can enter the admin screen',
      auth: _AuthState(user: _user, profile: _profile()),
      path: '/admin/users',
      expected: '/admin/users',
    ),
    (
      name: 'a suspended admin cannot enter the admin screen',
      auth: _AuthState(user: _user, profile: _profile(status: 'suspended')),
      path: '/admin/users',
      expected: '/suspended',
    ),
    (
      name: 'a guest cannot enter protected routes',
      auth: _AuthState(),
      path: '/admin/users',
      expected: '/login',
    ),
    (
      name: 'a guest can use the public guest route',
      auth: _AuthState(),
      path: '/guest',
      expected: '/guest',
    ),
    (
      name: 'an active account leaves the suspended screen',
      auth: _AuthState(user: _user, profile: _profile()),
      path: '/suspended',
      expected: '/',
    ),
    (
      name: 'a guest can access the forgot-password route',
      auth: _AuthState(),
      path: '/forgot-password',
      expected: '/forgot-password',
    ),
    (
      name: 'an active account on forgot-password is redirected home',
      auth: _AuthState(user: _user, profile: _profile()),
      path: '/forgot-password',
      expected: '/',
    ),
  ];

  for (final scenario in cases) {
    testWidgets(scenario.name, (tester) async {
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (value) {
        context = value;
        return const SizedBox.shrink();
      }));
      final router = createRouter(scenario.auth);
      addTearDown(router.dispose);
      addTearDown(scenario.auth.dispose);

      final result = await router.configuration.redirect(
        context,
        router.configuration.findMatch(scenario.path),
        redirectHistory: [],
      );

      expect(result.error, isNull);
      expect(result.uri.path, scenario.expected);
    });
  }

  testWidgets('profile failure shows recovery actions instead of admin data',
      (tester) async {
    final auth = _AuthState(user: _user);
    final router = createRouter(auth);
    addTearDown(router.dispose);
    addTearDown(auth.dispose);
    router.go('/admin/users');

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Unable to verify your account'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Manage Users'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile failure shows recovery actions in Arabic when locale is ar',
      (tester) async {
    LocaleService.localeNotifier.value = const Locale('ar');
    final auth = _AuthState(user: _user);
    final router = createRouter(auth);
    addTearDown(router.dispose);
    addTearDown(auth.dispose);
    router.go('/admin/users');

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('تعذر التحقق من الحساب'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.text('Manage Users'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
