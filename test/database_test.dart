import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('创建全部索引', () async {
    final rows = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(
      names,
      containsAll({
        'series_top_level_order',
        'episodes_top_level_order',
        'episodes_series_order',
        'episodes_series_last_played',
        'episodes_unique_standalone',
        'episodes_unique_in_series',
      }),
    );
  });

  test('拒绝不支持的来源类型和下载状态', () async {
    await expectLater(
      database
          .into(database.seriesTable)
          .insert(_seriesCompanion(sourceType: 'apple_podcast')),
      throwsA(isA<Exception>()),
    );

    await expectLater(
      database
          .into(database.downloadsTable)
          .insert(
            DownloadsTableCompanion.insert(
              sourceType: 'rss',
              sourceEpisodeId: 'episode-1',
              status: const Value('paused'),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('独立单集和同一 series 内单集不可重复', () async {
    final seriesId = await _insertSeries(database);
    final otherSeriesId = await _insertSeries(
      database,
      sourceSeriesId: 'series-2',
    );

    await _insertEpisode(database, sourceEpisodeId: 'shared');
    await expectLater(
      _insertEpisode(database, sourceEpisodeId: 'shared'),
      throwsA(isA<Exception>()),
    );

    await _insertEpisode(
      database,
      seriesId: seriesId,
      sourceEpisodeId: 'shared',
    );
    await _insertEpisode(
      database,
      seriesId: otherSeriesId,
      sourceEpisodeId: 'shared',
    );
    await expectLater(
      _insertEpisode(database, seriesId: seriesId, sourceEpisodeId: 'shared'),
      throwsA(isA<Exception>()),
    );
  });

  test('删除 series 会级联删除其子单集', () async {
    final seriesId = await _insertSeries(database);
    await _insertEpisode(database, seriesId: seriesId);

    await (database.delete(
      database.seriesTable,
    )..where((table) => table.id.equals(seriesId))).go();

    expect(await database.select(database.episodesTable).get(), isEmpty);
  });

  test('下载以来源单集身份全局唯一，并具有默认状态', () async {
    final id = await database
        .into(database.downloadsTable)
        .insert(
          DownloadsTableCompanion.insert(
            sourceType: 'rss',
            sourceEpisodeId: 'episode-1',
          ),
        );
    final download = await (database.select(
      database.downloadsTable,
    )..where((table) => table.id.equals(id))).getSingle();

    expect(download.status, 'downloading');
    expect(download.bytes, isNull);
    await expectLater(
      database
          .into(database.downloadsTable)
          .insert(
            DownloadsTableCompanion.insert(
              sourceType: 'rss',
              sourceEpisodeId: 'episode-1',
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('单集具有默认播放状态', () async {
    final id = await _insertEpisode(database);
    final episode = await (database.select(
      database.episodesTable,
    )..where((table) => table.id.equals(id))).getSingle();

    expect(episode.progressMs, 0);
    expect(episode.isCompleted, isFalse);
  });
}

Future<int> _insertSeries(
  AppDatabase database, {
  String sourceSeriesId = 'series-1',
}) {
  return database
      .into(database.seriesTable)
      .insert(_seriesCompanion(sourceSeriesId: sourceSeriesId));
}

SeriesTableCompanion _seriesCompanion({
  String sourceType = 'rss',
  String sourceSeriesId = 'series-1',
}) {
  final now = DateTime.utc(2026);
  return SeriesTableCompanion.insert(
    sourceType: sourceType,
    seriesKind: 'rss_podcast',
    sourceSeriesId: sourceSeriesId,
    sortOrder: 0,
    title: '测试系列',
    createdAt: now,
    updatedAt: now,
  );
}

Future<int> _insertEpisode(
  AppDatabase database, {
  int? seriesId,
  String sourceEpisodeId = 'episode-1',
}) {
  final now = DateTime.utc(2026);
  return database
      .into(database.episodesTable)
      .insert(
        EpisodesTableCompanion.insert(
          seriesId: Value(seriesId),
          sourceType: 'rss',
          sourceEpisodeId: sourceEpisodeId,
          sortOrder: 0,
          title: '测试单集',
          createdAt: now,
          updatedAt: now,
        ),
      );
}
