import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/bilibili/services/client.dart';
import 'package:xunyin_dart/features/bilibili/services/repository.dart';
import 'package:xunyin_dart/features/series/model.dart';
import 'package:xunyin_dart/features/episode/model.dart';
import 'package:xunyin_dart/features/search/model.dart';

void main() {
  test('marks B站 search rows without bvid as unavailable', () async {
    final repository = BilibiliRepository(
      _FakeBilibiliClient(
        rows: [
          {
            'bvid': '',
            'aid': '',
            'title': '细品<em class="keyword">红楼梦</em>',
            'author': 'Alice',
          },
        ],
      ),
    );

    final results = await repository.search('红楼梦');

    expect(results, hasLength(1));
    expect(results.single.bvid, isNull);
    expect(results.single.title, '细品红楼梦');
    expect(results.single.bilibiliKind, BilibiliResultKind.unavailable);
  });

  test('rejects B站 result with blank bvid before requesting detail', () async {
    final repository = BilibiliRepository(_FakeBilibiliClient());

    await expectLater(
      repository.resolveAsSeries(
        const SearchResult(
          id: '',
          title: '细品红楼梦',
          sourceType: SourceType.bilibili,
          originalUrl: '',
          bvid: '',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('converts multipart B站 videos into a Series', () async {
    final repository = BilibiliRepository(
      _FakeBilibiliClient(
        detail: {
          'bvid': 'BV1xx411c7mD',
          'aid': 1,
          'title': 'Long Talk',
          'pic': '//i0.hdslb.com/cover.jpg',
          'owner': {'name': 'Alice', 'mid': 42},
          'pages': [
            {'cid': 101, 'page': 1, 'part': 'Part 1', 'duration': 60},
            {'cid': 102, 'page': 2, 'part': 'Part 2', 'duration': 90},
          ],
        },
      ),
    );

    final series = await repository.resolveAsSeries(_result());

    expect(series.title, 'Long Talk');
    expect(series, isA<BilibiliCollectionSeries>());
    expect(series.episodes, hasLength(2));
    expect(series.episodes.first.title, 'Part 1');
    expect(series.episodes.first.cid, 101);
  });

  test('converts single B站 videos into one Episode', () async {
    final repository = BilibiliRepository(
      _FakeBilibiliClient(
        detail: {
          'bvid': 'BV1xx411c7mD',
          'aid': 1,
          'title': 'One Talk',
          'owner': {'name': 'Alice', 'mid': 42},
          'pages': [
            {'cid': 101, 'page': 1, 'part': 'Main', 'duration': 60},
          ],
        },
      ),
    );

    final series = await repository.resolveAsSeries(_result());

    expect(series.episodes, hasLength(1));
    expect(series.episodes.single.title, 'One Talk');
    expect(series.episodes.single.sourceType, SourceType.bilibili);
  });

  test('converts B站 ugc season into a Series', () async {
    final repository = BilibiliRepository(
      _FakeBilibiliClient(
        detail: {
          'bvid': 'BV1xx411c7mD',
          'title': 'Current Video',
          'owner': {'name': 'Alice', 'mid': 42},
          'ugc_season': {
            'id': 88,
            'title': 'Season Talk',
            'sections': [
              {
                'episodes': [
                  {'bvid': 'BV101', 'aid': 101, 'cid': 201, 'title': 'S1'},
                  {'bvid': 'BV102', 'aid': 102, 'cid': 202, 'title': 'S2'},
                ],
              },
            ],
          },
        },
      ),
    );

    final series = await repository.resolveAsSeries(_result());

    expect(series.id, 'bili-season-88');
    expect(series, isA<BilibiliCollectionSeries>());
    expect(series.title, 'Season Talk');
    expect(series.episodes.map((episode) => episode.bvid), ['BV101', 'BV102']);
  });

  test('loads B站 creator videos as playable episodes', () async {
    final repository = BilibiliRepository(
      _FakeBilibiliClient(
        rows: [
          {'bvid': 'BV101'},
          {'bvid': 'BV102'},
        ],
        details: {
          'BV101': {
            'bvid': 'BV101',
            'title': 'Video 1',
            'owner': {'name': 'Alice', 'mid': 42},
            'pages': [
              {'cid': 201, 'page': 1, 'duration': 60},
            ],
          },
          'BV102': {
            'bvid': 'BV102',
            'title': 'Video 2',
            'owner': {'name': 'Alice', 'mid': 42},
            'pages': [
              {'cid': 202, 'page': 1, 'duration': 90},
            ],
          },
        },
      ),
    );

    final series = await repository.loadCreatorSeries(
      const BilibiliCreatorSeries(
        id: 'bili-up-42',
        title: 'Alice',
        originalUrl: 'https://space.bilibili.com/42',
      ),
    );

    expect(series.episodes.map((episode) => episode.title), [
      'Video 1',
      'Video 2',
    ]);
    expect(series, isA<BilibiliCreatorSeries>());
    expect(series.episodes.first.cid, 201);
    expect(series.episodes.first.duration, const Duration(seconds: 60));
  });
}

SearchResult _result() {
  return const SearchResult(
    id: 'BV1xx411c7mD',
    title: 'Result',
    sourceType: SourceType.bilibili,
    originalUrl: 'https://www.bilibili.com/video/BV1xx411c7mD',
    bvid: 'BV1xx411c7mD',
  );
}

class _FakeBilibiliClient extends BilibiliClient {
  _FakeBilibiliClient({
    this.detail = const <String, dynamic>{},
    this.details = const <String, Map<String, dynamic>>{},
    this.rows = const <Map<String, dynamic>>[],
  }) : super(Dio());

  final Map<String, dynamic> detail;
  final Map<String, Map<String, dynamic>> details;
  final List<Map<String, dynamic>> rows;

  @override
  Future<List<Map<String, dynamic>>> searchVideos(String keyword) async => rows;

  @override
  Future<List<Map<String, dynamic>>> ownerVideos(
    int mid, {
    int pageSize = 30,
  }) async => rows;

  @override
  Future<Map<String, dynamic>> videoDetail(String bvid) async {
    return details[bvid] ?? detail;
  }
}
