import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_logger.dart';
import '../../../core/storage/app_json_store.dart';
import '../../episode/model.dart';
import '../../series/model.dart';

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

  ({Episode? episode, PlaybackQueueState state}) advanceAfter(Episode episode) {
    final entryIndex = items.indexWhere(
      (item) => item.containsEpisode(episode.id),
    );
    if (entryIndex < 0) return (episode: null, state: this);

    final entry = items[entryIndex];
    final episodeIndex = entry.episodes.indexWhere(
      (item) => item.id == episode.id,
    );

    Episode? nextEpisode;
    var nextEntryIndex = entryIndex;
    if (entry.type == PlaybackQueueEntryType.series &&
        episodeIndex >= 0 &&
        episodeIndex + 1 < entry.episodes.length) {
      nextEpisode = entry.episodes[episodeIndex + 1];
    } else if (entryIndex + 1 < items.length) {
      nextEntryIndex = entryIndex + 1;
      nextEpisode = items[nextEntryIndex].playableEpisode;
    }

    if (nextEpisode == null) return (episode: null, state: this);

    final nextItems = [...items];
    nextItems[nextEntryIndex] = nextItems[nextEntryIndex].markPlayed(
      nextEpisode.id,
    );
    return (
      episode: nextEpisode,
      state: PlaybackQueueState(current: nextEpisode, items: nextItems),
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
    final existingIndex = state.items.indexWhere(
      (item) => item.containsEpisode(episode.id),
    );
    if (existingIndex >= 0) {
      final items = [...state.items];
      items[existingIndex] = items[existingIndex].markPlayed(episode.id);
      state = PlaybackQueueState(current: episode, items: items);
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

  void addSeries(Series series) {
    if (state.items.any((item) => item.id == series.id)) return;
    final items = [...state.items, PlaybackQueueEntry.series(series)];
    state = state.copyWith(items: items);
    _persist();
    AppLogger.result(
      'queue_add_series',
      area: 'player',
      data: {
        'seriesId': series.id,
        'title': series.title,
        'episodeCount': series.episodes.length,
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

  Episode? playNextAfter(Episode episode) {
    final advance = state.advanceAfter(episode);
    final nextEpisode = advance.episode;
    if (nextEpisode == null) {
      AppLogger.result(
        'queue_advance_next_missing',
        area: 'player',
        data: {'episodeId': episode.id, 'queueCount': state.items.length},
      );
      return null;
    }
    state = advance.state;
    _persist();
    AppLogger.result(
      'queue_advance_next',
      area: 'player',
      data: {
        'fromEpisodeId': episode.id,
        'episodeId': nextEpisode.id,
        'title': nextEpisode.title,
        'queueCount': state.items.length,
      },
    );
    return nextEpisode;
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

enum PlaybackQueueEntryType { episode, series }

class PlaybackQueueEntry {
  const PlaybackQueueEntry._({
    required this.id,
    required this.title,
    required this.type,
    required this.episodes,
    this.subtitle,
    this.lastPlayedEpisodeId,
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

  factory PlaybackQueueEntry.series(Series series) {
    return PlaybackQueueEntry._(
      id: series.id,
      title: series.title,
      subtitle: '${series.episodes.length} 集 · ${series.label}',
      type: PlaybackQueueEntryType.series,
      episodes: series.episodes,
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final String? lastPlayedEpisodeId;
  final PlaybackQueueEntryType type;
  final List<Episode> episodes;

  bool containsEpisode(String episodeId) {
    return episodes.any((episode) => episode.id == episodeId);
  }

  Episode get playableEpisode {
    final lastPlayedEpisodeId = this.lastPlayedEpisodeId;
    if (lastPlayedEpisodeId == null) return episodes.first;
    return episodes
            .where((episode) => episode.id == lastPlayedEpisodeId)
            .firstOrNull ??
        episodes.first;
  }

  PlaybackQueueEntry markPlayed(String episodeId) {
    if (type != PlaybackQueueEntryType.series || !containsEpisode(episodeId)) {
      return this;
    }
    return PlaybackQueueEntry._(
      id: id,
      title: title,
      subtitle: subtitle,
      type: type,
      episodes: episodes,
      lastPlayedEpisodeId: episodeId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type.name,
      'lastPlayedEpisodeId': lastPlayedEpisodeId,
      'episodes': episodes.map((episode) => episode.toJson()).toList(),
    };
  }

  static PlaybackQueueEntry? fromJson(Map<String, Object?> json) {
    final type = PlaybackQueueEntryType.values
        .where((item) => item.name == json['type'])
        .firstOrNull;
    if (type == null) return null;
    final episodes = (json['episodes'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Episode.tryFromJson(item.cast()))
        .whereType<Episode>()
        .toList();
    if (episodes.isEmpty) return null;
    return PlaybackQueueEntry._(
      id: json['id'] as String? ?? episodes.first.id,
      title: json['title'] as String? ?? episodes.first.title,
      subtitle: json['subtitle'] as String?,
      type: type,
      episodes: episodes,
      lastPlayedEpisodeId: json['lastPlayedEpisodeId'] as String?,
    );
  }
}
