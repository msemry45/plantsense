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

  stdout.writeln('Creating default seed accounts if they do not exist...');

  try {
    // Admin
    await client.auth.signUp(
      email: 'manager@test.com',
      password: 'password123',
      data: {'username': 'Manager', 'full_name': 'Manager Admin'},
    );
    stdout.writeln('Manager created');
  } catch (e) {
    stderr.writeln('Manager error: $e');
  }

  try {
    // Farmer
    await client.auth.signUp(
      email: 'user1@test.com',
      password: 'password123',
      data: {'username': 'User1', 'full_name': 'User One'},
    );
    stdout.writeln('User created');
  } catch (e) {
    stderr.writeln('User error: $e');
  }
}
