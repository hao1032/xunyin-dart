import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/storage/library_store.dart';
import '../podcast/model.dart';
import '../channel/model.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(libraryStoreProvider));
});

class LibraryRepository {
  const LibraryRepository(this._store);

  final LibraryStore _store;

  Future<List<AudioShow>> subscriptions() => _store.loadSubscriptions();

  Future<bool> isSubscribed(String showId) async {
    final shows = await subscriptions();
    return shows.any((show) => show.id == showId);
  }

  Future<void> subscribe(AudioShow show) async {
    await _store.saveSubscription(show);
    AppLogger.result(
      'save_subscription',
      area: 'library',
      data: {'showId': show.id, 'title': show.title},
    );
  }

  Future<void> unsubscribe(String showId) async {
    await _store.removeSubscription(showId);
    AppLogger.result(
      'remove_subscription',
      area: 'library',
      data: {'showId': showId},
    );
  }

  Future<List<Episode>> history() => _store.loadHistory();

  Future<void> recordPlayback(Episode episode) async {
    await _store.addHistory(episode);
    AppLogger.result(
      'record_playback',
      area: 'library',
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
      area: 'library',
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
      area: 'library',
      data: {'episodeId': episode.id, 'title': episode.title},
    );
  }
}
