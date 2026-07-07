import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../podcast/domain/episode.dart';

final playbackQueueProvider =
    NotifierProvider<PlaybackQueueController, PlaybackQueueState>(
      PlaybackQueueController.new,
    );

class PlaybackQueueState {
  const PlaybackQueueState({this.current, this.items = const []});

  final Episode? current;
  final List<Episode> items;

  PlaybackQueueState copyWith({Episode? current, List<Episode>? items}) {
    return PlaybackQueueState(
      current: current ?? this.current,
      items: items ?? this.items,
    );
  }
}

class PlaybackQueueController extends Notifier<PlaybackQueueState> {
  @override
  PlaybackQueueState build() => const PlaybackQueueState();

  void playNow(Episode episode) {
    final items = [
      episode,
      ...state.items.where((item) => item.id != episode.id),
    ];
    state = PlaybackQueueState(current: episode, items: items);
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
    if (state.items.any((item) => item.id == episode.id)) return;
    final items = [...state.items, episode];
    state = state.copyWith(items: items);
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

  void addAll(List<Episode> episodes) {
    final byId = {for (final item in state.items) item.id: item};
    for (final episode in episodes) {
      byId[episode.id] = episode;
    }
    final items = byId.values.toList();
    state = state.copyWith(items: items);
    AppLogger.result(
      'queue_add_all',
      area: 'player',
      data: {'addedCount': episodes.length, 'queueCount': items.length},
    );
  }

  void remove(String episodeId) {
    final items = state.items.where((item) => item.id != episodeId).toList();
    final current = state.current?.id == episodeId ? null : state.current;
    state = PlaybackQueueState(current: current, items: items);
    AppLogger.result(
      'queue_remove_episode',
      area: 'player',
      data: {'episodeId': episodeId, 'queueCount': items.length},
    );
  }

  void clear() {
    state = const PlaybackQueueState();
    AppLogger.result('queue_clear', area: 'player');
  }
}
