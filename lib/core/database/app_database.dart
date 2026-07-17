import 'package:drift/drift.dart';

import '../../features/downloads/table.dart';
import '../../features/episode/table.dart';
import '../../features/series/table.dart';
import 'database_connection.dart';
import '../logging/app_logger.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SeriesTable, EpisodesTable, DownloadsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase({AppLogger? logger})
    : _logger = logger ?? createAppLogger(),
      super(openDatabaseConnection());

  AppDatabase.forTesting(super.executor, {AppLogger? logger})
    : _logger = logger ?? const NoopAppLogger();

  final AppLogger _logger;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        try {
          await migrator.createAll();
          await _createIndexes();
          _logger.info(
            'database',
            'schema_created',
            data: {'version': schemaVersion},
          );
        } catch (error, stackTrace) {
          _logger.error(
            'database',
            'schema_create_failed',
            error: error,
            stackTrace: stackTrace,
            data: {'version': schemaVersion},
          );
          Error.throwWithStackTrace(error, stackTrace);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX series_top_level_order ON series(sort_order, id)',
    );
    await customStatement(
      'CREATE INDEX episodes_top_level_order '
      'ON episodes(sort_order, id) WHERE series_id IS NULL',
    );
    await customStatement(
      'CREATE INDEX episodes_series_order '
      'ON episodes(series_id, sort_order, id) WHERE series_id IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX episodes_series_last_played '
      'ON episodes(series_id, last_played_at DESC)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX episodes_unique_standalone '
      'ON episodes(source_type, source_episode_id) WHERE series_id IS NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX episodes_unique_in_series '
      'ON episodes(series_id, source_type, source_episode_id) '
      'WHERE series_id IS NOT NULL',
    );
  }
}
