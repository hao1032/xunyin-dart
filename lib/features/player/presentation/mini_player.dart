import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/logging/app_logger.dart';
import '../data/playback_queue.dart';
import '../data/player_controller.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(appAudioPlayerProvider);
    final queue = ref.watch(playbackQueueProvider);
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Material(
          elevation: 4,
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 92,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(playing ? Icons.graphic_eq : Icons.podcasts),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            queue.current?.title ?? '播放器',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: '播放列表',
                          icon: Badge.count(
                            count: queue.items.length,
                            isLabelVisible: queue.items.isNotEmpty,
                            child: const Icon(Icons.queue_music),
                          ),
                          onPressed: () {
                            AppLogger.userAction(
                              'open_queue',
                              area: 'player',
                              data: {'queueCount': queue.items.length},
                            );
                            context.push('/queue');
                          },
                        ),
                        IconButton(
                          tooltip: playing ? '暂停' : '播放',
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                          onPressed: () {
                            AppLogger.userAction(
                              playing
                                  ? 'pause_from_mini_player'
                                  : 'play_from_mini_player',
                              area: 'player',
                            );
                            playing ? player.pause() : player.play();
                            AppLogger.result(
                              playing
                                  ? 'pause_from_mini_player'
                                  : 'play_from_mini_player',
                              area: 'player',
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  _MiniPlayerProgress(player: player),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerProgress extends StatelessWidget {
  const _MiniPlayerProgress({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data;
            final maxMs = duration?.inMilliseconds ?? 0;
            final positionMs = position.inMilliseconds.clamp(0, maxMs);
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      _formatDuration(position),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: maxMs <= 0 ? 1 : maxMs.toDouble(),
                      value: maxMs <= 0 ? 0 : positionMs.toDouble(),
                      onChanged: maxMs <= 0
                          ? null
                          : (value) {
                              player.seek(
                                Duration(milliseconds: value.round()),
                              );
                            },
                      onChangeEnd: maxMs <= 0
                          ? null
                          : (value) {
                              AppLogger.userAction(
                                'seek_from_mini_player',
                                area: 'player',
                                data: {
                                  'positionMs': value.round(),
                                  'durationMs': maxMs,
                                },
                              );
                            },
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      duration == null ? '--:--' : _formatDuration(duration),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final secondsText = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final minutesText = minutes.toString().padLeft(2, '0');
      return '$hours:$minutesText:$secondsText';
    }
    return '$minutes:$secondsText';
  }
}
