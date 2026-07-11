class AppError implements Exception {
  const AppError(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => code == null ? message : '$message ($code)';
}

class BilibiliUnavailableException extends AppError {
  const BilibiliUnavailableException(super.message, {super.code, super.cause});
}
