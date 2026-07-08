import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/podcast/domain/episode.dart';
import '../../features/podcast/domain/podcast_show.dart';
import 'app_json_store.dart';

final libraryStoreProvider = Provider<LibraryStore>((ref) {
  return LibraryStore(ref.watch(appJsonStoreProvider));
});

class LibraryStore {
  const LibraryStore(this._jsonStore);

  static const _subscriptionsFileName = 'subscriptions.json';
  static const _historyFileName = 'history.json';

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

  List<Map<String, Object?>> _decodeList(Object? raw) {
    if (raw == null) return const [];
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((item) {
      return item.cast<String, Object?>();
    }).toList();
  }
}
