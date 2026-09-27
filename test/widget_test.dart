import 'package:flutter_test/flutter_test.dart';
import 'package:plantsense/models/user_profile.dart';

void main() {
  test('UserProfile parses correctly from JSON', () {
    final json = {
      'id': '123-abc',
      'role': 'farmer',
      'status': 'active',
      'username': 'test_user',
      'full_name': 'Test User',
    };

    final profile = UserProfile.fromJson(json);

    expect(profile.id, '123-abc');
    expect(profile.role, 'farmer');
    expect(profile.status, 'active');
    expect(profile.username, 'test_user');
    expect(profile.fullName, 'Test User');
  });

  test('UserProfile handles missing full_name correctly', () {
    final json = {
      'id': '123-abc',
      'role': 'farmer',
      'status': 'active',
      'username': 'test_user',
    };

    final profile = UserProfile.fromJson(json);

    expect(profile.id, '123-abc');
    expect(profile.fullName, null);
  });
}
