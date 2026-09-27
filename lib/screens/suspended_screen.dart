import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SuspendedScreen extends StatelessWidget {
  final AuthService authService;

  const SuspendedScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Suspended')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Your account has been suspended.\nPlease contact the administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => authService.signOut(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
