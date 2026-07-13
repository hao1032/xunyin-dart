import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xunyin_dart/core/app.dart';

void main() {
  testWidgets('home shell exposes play, discovery and settings', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: XunyinApp()));

    expect(find.text('播放列表'), findsAtLeastNWidgets(1));
    expect(find.text('发现'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();

    expect(find.text('找到值得听的声音'), findsOneWidget);
    expect(find.text('B站合集'), findsOneWidget);
    expect(find.text('B站UP主'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(find.text('RSS播客'), findsOneWidget);
    expect(find.text('B站'), findsOneWidget);
    expect(find.text('播客'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
  });
}
