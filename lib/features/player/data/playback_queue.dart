import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/storage/app_json_store.dart';
import '../../podcast/domain/episode.dart';
import '../../podcast/domain/podcast_show.dart';

final playbackQueueProvider =
    NotifierProvider<PlaybackQueueController, PlaybackQueueState>(
      PlaybackQueueController.new,
    );

class PlaybackQueueState {
  const PlaybackQueueState({this.current, this.items = const []});

  final Episode? current;
  final List<PlaybackQueueEntry> items;

  PlaybackQueueState copyWith({
    Episode? current,
    List<PlaybackQueueEntry>? items,
  }) {
    return PlaybackQueueState(
      current: current ?? this.current,
      items: items ?? this.items,
    );
  }
}

class PlaybackQueueController extends Notifier<PlaybackQueueState> {
  static const _fileName = 'playback_queue.json';

  AppJsonStore? _store;
  bool _restoring = false;

  @override
  PlaybackQueueState build() {
    _store = ref.watch(appJsonStoreProvider);
    unawaited(_restore());
    return const PlaybackQueueState();
  }

  void playNow(Episode episode) {
    if (state.items.any((item) => item.containsEpisode(episode.id))) {
      state = state.copyWith(current: episode);
      _persist();
      AppLogger.result(
        'queue_play_now',
        area: 'player',
        data: {
          'episodeId': episode.id,
          'title': episode.title,
          'queueCount': state.items.length,
          'alreadyQueued': true,
        },
      );
      return;
    }
    final items = [
      PlaybackQueueEntry.episode(episode),
      ...state.items.where((item) => item.id != episode.id),
    ];
    state = PlaybackQueueState(current: episode, items: items);
    _persist();
    AppLogger.result(
      'queue_play_now',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'queueCount': items.length,
      },
    );
  }

  void add(Episode episode) {
    if (state.items.any((item) => item.containsEpisode(episode.id))) return;
    final items = [...state.items, PlaybackQueueEntry.episode(episode)];
    state = state.copyWith(items: items);
    _persist();
    AppLogger.result(
      'queue_add_episode',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'queueCount': items.length,
      },
    );
  }

  void addShow(PodcastShow show) {
    if (state.items.any((item) => item.id == show.id)) return;
    final items = [...state.items, PlaybackQueueEntry.show(show)];
    state = state.copyWith(items: items);
    _persist();
    AppLogger.result(
      'queue_add_show',
      area: 'player',
      data: {
        'showId': show.id,
        'title': show.title,
        'episodeCount': show.episodes.length,
        'queueCount': items.length,
      },
    );
  }

  void remove(String entryId) {
    final removed = state.items.where((item) => item.id == entryId).toList();
    final removedCurrent = removed.any(
      (item) =>
          state.current != null && item.containsEpisode(state.current!.id),
    );
    final items = state.items.where((item) => item.id != entryId).toList();
    final current = removedCurrent ? null : state.current;
    state = PlaybackQueueState(current: current, items: items);
    _persist();
    AppLogger.result(
      'queue_remove_entry',
      area: 'player',
      data: {'entryId': entryId, 'queueCount': items.length},
    );
  }

  void clear() {
    state = const PlaybackQueueState();
    _persist();
    AppLogger.result('queue_clear', area: 'player');
  }

  Future<void> _restore() async {
    if (_restoring) return;
    _restoring = true;
    try {
      final data = await _store?.readObject(
        _fileName,
        fallback: {'items': <Object?>[]},
      );
      if (data == null) return;
      final entries = (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => PlaybackQueueEntry.fromJson(item.cast()))
          .whereType<PlaybackQueueEntry>()
          .toList();
      final currentEpisodeId = data['currentEpisodeId'] as String?;
      final current = currentEpisodeId == null
          ? null
          : entries
                .expand((entry) => entry.episodes)
                .where((episode) => episode.id == currentEpisodeId)
                .firstOrNull;
      if (entries.isEmpty && current == null) return;
      state = PlaybackQueueState(current: current, items: entries);
      AppLogger.result(
        'queue_restore',
        area: 'player',
        data: {'queueCount': entries.length, 'currentEpisodeId': current?.id},
      );
    } catch (error, stackTrace) {
      AppLogger.failure(
        'queue_restore',
        error,
        area: 'player',
        stackTrace: stackTrace,
      );
    } finally {
      _restoring = false;
    }
  }

  void _persist() {
    final store = _store;
    if (store == null || _restoring) return;
    unawaited(
      store.writeObject(_fileName, {
        'version': 1,
        'currentEpisodeId': state.current?.id,
        'items': state.items.map((item) => item.toJson()).toList(),
      }),
    );
  }
}

enum PlaybackQueueEntryType { episode, show }

class PlaybackQueueEntry {
  const PlaybackQueueEntry._({
    required this.id,
    required this.title,
    required this.type,
    required this.episodes,
    this.subtitle,
  });

  factory PlaybackQueueEntry.episode(Episode episode) {
    return PlaybackQueueEntry._(
      id: episode.id,
      title: episode.title,
      subtitle: episode.author ?? episode.sourceType.label,
      type: PlaybackQueueEntryType.episode,
      episodes: [episode],
    );
  }

  factory PlaybackQueueEntry.show(PodcastShow show) {
    return PlaybackQueueEntry._(
      id: show.id,
      title: show.title,
      subtitle: '${show.episodes.length} 集 · ${show.sourceType.label}',
      type: PlaybackQueueEntryType.show,
      episodes: show.episodes,
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final PlaybackQueueEntryType type;
  final List<Episode> episodes;

  bool containsEpisode(String episodeId) {
    return episodes.any((episode) => episode.id == episodeId);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type.name,
      'episodes': episodes.map((episode) => episode.toJson()).toList(),
    };
  }

  static PlaybackQueueEntry? fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String?;
    final type = PlaybackQueueEntryType.values
        .where((item) => item.name == typeName)
        .firstOrNull;
    if (type == null) return null;
    final episodes = (json['episodes'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Episode.fromJson(item.cast()))
        .toList();
    if (episodes.isEmpty) return null;
    return PlaybackQueueEntry._(
      id: json['id'] as String? ?? episodes.first.id,
      title: json['title'] as String? ?? episodes.first.title,
      subtitle: json['subtitle'] as String?,
      type: type,
      episodes: episodes,
    );
  }
}
