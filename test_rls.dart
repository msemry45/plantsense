import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    stderr.writeln('Missing Supabase credentials in .env');
    exit(1);
  }

  final client = SupabaseClient(
    supabaseUrl,
    supabaseKey,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  // 1. Create a dummy user
  final email =
      'testuser_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}@example.com';
  const password = 'password123';

  stdout.writeln('Creating test user: $email...');
  final AuthResponse authRes = await client.auth.signUp(
    email: email,
    password: password,
    data: {'username': 'testrls', 'full_name': 'Test RLS'},
  );

  final user = authRes.user;
  if (user == null) {
    stderr.writeln('Failed to create user');
    exit(1);
  }

  stdout.writeln('User created successfully. ID: ${user.id}');

  // 2. Fetch profile to ensure it's created and role is 'farmer' (default)
  try {
    final profile =
        await client.from('profiles').select().eq('id', user.id).single();
    stdout.writeln('Initial profile: $profile');
    if (profile['role'] != 'farmer') {
      stdout.writeln('WARNING: Default role is not farmer');
    }
  } catch (e) {
    stderr.writeln('Could not fetch profile: $e');
  }

  // 3. Attempt to escalate privileges to 'admin'
  stdout.writeln('Attempting to escalate privileges to admin...');
  try {
    await client.from('profiles').update({'role': 'admin'}).eq('id', user.id);
    stderr.writeln(
        'ERROR: Update succeeded! RLS or trigger failed to block the update.');
    exit(1);
  } catch (e) {
    stdout.writeln('SUCCESS: Update was blocked as expected. Error: $e');
  }

  // Clean up
  await client.auth.signOut();
  stdout.writeln('RLS Test Completed.');
  exit(0);
}
