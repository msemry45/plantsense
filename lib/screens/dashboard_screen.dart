import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  final AuthService authService;
  final bool isGuest;

  const DashboardScreen(
      {super.key, required this.authService, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return _buildGuestDashboard(context);
    }

    final profile = authService.profile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (profile.role) {
      case 'farmer':
        return _buildFarmerDashboard(
            context, profile.fullName ?? profile.username);
      case 'admin':
        return _buildAdminDashboard(
            context, profile.fullName ?? profile.username);
      case 'viewer':
        return _buildViewerDashboard(
            context, profile.fullName ?? profile.username);
      default:
        return _buildDefaultDashboard(
            context, profile.fullName ?? profile.username);
    }
  }

  Widget _buildGuestDashboard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => context.go('/login'),
          )
        ],
      ),
      body: const Center(
        child: Text('Welcome Guest! You can browse the public Encyclopedia.'),
      ),
    );
  }

  Widget _buildFarmerDashboard(BuildContext context, String name) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      body: Center(
        child: Text('Welcome $name! Manage your plants and observations here.'),
      ),
    );
  }

  Widget _buildAdminDashboard(BuildContext context, String name) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome Admin $name! Manage users and encyclopedia.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/admin/users'),
              child: const Text('Manage Users'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerDashboard(BuildContext context, String name) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      body: Center(
        child: Text('Welcome $name! Read-only access to shared plants.'),
      ),
    );
  }

  Widget _buildDefaultDashboard(BuildContext context, String name) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      body: Center(
        child: Text('Welcome $name!'),
      ),
    );
  }
}
