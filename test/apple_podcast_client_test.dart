import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/podcast/services/apple_client.dart';

void main() {
  test('parses Apple search body when Dio returns a JSON string', () {
    final body = parseAppleSearchBody(
      jsonEncode({
        'resultCount': 1,
        'results': [
          {'collectionName': '红楼梦'},
        ],
      }),
    );

    expect(body['resultCount'], 1);
    expect(body['results'], isA<List>());
  });

  test('parses Apple search body when Dio returns a map', () {
    final body = parseAppleSearchBody({'resultCount': 0, 'results': const []});

    expect(body['resultCount'], 0);
    expect(body['results'], isEmpty);
  });
}
