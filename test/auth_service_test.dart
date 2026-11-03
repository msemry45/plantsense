import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-10-20T00:00:00Z',
    );

class _AuthClient extends Fake implements GoTrueClient {
  @override
  User? currentUser = _user('account-1');
  final events = StreamController<AuthState>.broadcast(sync: true);

  @override
  Stream<AuthState> get onAuthStateChange => events.stream;

  void signInAs(String id) {
    currentUser = _user(id);
    events.add(AuthState(
      AuthChangeEvent.signedIn,
      Session(
          accessToken: 'test-token', tokenType: 'bearer', user: currentUser!),
    ));
  }
}

class _ProfileStream extends Fake implements SupabaseStreamFilterBuilder {
  final StreamController<List<Map<String, dynamic>>> controller;

  _ProfileStream(this.controller);

  @override
  SupabaseStreamBuilder eq(String column, Object value) {
    if (column != 'id' || value != 'account-1' && value != 'account-2') {
      throw StateError('Unexpected profile filter');
    }
    return this;
  }

  @override
  StreamSubscription<List<Map<String, dynamic>>> listen(
    void Function(List<Map<String, dynamic>>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

class _ProfileQuery extends Fake implements SupabaseQueryBuilder {
  final _ProfileStream updates;

  _ProfileQuery(this.updates);

  @override
  SupabaseStreamFilterBuilder stream({required List<String> primaryKey}) {
    if (primaryKey.single != 'id') throw StateError('Unexpected primary key');
    return updates;
  }
}

class _Client extends Fake implements SupabaseClient {
  @override
  final _AuthClient auth = _AuthClient();
  final profiles =
      StreamController<List<Map<String, dynamic>>>.broadcast(sync: true);

  @override
  SupabaseQueryBuilder from(String table) {
    if (table != 'profiles') throw StateError('Unexpected table');
    return _ProfileQuery(_ProfileStream(profiles));
  }

  void publishAdmin() => profiles.add([
        {
          'id': 'account-1',
          'role': 'admin',
          'status': 'active',
          'username': 'test-admin',
        }
      ]);
}

void main() {
  late _Client client;
  late AuthService service;
  late bool disposed;

  setUp(() {
    client = _Client();
    service = AuthService(client: client);
    disposed = false;
    client.publishAdmin();
    expect(service.profile?.role, 'admin');
  });

  tearDown(() async {
    if (!disposed) service.dispose();
    await client.profiles.close();
    await client.auth.events.close();
  });

  test('switching accounts clears previous admin access while loading', () {
    client.auth.signInAs('account-2');

    expect(service.user?.id, 'account-2');
    expect(service.profile, isNull);
    expect(service.isLoading, isTrue);
  });

  test('a profile stream error revokes cached admin access', () {
    client.profiles.addError(StateError('connection lost'));

    expect(service.profile, isNull);
    expect(service.isLoading, isFalse);
  });

  test('a missing profile row revokes cached admin access', () {
    client.profiles.add([]);

    expect(service.profile, isNull);
    expect(service.isLoading, isFalse);
  });

  test('malformed profile data cannot leave cached admin access', () {
    client.profiles.add([
      {'id': 'account-1'}
    ]);

    expect(service.profile, isNull);
    expect(service.isLoading, isFalse);
  });

  test('disposing authentication releases both subscriptions', () {
    service.dispose();
    disposed = true;
    expect(client.auth.events.hasListener, isFalse);
    expect(client.profiles.hasListener, isFalse);
  });
}
