import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/storage/library_store.dart';
import '../../podcast/domain/episode.dart';
import '../../podcast/domain/podcast_show.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(libraryStoreProvider));
});

class LibraryRepository {
  const LibraryRepository(this._store);

  final LibraryStore _store;

  Future<List<PodcastShow>> subscriptions() => _store.loadSubscriptions();

  Future<bool> isSubscribed(String showId) async {
    final shows = await subscriptions();
    return shows.any((show) => show.id == showId);
  }

  Future<void> subscribe(PodcastShow show) async {
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
}
