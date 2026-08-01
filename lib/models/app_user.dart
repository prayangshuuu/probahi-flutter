/// The `data.user` payload returned by allauth headless (see REST_API.md
/// §2.3). Note this is the *only* user data the API currently exposes —
/// there is no endpoint for `full_name` or an instructor profile.
class AppUser {
  const AppUser({
    required this.id,
    required this.display,
    required this.hasUsablePassword,
    this.email,
  });

  final int id;
  final String display;
  final bool hasUsablePassword;
  final String? email;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      display: (json['display'] ?? json['email'] ?? '').toString(),
      hasUsablePassword: json['has_usable_password'] as bool? ?? false,
      email: json['email'] as String?,
    );
  }

  String get initial => display.isNotEmpty ? display[0].toUpperCase() : '?';
}
