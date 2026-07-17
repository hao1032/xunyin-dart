import 'package:flutter/foundation.dart';

/// 应用内统一的诊断日志接口。
///
/// 日志仅用于开发期排障，调用方不得传入请求正文、Cookie、授权信息或完整
/// 用户输入。Release 构建使用 [NoopAppLogger]，不会输出任何业务日志。
abstract interface class AppLogger {
  bool get isEnabled;

  void debug(String area, String event, {Map<String, Object?> data = const {}});

  void info(String area, String event, {Map<String, Object?> data = const {}});

  void warning(
    String area,
    String event, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  });

  void error(
    String area,
    String event, {
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  });
}

enum LogLevel { debug, info, warning, error }

/// Debug 构建默认使用的控制台日志实现。
class DebugAppLogger implements AppLogger {
  DebugAppLogger({void Function(String message)? output})
    : _output = output ?? debugPrint;

  final void Function(String message) _output;

  @override
  bool get isEnabled => true;

  @override
  void debug(
    String area,
    String event, {
    Map<String, Object?> data = const {},
  }) {
    _write(LogLevel.debug, area, event, data: data);
  }

  @override
  void info(String area, String event, {Map<String, Object?> data = const {}}) {
    _write(LogLevel.info, area, event, data: data);
  }

  @override
  void warning(
    String area,
    String event, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(LogLevel.warning, area, event, data: data, error: error);
    _writeStackTrace(stackTrace);
  }

  @override
  void error(
    String area,
    String event, {
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  }) {
    _write(LogLevel.error, area, event, data: data, error: error);
    _writeStackTrace(stackTrace);
  }

  void _write(
    LogLevel level,
    String area,
    String event, {
    required Map<String, Object?> data,
    Object? error,
  }) {
    final fields = <String>[
      ...data.entries
          .where((entry) => entry.value != null)
          .map(
            (entry) => '${entry.key}=${_safeValue(entry.key, entry.value!)}',
          ),
      if (error != null) 'error=${error.runtimeType}',
    ];
    _output(
      '[${level.name}][$area][$event]'
      '${fields.isEmpty ? '' : ' ${fields.join(' ')}'}',
    );
  }

  void _writeStackTrace(StackTrace? stackTrace) {
    if (stackTrace != null) _output(stackTrace.toString());
  }

  String _safeValue(String key, Object value) {
    final normalizedKey = key.toLowerCase();
    if (_sensitiveKeys.any(normalizedKey.contains)) return '<redacted>';
    if (value is Uri) return value.replace(query: '').toString();
    return value.toString();
  }
}

const _sensitiveKeys = <String>[
  'authorization',
  'cookie',
  'token',
  'signature',
  'w_rid',
  'keyword',
  'query',
  'url',
];

class NoopAppLogger implements AppLogger {
  const NoopAppLogger();

  @override
  bool get isEnabled => false;

  @override
  void debug(
    String area,
    String event, {
    Map<String, Object?> data = const {},
  }) {}

  @override
  void error(
    String area,
    String event, {
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  }) {}

  @override
  void info(
    String area,
    String event, {
    Map<String, Object?> data = const {},
  }) {}

  @override
  void warning(
    String area,
    String event, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

AppLogger createAppLogger() {
  return kDebugMode ? DebugAppLogger() : const NoopAppLogger();
}
