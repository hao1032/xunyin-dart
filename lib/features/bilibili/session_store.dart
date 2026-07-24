import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/exceptions.dart';
import '../../core/logging/app_logger.dart';

enum BilibiliQrLoginState {
  waitingForScan,
  waitingForConfirm,
  succeeded,
  expired,
}

class BilibiliQrCode {
  const BilibiliQrCode({required this.url, required this.key});

  final String url;
  final String key;
}

class BilibiliQrLoginResult {
  const BilibiliQrLoginResult(this.state);

  final BilibiliQrLoginState state;

  bool get isTerminal =>
      state == BilibiliQrLoginState.succeeded ||
      state == BilibiliQrLoginState.expired;
}

class BilibiliSession {
  const BilibiliSession({required this.cookies, required this.updatedAt});

  final Map<String, String> cookies;
  final DateTime updatedAt;

  bool get isUsable => cookies['SESSDATA']?.isNotEmpty == true;
}

/// Persists the Bilibili web-login session in the application's private files.
/// The file contains sensitive, plain-text cookies and must never be logged.
class BilibiliSessionStore {
  BilibiliSessionStore(
    this._dio,
    this._logger, {
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const _sessionFileName = 'bilibili_session.json';
  static const _passportBaseUrl = 'https://passport.bilibili.com';
  static const _apiBaseUrl = 'https://api.bilibili.com';

  final Dio _dio;
  final AppLogger _logger;
  final Future<Directory> Function() _directoryProvider;
  BilibiliSession? _cachedSession;
  bool _loaded = false;

  Future<BilibiliQrCode> createQrCode() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_passportBaseUrl/x/passport-login/web/qrcode/generate',
      );
      final data = response.data?['data'];
      final url = data is Map ? data['url'] : null;
      final key = data is Map ? data['qrcode_key'] : null;
      if (url is! String || url.isEmpty || key is! String || key.isEmpty) {
        throw const FormatException('missing QR code data');
      }
      _logger.info('bilibili_session', 'qr_code_created');
      return BilibiliQrCode(url: url, key: key);
    } on DioException catch (error, stackTrace) {
      _logger.error(
        'bilibili_session',
        'qr_code_create_failed',
        error: error,
        stackTrace: stackTrace,
        data: {'status_code': error.response?.statusCode},
      );
      throw DataFetchException('B站登录二维码获取失败，请稍后重试', cause: error);
    } on FormatException catch (error, stackTrace) {
      _logger.error(
        'bilibili_session',
        'qr_code_invalid',
        error: error,
        stackTrace: stackTrace,
      );
      throw DataFetchException('B站登录二维码无效，请稍后重试', cause: error);
    }
  }

  Future<BilibiliQrLoginResult> pollQrCode(String key) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_passportBaseUrl/x/passport-login/web/qrcode/poll',
        queryParameters: {'qrcode_key': key},
      );
      final data = response.data?['data'];
      final code = data is Map ? data['code'] : null;
      switch (code) {
        case 86101:
          return const BilibiliQrLoginResult(
            BilibiliQrLoginState.waitingForScan,
          );
        case 86090:
          return const BilibiliQrLoginResult(
            BilibiliQrLoginState.waitingForConfirm,
          );
        case 86038:
          return const BilibiliQrLoginResult(BilibiliQrLoginState.expired);
        case 0:
          final cookies = _cookiesFromHeaders(response.headers);
          if (cookies['SESSDATA']?.isEmpty ?? true) {
            throw const FormatException('missing SESSDATA cookie');
          }
          await _save(
            BilibiliSession(cookies: cookies, updatedAt: DateTime.now()),
          );
          _logger.info('bilibili_session', 'login_succeeded');
          return const BilibiliQrLoginResult(BilibiliQrLoginState.succeeded);
        default:
          throw FormatException('unexpected QR login status: $code');
      }
    } on DioException catch (error, stackTrace) {
      _logger.error(
        'bilibili_session',
        'qr_code_poll_failed',
        error: error,
        stackTrace: stackTrace,
        data: {'status_code': error.response?.statusCode},
      );
      throw DataFetchException('B站登录状态获取失败，请稍后重试', cause: error);
    } on FormatException catch (error, stackTrace) {
      _logger.error(
        'bilibili_session',
        'qr_code_poll_invalid',
        error: error,
        stackTrace: stackTrace,
      );
      throw DataFetchException('B站登录状态无效，请重新获取二维码', cause: error);
    }
  }

  Future<BilibiliSession?> load() async {
    if (_loaded) return _cachedSession;
    _loaded = true;
    try {
      final file = await _sessionFile();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) throw const FormatException('session is not a map');
      final rawCookies = decoded['cookies'];
      if (rawCookies is! Map) {
        throw const FormatException('cookies are missing');
      }
      final cookies = <String, String>{
        for (final entry in rawCookies.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
      final rawUpdatedAt = decoded['updated_at'];
      final updatedAt = rawUpdatedAt is String
          ? DateTime.tryParse(rawUpdatedAt)
          : null;
      final session = BilibiliSession(
        cookies: cookies,
        updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
      if (!session.isUsable) throw const FormatException('SESSDATA is missing');
      _cachedSession = session;
      return session;
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'bilibili_session',
        'session_file_invalid',
        error: error,
        stackTrace: stackTrace,
      );
      await clear();
      return null;
    }
  }

  Future<bool> validate() async {
    final session = await load();
    if (session == null) return false;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiBaseUrl/x/web-interface/nav',
        options: Options(headers: {'Cookie': cookieHeader(session.cookies)}),
      );
      final isLogin = response.data?['data']?['isLogin'] == true;
      if (!isLogin) await clear();
      return isLogin;
    } on DioException catch (error, stackTrace) {
      _logger.warning(
        'bilibili_session',
        'session_validation_failed',
        error: error,
        stackTrace: stackTrace,
        data: {'status_code': error.response?.statusCode},
      );
      return false;
    }
  }

  Future<Map<String, String>> cookies() async =>
      Map.unmodifiable((await load())?.cookies ?? const <String, String>{});

  Future<void> clear() async {
    _cachedSession = null;
    _loaded = true;
    final file = await _sessionFile();
    if (await file.exists()) await file.delete();
    _logger.info('bilibili_session', 'session_cleared');
  }

  static String cookieHeader(Map<String, String> cookies) => cookies.entries
      .where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty)
      .map((entry) => '${entry.key}=${entry.value}')
      .join('; ');

  static Map<String, String> _cookiesFromHeaders(Headers headers) {
    final result = <String, String>{};
    for (final header in headers.map['set-cookie'] ?? const <String>[]) {
      final pair = header.split(';').first;
      final separator = pair.indexOf('=');
      if (separator <= 0) continue;
      final name = pair.substring(0, separator).trim();
      final value = pair.substring(separator + 1).trim();
      if (name.isNotEmpty && value.isNotEmpty) result[name] = value;
    }
    return result;
  }

  Future<void> _save(BilibiliSession session) async {
    final file = await _sessionFile();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'cookies': session.cookies,
        'updated_at': session.updatedAt.toUtc().toIso8601String(),
      }),
      flush: true,
    );
    await temporary.rename(file.path);
    _cachedSession = session;
    _loaded = true;
  }

  Future<File> _sessionFile() async =>
      File('${(await _directoryProvider()).path}/$_sessionFileName');
}
