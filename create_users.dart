import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://tpsguqbyqlvsxrshwcks.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRwc2d1cWJ5cWx2c3hyc2h3Y2tzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0NjkzMjYsImV4cCI6MjEwNjA0NTMyNn0.o3OZuatIiUlcdbdxCC7KUVwOvpOeNEH3geKU4LFKl-4',
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  try {
    // Admin
    await client.auth.signUp(
      email: 'manager@test.com',
      password: 'password123',
      data: {'username': 'Manager', 'full_name': 'Manager Admin'},
    );
    print('Manager created');
  } catch (e) {
    print('Manager error: $e');
  }

  try {
    // Farmer
    await client.auth.signUp(
      email: 'user1@test.com',
      password: 'password123',
      data: {'username': 'User1', 'full_name': 'User One'},
    );
    print('User created');
  } catch (e) {
    print('User error: $e');
  }
}
