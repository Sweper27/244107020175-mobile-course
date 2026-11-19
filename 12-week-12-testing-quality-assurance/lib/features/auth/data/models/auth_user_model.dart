import '../../domain/entities/auth_user.dart';

/// Data model for AuthUser containing serialization and entity mapping logic.
class AuthUserModel extends AuthUser {
  const AuthUserModel({required super.email, super.accessToken});

  factory AuthUserModel.fromMap(Map<String, dynamic> map) {
    return AuthUserModel(
      email: map['email'] as String? ?? '',
      accessToken: map['access_token'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {'email': email, 'access_token': accessToken};

  AuthUser toEntity() => AuthUser(email: email, accessToken: accessToken);
}
