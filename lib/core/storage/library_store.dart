import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/podcast/domain/episode.dart';
import '../../features/podcast/domain/podcast_show.dart';
import '../../features/cache/domain/cached_episode.dart';
import 'app_json_store.dart';

final libraryStoreProvider = Provider<LibraryStore>((ref) {
  return LibraryStore(ref.watch(appJsonStoreProvider));
});

class LibraryStore {
  const LibraryStore(this._jsonStore);

  static const _subscriptionsFileName = 'subscriptions.json';
  static const _historyFileName = 'history.json';
  static const _cacheFileName = 'cached_episodes.json';
  static const _playbackPositionsFileName = 'playback_positions.json';

  final AppJsonStore _jsonStore;

  Future<List<PodcastShow>> loadSubscriptions() async {
    final data = await _loadSubscriptions();
    return _decodeList(
      data['subscriptions'],
    ).map(PodcastShow.fromJson).toList();
  }

  Future<void> saveSubscription(PodcastShow show) async {
    final data = await _loadSubscriptions();
    final shows = _decodeList(
      data['subscriptions'],
    ).map(PodcastShow.fromJson).toList();
    final next = [show, ...shows.where((item) => item.id != show.id)];
    data['subscriptions'] = next.map((item) => item.toJson()).toList();
    await _saveSubscriptions(data);
  }

  Future<void> removeSubscription(String showId) async {
    final data = await _loadSubscriptions();
    final shows = _decodeList(
      data['subscriptions'],
    ).map(PodcastShow.fromJson).where((item) => item.id != showId).toList();
    data['subscriptions'] = shows.map((item) => item.toJson()).toList();
    await _saveSubscriptions(data);
  }

  Future<List<Episode>> loadHistory() async {
    final data = await _loadHistory();
    return _decodeList(data['history']).map(Episode.fromJson).toList();
  }

  Future<void> addHistory(Episode episode) async {
    final data = await _loadHistory();
    final history = _decodeList(data['history']).map(Episode.fromJson).toList();
    final next = [
      episode,
      ...history.where((item) => item.id != episode.id),
    ].take(50).toList();
    data['history'] = next.map((item) => item.toJson()).toList();
    await _saveHistory(data);
  }

  Future<List<CachedEpisode>> loadCachedEpisodes() async {
    final data = await _loadCache();
    return _decodeList(data['episodes']).map(CachedEpisode.fromJson).toList();
  }

  Future<void> saveCachedEpisode(CachedEpisode cached) async {
    final data = await _loadCache();
    final episodes = _decodeList(
      data['episodes'],
    ).map(CachedEpisode.fromJson).toList();
    final next = [
      cached,
      ...episodes.where((item) => item.episode.id != cached.episode.id),
    ];
    data['episodes'] = next.map((item) => item.toJson()).toList();
    await _saveCache(data);
  }

  Future<void> removeCachedEpisode(String episodeId) async {
    final data = await _loadCache();
    final episodes = _decodeList(data['episodes'])
        .map(CachedEpisode.fromJson)
        .where((item) => item.episode.id != episodeId)
        .toList();
    data['episodes'] = episodes.map((item) => item.toJson()).toList();
    await _saveCache(data);
  }

  Future<Duration?> loadPlaybackPosition(String episodeId) async {
    final data = await _loadPlaybackPositions();
    final positions = _decodePlaybackPositions(data['positions']);
    return positions[episodeId];
  }

  Future<void> savePlaybackPosition(String episodeId, Duration position) async {
    final data = await _loadPlaybackPositions();
    final positions = _decodePlaybackPositions(data['positions']);
    positions[episodeId] = position;
    data['positions'] = positions.map((key, value) {
      return MapEntry(key, value.inMilliseconds);
    });
    await _savePlaybackPositions(data);
  }

  Future<void> removePlaybackPosition(String episodeId) async {
    final data = await _loadPlaybackPositions();
    final positions = _decodePlaybackPositions(data['positions']);
    positions.remove(episodeId);
    data['positions'] = positions.map((key, value) {
      return MapEntry(key, value.inMilliseconds);
    });
    await _savePlaybackPositions(data);
  }

  Future<Map<String, Object?>> _loadSubscriptions() {
    return _jsonStore.readObject(
      _subscriptionsFileName,
      fallback: {'version': 1, 'subscriptions': <Object?>[]},
    );
  }

  Future<Map<String, Object?>> _loadHistory() {
    return _jsonStore.readObject(
      _historyFileName,
      fallback: {'version': 1, 'history': <Object?>[]},
    );
  }

  Future<Map<String, Object?>> _loadCache() {
    return _jsonStore.readObject(
      _cacheFileName,
      fallback: {'version': 1, 'episodes': <Object?>[]},
    );
  }

  Future<Map<String, Object?>> _loadPlaybackPositions() {
    return _jsonStore.readObject(
      _playbackPositionsFileName,
      fallback: {'version': 1, 'positions': <String, Object?>{}},
    );
  }

  Future<void> _saveSubscriptions(Map<String, Object?> data) {
    data['version'] = 1;
    data.putIfAbsent('subscriptions', () => <Object?>[]);
    return _jsonStore.writeObject(_subscriptionsFileName, data);
  }

  Future<void> _saveHistory(Map<String, Object?> data) {
    data['version'] = 1;
    data.putIfAbsent('history', () => <Object?>[]);
    return _jsonStore.writeObject(_historyFileName, data);
  }

  Future<void> _saveCache(Map<String, Object?> data) {
    data['version'] = 1;
    data.putIfAbsent('episodes', () => <Object?>[]);
    return _jsonStore.writeObject(_cacheFileName, data);
  }

  Future<void> _savePlaybackPositions(Map<String, Object?> data) {
    data['version'] = 1;
    data.putIfAbsent('positions', () => <String, Object?>{});
    return _jsonStore.writeObject(_playbackPositionsFileName, data);
  }

  List<Map<String, Object?>> _decodeList(Object? raw) {
    if (raw == null) return const [];
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((item) {
      return item.cast<String, Object?>();
    }).toList();
  }

  Map<String, Duration> _decodePlaybackPositions(Object? raw) {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) return {};
    final positions = <String, Duration>{};
    for (final entry in decoded.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! num) continue;
      positions[key] = Duration(milliseconds: value.toInt());
    }
    return positions;
  }
}
