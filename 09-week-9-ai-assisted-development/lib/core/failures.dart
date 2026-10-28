/// Base Failure class for domain layer error representation.
/// Pure Dart — no Flutter or third-party framework dependencies.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}
