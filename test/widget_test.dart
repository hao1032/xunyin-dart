import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xunyin_dart/core/app.dart';

void main() {
  testWidgets('home tabs include search with B站 as the default source', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: XunyinApp()));

    expect(find.text('播放列表'), findsAtLeastNWidgets(1));
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    await tester.tap(find.text('搜索'));
    await tester.pumpAndSettle();

    expect(find.text('输入关键词开始搜索'), findsOneWidget);
    expect(find.text('B站'), findsOneWidget);
    expect(find.text('播客'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
  });
}
