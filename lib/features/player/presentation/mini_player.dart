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
    final current = queue.current;
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Material(
          elevation: 4,
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: InkWell(
              onTap: () {
                AppLogger.userAction('open_player_from_mini', area: 'player');
                context.push('/player');
              },
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    _MiniCover(url: current?.imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            queue.current?.title ?? '播放器',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _MiniPlayerTime(player: player),
                        ],
                      ),
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
            ),
          ),
        );
      },
    );
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: 44,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.podcasts),
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _MiniPlayerTime extends StatelessWidget {
  const _MiniPlayerTime({required this.player});

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
            final text = duration == null
                ? _formatDuration(position)
                : '${_formatDuration(position)} / ${_formatDuration(duration)}';
            return Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
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
