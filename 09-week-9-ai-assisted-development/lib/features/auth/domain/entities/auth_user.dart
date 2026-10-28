/// Pure Dart entity representing an authenticated user.
/// Contains no JSON mapping or framework dependencies.
class AuthUser {
  const AuthUser({required this.email, this.accessToken});

  final String email;
  final String? accessToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          accessToken == other.accessToken;

  @override
  int get hashCode => email.hashCode ^ (accessToken?.hashCode ?? 0);
}
