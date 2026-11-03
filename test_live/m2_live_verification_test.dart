import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotenv/dotenv.dart';

void main() {
  late String supabaseUrl;
  late String supabaseKey;
  late String serviceRoleKey;
  late String adminEmail;
  late String adminPassword;
  late String farmerEmail;
  late String farmerPassword;

  setUpAll(() {
    final env = DotEnv(includePlatformEnvironment: true)..load(['.env.test']);
    supabaseUrl = env['SUPABASE_URL']!;
    supabaseKey = env['SUPABASE_ANON_KEY']!;
    serviceRoleKey = env['SUPABASE_SERVICE_ROLE_KEY']!;
    adminEmail = env['TEST_ADMIN_EMAIL']!;
    adminPassword = env['TEST_ADMIN_PASSWORD']!;
    farmerEmail = env['TEST_FARMER_EMAIL']!;
    farmerPassword = env['TEST_FARMER_PASSWORD']!;
  });

  test('Live Test 1: Sign In and Sign Out with Farmer Account', () async {
    final client = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    final signInRes = await client.auth.signInWithPassword(
      email: farmerEmail,
      password: farmerPassword,
    );

    expect(signInRes.user, isNotNull);
    expect(signInRes.user?.email, farmerEmail);
    expect(client.auth.currentUser, isNotNull);

    await client.auth.signOut();
    expect(client.auth.currentUser, isNull);
  });

  test('Live Test 2: Sign In and Sign Out with Admin Account', () async {
    final client = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    final signInRes = await client.auth.signInWithPassword(
      email: adminEmail,
      password: adminPassword,
    );

    expect(signInRes.user, isNotNull);
    expect(signInRes.user?.email, adminEmail);
    expect(client.auth.currentUser, isNotNull);

    await client.auth.signOut();
    expect(client.auth.currentUser, isNull);
  });

  test(
      'Live Test 3: Admin Role Change, Account Suspension, Reactivation & Realtime Event Delivery',
      () async {
    final adminClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final userClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    await adminClient.auth.signInWithPassword(
      email: adminEmail,
      password: adminPassword,
    );
    final userSignIn = await userClient.auth.signInWithPassword(
      email: farmerEmail,
      password: farmerPassword,
    );
    final targetUserId = userSignIn.user!.id;

    final stream = userClient
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', targetUserId);

    final updateController = StreamController<Map<String, dynamic>>.broadcast();
    final subscription = stream.listen((data) {
      // ignore: avoid_print
      print('DEBUG: stream received ${data.length} records: $data');
      if (data.isNotEmpty) {
        updateController.add(data.first);
      }
    }, onError: (e) {
      // ignore: avoid_print
      print('DEBUG: stream error: $e');
    });

    try {
      // Wait for initial profile snapshot in Session B
      // ignore: avoid_print
      print('DEBUG: waiting for initial snapshot...');
      final initial = await updateController.stream.first.timeout(const Duration(seconds: 8));
      // ignore: avoid_print
      print('DEBUG: initial snapshot received: $initial');

      // Allow WebSocket subscription channel to complete join
      await Future.delayed(const Duration(seconds: 2));

      // Action 1: Admin changes role to 'viewer'
      // ignore: avoid_print
      print('DEBUG: admin updating role to viewer...');
      final res1 = await adminClient
          .from('profiles')
          .update({'role': 'viewer'}).eq('id', targetUserId).select();
      // ignore: avoid_print
      print('DEBUG: admin update returned: $res1');

      final eventRoleViewer = await updateController.stream
          .firstWhere((p) => p['role'] == 'viewer')
          .timeout(const Duration(seconds: 15));
      // ignore: avoid_print
      print('DEBUG: received viewer role event: $eventRoleViewer');
      expect(eventRoleViewer['role'], 'viewer');

      // Action 2: Admin suspends account
      await adminClient
          .from('profiles')
          .update({'status': 'suspended'}).eq('id', targetUserId);

      final eventSuspended = await updateController.stream
          .firstWhere((p) => p['status'] == 'suspended')
          .timeout(const Duration(seconds: 10));
      expect(eventSuspended['status'], 'suspended');

      // Action 3: Admin reactivates account
      await adminClient
          .from('profiles')
          .update({'status': 'active'}).eq('id', targetUserId);

      final eventActive = await updateController.stream
          .firstWhere((p) => p['status'] == 'active')
          .timeout(const Duration(seconds: 10));
      expect(eventActive['status'], 'active');
    } finally {
      // Guaranteed account state restoration even on assertion failure
      try {
        await adminClient.from('profiles').update({
          'role': 'farmer',
          'status': 'active',
        }).eq('id', targetUserId);
      } catch (e, st) {
        stderr.writeln('CRITICAL: Failed to restore user account state in finally block: $e\n$st');
        rethrow;
      }

      await subscription.cancel();
      await updateController.close();
      await adminClient.auth.signOut();
      await userClient.auth.signOut();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('Live Test 4: Public Registration and Duplicate Username Rejection (FR-AUTH-01)', () async {
    final client = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final adminServiceClient = SupabaseClient(
      supabaseUrl,
      serviceRoleKey,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final candidateUsername = 'user_$timestamp';
    final validEmail = 'valid_$timestamp@plantsense.org';
    final duplicateEmail = 'dup_$timestamp@plantsense.org';
    const password = 'Password123!';

    String? createdUserId;
    try {
      // Step 1: Prove that registering a valid, unique username succeeds via public signup
      try {
        final signUpRes = await client.auth.signUp(
          email: validEmail,
          password: password,
          data: {'username': candidateUsername, 'full_name': 'Valid User'},
        );

        expect(signUpRes.user, isNotNull, reason: 'Valid initial public registration must succeed');
        createdUserId = signUpRes.user?.id;
        expect(createdUserId, isNotNull);

        // Verify profile row was created with the exact lowercase username
        final createdProfile = await adminServiceClient
            .from('profiles')
            .select()
            .eq('id', createdUserId!)
            .single();
        expect(createdProfile['username'], candidateUsername);
      } on AuthException catch (e) {
        if (e.statusCode == '429' || e.message.toLowerCase().contains('rate limit')) {
          fail('Public registration rate-limited by Supabase hourly email quota (429: over_email_send_rate_limit).');
        }
        rethrow;
      }

      // Step 2: Attempt to register a SECOND user with the exact same username via public signup
      bool duplicateRejected = false;
      String? rejectionReason;
      try {
        await client.auth.signUp(
          email: duplicateEmail,
          password: password,
          data: {'username': candidateUsername, 'full_name': 'Duplicate User'},
        );
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        // Specifically check for uniqueness rejection; reject generic 'database error'
        if (msg.contains('already taken') ||
            msg.contains('unique') ||
            e.code == '23505' ||
            e.statusCode == '409') {
          duplicateRejected = true;
          rejectionReason = e.message;
        } else if (e.statusCode == '429' || msg.contains('rate limit')) {
          fail('Duplicate registration check rate-limited by Supabase hourly email quota (429: over_email_send_rate_limit).');
        } else {
          fail('Registration failed with unexpected error (not uniqueness rejection): ${e.message} (code: ${e.code}, status: ${e.statusCode})');
        }
      }

      expect(duplicateRejected, isTrue,
          reason: 'Duplicate username must be rejected with specific uniqueness error per FR-AUTH-01. Observed: $rejectionReason');
    } finally {
      // Step 3: Clean up newly created test account; failure MUST fail the test
      if (createdUserId != null) {
        try {
          await adminServiceClient.auth.admin.deleteUser(createdUserId);
        } catch (e, st) {
          stderr.writeln('CRITICAL: Failed to clean up test user $createdUserId: $e\n$st');
          rethrow;
        }
      }
    }
  });

  test('Live Test 5: Password Reset Request Endpoint Verification', () async {
    final client = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    try {
      await client.auth.resetPasswordForEmail(farmerEmail);
    } on AuthException catch (e) {
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        // Document unmasked rate-limit
        fail('Password reset rate-limited by Supabase hourly email quota (429: over_email_send_rate_limit).');
      }
      rethrow;
    }
  });
}
