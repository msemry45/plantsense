import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase;

  User? _user;
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isPasswordRecovery = false;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

  User? get user => _user;
  UserProfile? get profile => _profile;
  UserProfile? get currentUserProfile => _profile;
  bool get isLoading => _isLoading;
  bool get isPasswordRecovery => _isPasswordRecovery;

  AuthService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client {
    _init();
  }

  void _init() {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      _listenToProfile(_user!.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      final previousUserId = _user?.id;
      _user = session?.user;
      if (event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      }
      if (_user == null) {
        _profileSubscription?.cancel();
        _profileSubscription = null;
        _profileUnavailable();
      } else if (event == AuthChangeEvent.signedIn ||
          previousUserId != _user!.id) {
        _listenToProfile(_user!.id);
      }
    }, onError: (Object error) {
      _profileSubscription?.cancel();
      _profileSubscription = null;
      _profileUnavailable();
    });
  }

  void _listenToProfile(String userId) {
    _profileSubscription?.cancel();
    _profile = null;
    _isLoading = true;
    notifyListeners();
    _profileSubscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((data) {
          if (_user?.id != userId) return;
          try {
            _profile =
                data.length == 1 ? UserProfile.fromJson(data.single) : null;
          } catch (_) {
            _profile = null;
          }
          _isLoading = false;
          notifyListeners();
        }, onError: (Object error) {
          if (_user?.id == userId) _profileUnavailable();
        }, onDone: () {
          if (_user?.id == userId) _profileUnavailable();
        });
  }

  void _profileUnavailable() {
    _profile = null;
    _isLoading = false;
    notifyListeners();
  }

  void retryProfile() {
    final userId = _user?.id;
    if (userId != null) _listenToProfile(userId);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'plantsense://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signUp(
      {required String email,
      required String password,
      required String username,
      required String fullName}) async {
    try {
      // 1. Attempt server-side admin user creation via Edge Function
      // to bypass Supabase Auth SMTP email rate limits (429) and auto-confirm email.
      final response = await _supabase.functions.invoke(
        'analyze-plant-image',
        body: {
          'action': 'register_user',
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
          'username': username.trim().toLowerCase(),
          'full_name': fullName.trim(),
        },
      );

      final data = response.data;
      if (response.status >= 400 || (data is Map && data['error'] != null)) {
        final errorMsg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'Registration failed';
        throw AuthException(errorMsg, statusCode: response.status.toString());
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      // 2. Fallback to standard Supabase auth signUp if edge functions are
      // unavailable or running under Fake/Mock clients in unit tests.
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': username},
      );
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    _isPasswordRecovery = false;
    notifyListeners();
  }
}
