import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/core/logging/app_logger.dart';
import 'package:xunyin_dart/features/bilibili/client.dart';
import 'package:xunyin_dart/features/bilibili/login_page.dart';
import 'package:xunyin_dart/features/bilibili/session_store.dart';
import 'package:xunyin_dart/features/podcast/client.dart';
import 'package:xunyin_dart/main.dart';

void main() {
  testWidgets('底部导航显示三个 Tab，并默认进入播放列表', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('播放列表'), findsWidgets);
    expect(find.text('发现'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();
    expect(find.text('发现'), findsWidgets);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('数据获取调试'), findsOneWidget);
    expect(find.text('B站登录'), findsOneWidget);
  });

  testWidgets('设置入口分别打开调试页和 B站登录页', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('数据获取调试'));
    await tester.pumpAndSettle();
    expect(find.byType(DataDebugPage), findsOneWidget);
    expect(find.text('B站登录'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'B站登录'));
    await tester.pumpAndSettle();
    expect(find.byType(BilibiliLoginPage), findsOneWidget);
  });
}

XunyinApp _app() {
  final dio = Dio();
  final logger = const NoopAppLogger();
  final sessionStore = BilibiliSessionStore(
    dio,
    logger,
    directoryProvider: () async => Directory.systemTemp,
  );
  return XunyinApp(
    bilibili: BilibiliClient(dio, logger, sessionStore: sessionStore),
    bilibiliSession: sessionStore,
    apple: ApplePodcastClient(dio, logger),
    rss: RssClient(dio, logger),
  );
}
