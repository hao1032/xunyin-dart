import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/app_logger.dart';
import 'core/logging/logger_provider.dart';

void main() {
  final logger = createAppLogger();
  _installGlobalErrorLogging(logger);
  runApp(
    ProviderScope(
      overrides: [appLoggerProvider.overrideWithValue(logger)],
      child: const XunyinApp(),
    ),
  );
}

void _installGlobalErrorLogging(AppLogger logger) {
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    logger.error(
      'ui',
      'flutter_error',
      error: details.exception,
      stackTrace: details.stack,
      data: {'library': details.library},
    );
    previousOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error(
      'app',
      'uncaught_async_error',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  };
}

class XunyinApp extends StatelessWidget {
  const XunyinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('数据源调试页面尚未实现'))),
    );
  }
}
