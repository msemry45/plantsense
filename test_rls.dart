import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    print('Missing Supabase credentials in .env');
    exit(1);
  }

  final client = SupabaseClient(
    supabaseUrl, 
    supabaseKey,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  // 1. Create a dummy user
  final email = 'testuser_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}@example.com';
  final password = 'password123';

  print('Creating test user: $email...');
  final AuthResponse authRes = await client.auth.signUp(
    email: email,
    password: password,
    data: {'username': 'testrls', 'full_name': 'Test RLS'},
  );

  final user = authRes.user;
  if (user == null) {
    print('Failed to create user');
    exit(1);
  }

  print('User created successfully. ID: ${user.id}');

  // 2. Fetch profile to ensure it's created and role is 'farmer' (default)
  try {
    final profile = await client.from('profiles').select().eq('id', user.id).single();
    print('Initial profile: $profile');
    if (profile['role'] != 'farmer') {
      print('WARNING: Default role is not farmer');
    }
  } catch (e) {
    print('Could not fetch profile: $e');
  }

  // 3. Attempt to escalate privileges to 'admin'
  print('Attempting to escalate privileges to admin...');
  try {
    await client.from('profiles').update({'role': 'admin'}).eq('id', user.id);
    print('ERROR: Update succeeded! RLS or trigger failed to block the update.');
    exit(1);
  } catch (e) {
    print('SUCCESS: Update was blocked as expected. Error: $e');
  }

  // Clean up (optional, might need service role key to delete users, so we just leave it or sign out)
  await client.auth.signOut();
  print('RLS Test Completed.');
  exit(0);
}
