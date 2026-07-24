import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/core/logging/app_logger.dart';
import 'package:xunyin_dart/features/bilibili/client.dart';
import 'package:xunyin_dart/features/bilibili/session_store.dart';

void main() {
  test('二维码登录保存并还原 Cookie 文件', () async {
    final directory = await Directory.systemTemp.createTemp('xunyin_session_');
    addTearDown(() => directory.delete(recursive: true));
    final dio = Dio()..httpClientAdapter = _SessionAdapter();
    final store = BilibiliSessionStore(
      dio,
      const NoopAppLogger(),
      directoryProvider: () async => directory,
    );

    final qrCode = await store.createQrCode();
    expect(qrCode.url, 'https://passport.bilibili.com/h5-app/passport/login');

    final pending = await store.pollQrCode(qrCode.key);
    expect(pending.state, BilibiliQrLoginState.waitingForScan);

    final succeeded = await store.pollQrCode(qrCode.key);
    expect(succeeded.state, BilibiliQrLoginState.succeeded);
    expect(await store.cookies(), {
      'SESSDATA': 'session-value',
      'bili_jct': 'csrf-value',
      'DedeUserID': '42',
    });
    expect(
      BilibiliSessionStore.cookieHeader(await store.cookies()),
      contains('SESSDATA=session-value'),
    );

    final file = File('${directory.path}/bilibili_session.json');
    final body = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(body['cookies'], isA<Map>());
    expect(body['cookies']['SESSDATA'], 'session-value');

    final reloaded = BilibiliSessionStore(
      dio,
      const NoopAppLogger(),
      directoryProvider: () async => directory,
    );
    expect((await reloaded.load())?.cookies['DedeUserID'], '42');
    await reloaded.clear();
    expect(await file.exists(), isFalse);
  });

  test('损坏的会话文件会被清除', () async {
    final directory = await Directory.systemTemp.createTemp('xunyin_session_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/bilibili_session.json');
    await file.writeAsString('not json');
    final store = BilibiliSessionStore(
      Dio(),
      const NoopAppLogger(),
      directoryProvider: () async => directory,
    );

    expect(await store.load(), isNull);
    expect(await file.exists(), isFalse);
  });

  test('B站请求合并匿名和已登录 Cookie，且日志不泄露会话', () async {
    final directory = await Directory.systemTemp.createTemp('xunyin_session_');
    addTearDown(() => directory.delete(recursive: true));
    final adapter = _SessionAdapter();
    final messages = <String>[];
    final dio = Dio()..httpClientAdapter = adapter;
    final store = BilibiliSessionStore(
      dio,
      DebugAppLogger(output: messages.add),
      directoryProvider: () async => directory,
    );
    await store.pollQrCode('key');
    await store.pollQrCode('key');
    final client = BilibiliClient(
      dio,
      DebugAppLogger(output: messages.add),
      sessionStore: store,
    );

    await client.searchVideos('测试');

    final cookie = adapter.searchCookie;
    expect(cookie, contains('SESSDATA=session-value'));
    expect(cookie, contains('buvid3=anonymous-3'));
    expect(messages.join('\n'), isNot(contains('session-value')));
  });
}

class _SessionAdapter implements HttpClientAdapter {
  int _pollCalls = 0;
  String? searchCookie;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path.endsWith('/qrcode/generate')) {
      return _json({
        'code': 0,
        'data': {
          'url': 'https://passport.bilibili.com/h5-app/passport/login',
          'qrcode_key': 'key',
        },
      });
    }
    if (path.endsWith('/qrcode/poll')) {
      _pollCalls += 1;
      if (_pollCalls == 1) {
        return _json({
          'code': 0,
          'data': {'code': 86101},
        });
      }
      return _json(
        {
          'code': 0,
          'data': {'code': 0},
        },
        headers: {
          'set-cookie': [
            'SESSDATA=session-value; Path=/; HttpOnly',
            'bili_jct=csrf-value; Path=/',
            'DedeUserID=42; Path=/',
          ],
        },
      );
    }
    if (path.endsWith('/finger/spi')) {
      return _json({
        'code': 0,
        'data': {'b_3': 'anonymous-3', 'b_4': 'anonymous-4'},
      });
    }
    if (path.endsWith('/search/type')) {
      searchCookie = options.headers['Cookie'] as String?;
      return _json({
        'code': 0,
        'data': {'result': []},
      });
    }
    throw StateError('unexpected request: $path');
  }

  ResponseBody _json(
    Map<String, Object?> value, {
    Map<String, List<String>>? headers,
  }) {
    return ResponseBody.fromString(
      jsonEncode(value),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...?headers,
      },
    );
  }
}
