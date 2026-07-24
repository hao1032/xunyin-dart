import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/core/http_client.dart';
import 'package:xunyin_dart/core/logging/app_logger.dart';

void main() {
  test('共享 HTTP 客户端配置请求超时', () {
    final options = createHttpClient(const NoopAppLogger()).options;

    expect(options.connectTimeout, const Duration(seconds: 15));
    expect(options.sendTimeout, const Duration(seconds: 15));
    expect(options.receiveTimeout, const Duration(seconds: 15));
  });

  test('Debug logger 输出等级、上下文和异常堆栈', () {
    final messages = <String>[];
    final logger = DebugAppLogger(output: messages.add);
    final stackTrace = StackTrace.current;

    logger.error(
      'rss',
      'parse_failed',
      error: const FormatException('invalid XML'),
      stackTrace: stackTrace,
      data: {'status_code': 200},
    );

    expect(
      messages.first,
      '[error][rss][parse_failed] status_code=200 error=FormatException',
    );
    expect(messages.last, contains('app_logger_test.dart'));
  });

  test('Noop logger 不输出日志', () {
    const logger = NoopAppLogger();

    expect(logger.isEnabled, isFalse);
    logger.error('rss', 'parse_failed', error: StateError('bad feed'));
  });

  test('HTTP 日志不包含敏感请求头、查询参数和响应正文', () async {
    final messages = <String>[];
    final dio = createHttpClient(DebugAppLogger(output: messages.add));
    dio.httpClientAdapter = _SuccessAdapter();

    await dio.get(
      'https://example.test/feed?token=secret&keyword=private',
      options: Options(
        headers: {'Authorization': 'Bearer secret', 'Cookie': 'a=b'},
      ),
    );

    final output = messages.join('\n');
    expect(output, contains('host=example.test'));
    expect(output, contains('path=/feed'));
    expect(output, isNot(contains('secret')));
    expect(output, isNot(contains('private')));
    expect(output, isNot(contains('response-body')));
  });
}

class _SuccessAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('response-body', 200);
  }
}
