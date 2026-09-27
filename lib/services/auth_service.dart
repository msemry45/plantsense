import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;
  UserProfile? _profile;
  bool _isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      _listenToProfile(_user!.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _user = session?.user;
      if (event == AuthChangeEvent.signedIn && _user != null) {
        _listenToProfile(_user!.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _profileSubscription?.cancel();
        _profile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _listenToProfile(String userId) {
    _profileSubscription?.cancel();
    _profileSubscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((data) {
      if (data.isNotEmpty) {
        _profile = UserProfile.fromJson(data.first);
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to profile: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(
      {required String email,
      required String password,
      required String username,
      required String fullName}) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'username': username},
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
