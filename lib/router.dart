import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'models/plant_image.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/suspended_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/encyclopedia/encyclopedia_screen.dart';
import 'screens/admin/admin_species_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/plants/plants_list_screen.dart';
import 'screens/plants/plant_form_screen.dart';
import 'screens/plants/plant_details_screen.dart';
import 'screens/plants/image_preview_screen.dart';
import 'screens/plants/plant_images_timeline_screen.dart';
import 'screens/plants/plant_image_compare_screen.dart';
import 'screens/plants/plant_notes_screen.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authService,
    redirect: (context, state) {
      final bool loggedIn = authService.user != null;
      final profile = authService.profile;
      final String path = state.matchedLocation;

      if (authService.isLoading) {
        return path == '/splash' ? null : '/splash';
      }

      final bool isAuthRoute = path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path == '/reset-password';
      final bool isGuestRoute = path == '/guest' || path == '/encyclopedia';

      if (authService.isPasswordRecovery && path != '/reset-password') {
        return '/reset-password';
      }

      if (!loggedIn) {
        if (isAuthRoute || isGuestRoute) return null;
        return '/login';
      }

      if (path == '/reset-password') {
        return null;
      }

      if (profile == null ||
          profile.id != authService.user!.id ||
          !['admin', 'farmer', 'viewer'].contains(profile.role) ||
          !['active', 'suspended'].contains(profile.status)) {
        return path == '/splash' ? null : '/splash';
      }

      if (profile.status == 'suspended') {
        return path == '/suspended' ? null : '/suspended';
      }

      if (path.startsWith('/admin') && profile.role != 'admin') return '/';

      if (path == '/splash' || path == '/suspended' || isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(authService: authService),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => DashboardScreen(authService: authService),
      ),
      GoRoute(
        path: '/guest',
        builder: (context, state) =>
            DashboardScreen(authService: authService, isGuest: true),
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
        path: '/admin/species',
        builder: (context, state) => const AdminSpeciesScreen(),
      ),
      GoRoute(
        path: '/encyclopedia',
        builder: (context, state) => EncyclopediaScreen(
          isGuest: authService.user == null,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => AnalyticsScreen(
          isViewer: authService.profile?.role == 'viewer',
        ),
      ),
      GoRoute(
        path: '/plants',
        builder: (context, state) => PlantsListScreen(authService: authService),
      ),
      GoRoute(
        path: '/plants/new',
        builder: (context, state) => const PlantFormScreen(),
      ),
      GoRoute(
        path: '/plants/:id',
        builder: (context, state) => PlantDetailsScreen(
          plantId: state.pathParameters['id']!,
          authService: authService,
        ),
      ),
      GoRoute(
        path: '/plants/:id/edit',
        builder: (context, state) => PlantFormScreen(
          plantId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/plants/:id/images',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final plantName = extra?['plantName'] as String? ?? 'Plant';
          return PlantImagesTimelineScreen(
            plantId: state.pathParameters['id']!,
            plantName: plantName,
          );
        },
      ),
      GoRoute(
        path: '/plants/:id/image-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final plantName = extra?['plantName'] as String? ?? 'Plant';
          return ImagePreviewScreen(
            plantId: state.pathParameters['id']!,
            plantName: plantName,
          );
        },
      ),
      GoRoute(
        path: '/plants/:id/compare',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PlantImageCompareScreen(
            plantName: extra['plantName'] as String,
            leftImage: extra['leftImage'] as PlantImage,
            rightImage: extra['rightImage'] as PlantImage,
          );
        },
      ),
      GoRoute(
        path: '/plants/:id/notes',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final plantName = extra?['plantName'] as String? ?? 'Plant';
          return PlantNotesScreen(
            plantId: state.pathParameters['id']!,
            plantName: plantName,
            authService: authService,
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(authService: authService),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(authService: authService),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            ForgotPasswordScreen(authService: authService),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(authService: authService),
      ),
    ],
  );
}
