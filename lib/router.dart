import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/suspended_screen.dart';
import 'screens/admin_users_screen.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authService,
    redirect: (context, state) {
      if (authService.isLoading) return null;

      final bool loggedIn = authService.user != null;
      final profile = authService.profile;
      final String path = state.matchedLocation;

      final bool isAuthRoute = path == '/login' || path == '/register';
      final bool isGuestRoute = path == '/guest';

      if (!loggedIn) {
        if (isAuthRoute || isGuestRoute) return null;
        return '/login';
      }

      if (profile != null) {
        if (profile.status == 'suspended') {
          if (path != '/suspended') return '/suspended';
          return null;
        }

        if (path == '/suspended') {
          return '/';
        }
        
        // Example: Only admins can go to /admin paths, etc.
        // If we add an admin section, we check it here:
        // if (path.startsWith('/admin') && profile.role != 'admin') return '/';
      }

      if (loggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => DashboardScreen(authService: authService),
      ),
      GoRoute(
        path: '/guest',
        builder: (context, state) => DashboardScreen(authService: authService, isGuest: true),
      ),
      GoRoute(
        path: '/suspended',
        builder: (context, state) => SuspendedScreen(authService: authService),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(authService: authService),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(authService: authService),
      ),
    ],
  );
}
