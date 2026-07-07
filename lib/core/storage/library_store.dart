import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/podcast/domain/episode.dart';
import '../../features/podcast/domain/podcast_show.dart';

final libraryStoreProvider = Provider<LibraryStore>((ref) => LibraryStore());

class LibraryStore {
  static const _subscriptionsKey = 'subscriptions';
  static const _historyKey = 'history';

  Future<List<PodcastShow>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(
      prefs.getString(_subscriptionsKey),
    ).map(PodcastShow.fromJson).toList();
  }

  Future<void> saveSubscription(PodcastShow show) async {
    final shows = await loadSubscriptions();
    final next = [show, ...shows.where((item) => item.id != show.id)];
    await _saveShows(_subscriptionsKey, next);
  }

  Future<void> removeSubscription(String showId) async {
    final shows = await loadSubscriptions();
    await _saveShows(
      _subscriptionsKey,
      shows.where((item) => item.id != showId),
    );
  }

  Future<List<Episode>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(
      prefs.getString(_historyKey),
    ).map(Episode.fromJson).toList();
  }

  Future<void> addHistory(Episode episode) async {
    final history = await loadHistory();
    final next = [
      episode,
      ...history.where((item) => item.id != episode.id),
    ].take(50).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveShows(String key, Iterable<PodcastShow> shows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(shows.map((item) => item.toJson()).toList()),
    );
  }

  List<Map<String, Object?>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((item) {
      return item.cast<String, Object?>();
    }).toList();
  }
}
