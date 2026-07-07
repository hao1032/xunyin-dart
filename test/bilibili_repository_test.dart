import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/bilibili/data/bilibili_client.dart';
import 'package:xunyin_dart/features/bilibili/data/bilibili_repository.dart';
import 'package:xunyin_dart/features/podcast/domain/source_type.dart';
import 'package:xunyin_dart/features/search/domain/search_result.dart';

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
      repository.resolveAsShow(
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

  test('converts multipart B站 videos into a PodcastShow', () async {
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

    final show = await repository.resolveAsShow(_result());

    expect(show.title, 'Long Talk');
    expect(show.episodes, hasLength(2));
    expect(show.episodes.first.title, 'Part 1');
    expect(show.episodes.first.cid, 101);
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

    final show = await repository.resolveAsShow(_result());

    expect(show.episodes, hasLength(1));
    expect(show.episodes.single.title, 'One Talk');
    expect(show.episodes.single.sourceType, SourceType.bilibili);
  });

  test('converts B站 ugc season into a PodcastShow', () async {
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

    final show = await repository.resolveAsShow(_result());

    expect(show.id, 'bili-season-88');
    expect(show.title, 'Season Talk');
    expect(show.episodes.map((episode) => episode.bvid), ['BV101', 'BV102']);
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
    this.rows = const <Map<String, dynamic>>[],
  }) : super(Dio());

  final Map<String, dynamic> detail;
  final List<Map<String, dynamic>> rows;

  @override
  Future<List<Map<String, dynamic>>> searchVideos(String keyword) async => rows;

  @override
  Future<Map<String, dynamic>> videoDetail(String bvid) async => detail;
}
