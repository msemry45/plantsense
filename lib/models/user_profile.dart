class UserProfile {
  final String id;
  final String role;
  final String status;
  final String username;
  final String? fullName;

  UserProfile({
    required this.id,
    required this.role,
    required this.status,
    required this.username,
    this.fullName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
    );
  }
}
