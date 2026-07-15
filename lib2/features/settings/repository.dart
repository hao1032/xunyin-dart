import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_logger.dart';
import '../../core/storage/user_data_store.dart';
import '../episode/model.dart';
import '../series/model.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(userDataStoreProvider));
});

class SettingsRepository {
  const SettingsRepository(this._store);

  final UserDataStore _store;

  Future<List<Series>> subscriptions() => _store.loadSubscriptions();

  Future<bool> isSubscribed(String seriesId) async {
    final series = await subscriptions();
    return series.any((item) => item.id == seriesId);
  }

  Future<void> subscribe(Series series) async {
    await _store.saveSubscription(series);
    AppLogger.result(
      'save_subscription',
      area: 'settings',
      data: {'seriesId': series.id, 'title': series.title},
    );
  }

  Future<void> unsubscribe(String seriesId) async {
    await _store.removeSubscription(seriesId);
    AppLogger.result(
      'remove_subscription',
      area: 'settings',
      data: {'seriesId': seriesId},
    );
  }

  Future<List<Episode>> history() => _store.loadHistory();

  Future<void> recordPlayback(Episode episode) async {
    await _store.addHistory(episode);
    AppLogger.result(
      'record_playback',
      area: 'settings',
      data: {'episodeId': episode.id, 'title': episode.title},
    );
  }

  Future<Duration?> playbackPosition(String episodeId) {
    return _store.loadPlaybackPosition(episodeId);
  }

  Future<void> savePlaybackPosition(Episode episode, Duration position) async {
    await _store.savePlaybackPosition(episode.id, position);
    AppLogger.result(
      'save_playback_position',
      area: 'settings',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'positionMs': position.inMilliseconds,
      },
    );
  }

  Future<void> clearPlaybackPosition(Episode episode) async {
    await _store.removePlaybackPosition(episode.id);
    AppLogger.result(
      'clear_playback_position',
      area: 'settings',
      data: {'episodeId': episode.id, 'title': episode.title},
    );
  }
}
