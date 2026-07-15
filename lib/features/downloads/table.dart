import 'package:drift/drift.dart';

@DataClassName('DownloadRow')
class DownloadsTable extends Table {
  @override
  String get tableName => 'downloads';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourceType => text()();

  TextColumn get sourceEpisodeId => text()();
  TextColumn get filePath => text().nullable()();
  IntColumn get bytes => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('downloading'))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get downloadedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sourceType, sourceEpisodeId},
  ];

  @override
  List<String> get customConstraints => const [
    "CHECK (source_type IN ('bilibili', 'rss'))",
    "CHECK (status IN ('downloading', 'complete', 'failed'))",
  ];
}
