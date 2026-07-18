class DataFetchException implements Exception {
  const DataFetchException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
