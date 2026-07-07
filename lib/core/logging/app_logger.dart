import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void userAction(
    String action, {
    String area = 'ui',
    Map<String, Object?> data = const {},
  }) {
    _write(area, action, 'user action', data: data);
  }

  static void result(
    String action, {
    required String area,
    String message = 'success',
    Map<String, Object?> data = const {},
  }) {
    _write(area, action, message, data: data);
  }

  static void failure(
    String action,
    Object error, {
    required String area,
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  }) {
    _write(area, action, 'failed: $error', data: data);
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static void _write(
    String area,
    String action,
    String message, {
    Map<String, Object?> data = const {},
  }) {
    final payload = data.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    debugPrint(
      '[Xunyin][$area][$action] $message${payload.isEmpty ? '' : ' | $payload'}',
    );
  }
}
