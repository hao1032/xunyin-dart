import 'package:drift/drift.dart';

@DataClassName('SeriesRow')
class SeriesTable extends Table {
  @override
  String get tableName => 'series';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourceType => text()();

  TextColumn get seriesKind => text()();

  TextColumn get sourceSeriesId => text()();
  IntColumn get sortOrder => integer()();

  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get originalUrl => text().nullable()();
  TextColumn get feedUrl => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sourceType, seriesKind, sourceSeriesId},
  ];

  @override
  List<String> get customConstraints => const [
    "CHECK (source_type IN ('bilibili', 'rss'))",
    "CHECK (series_kind IN ('bilibili_creator', 'bilibili_collection', 'rss_podcast'))",
  ];
}
