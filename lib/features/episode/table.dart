import 'package:drift/drift.dart';

// Required by drift_dev to validate the custom foreign key target.
// ignore: unused_import
import '../series/table.dart';

@DataClassName('EpisodeRow')
class EpisodesTable extends Table {
  @override
  String get tableName => 'episodes';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get seriesId => integer().nullable()();

  TextColumn get sourceType => text()();

  TextColumn get sourceEpisodeId => text()();
  IntColumn get sortOrder => integer()();

  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get originalUrl => text().nullable()();

  TextColumn get audioUrl => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get audioBytes => integer().nullable()();
  DateTimeColumn get publishedAt => dateTime().nullable()();

  TextColumn get bilibiliBvid => text().nullable()();
  IntColumn get bilibiliAid => integer().nullable()();
  IntColumn get bilibiliCid => integer().nullable()();
  IntColumn get bilibiliPage => integer().nullable()();

  IntColumn get progressMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<String> get customConstraints => const [
    "CHECK (source_type IN ('bilibili', 'rss'))",
    'FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE CASCADE',
  ];
}
