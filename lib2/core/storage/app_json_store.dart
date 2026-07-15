import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../app_logger.dart';

final appJsonStoreProvider = Provider<AppJsonStore>((ref) => AppJsonStore());

class AppJsonStore {
  const AppJsonStore();

  Future<Map<String, Object?>> readObject(
    String fileName, {
    Map<String, Object?> fallback = const {},
  }) async {
    final file = await _file(fileName);
    if (!await file.exists()) {
      AppLogger.result(
        'json_read',
        area: 'storage',
        message: 'missing',
        data: {'file': file.path},
      );
      return fallback;
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return fallback;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        AppLogger.result(
          'json_read',
          area: 'storage',
          data: {'file': file.path},
        );
        return decoded.cast<String, Object?>();
      }
      AppLogger.result(
        'json_read',
        area: 'storage',
        message: 'invalid_root',
        data: {'file': file.path},
      );
      return fallback;
    } catch (error, stackTrace) {
      AppLogger.failure(
        'json_read',
        error,
        area: 'storage',
        stackTrace: stackTrace,
        data: {'file': file.path},
      );
      return fallback;
    }
  }

  Future<void> writeObject(String fileName, Map<String, Object?> data) async {
    final file = await _file(fileName);
    final temp = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    const encoder = JsonEncoder.withIndent('  ');
    await temp.writeAsString('${encoder.convert(data)}\n', flush: true);
    await temp.rename(file.path);
    AppLogger.result(
      'json_write',
      area: 'storage',
      data: {'file': file.path, 'bytes': await file.length()},
    );
  }

  Future<File> _file(String fileName) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/data');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}/$fileName');
  }
}
