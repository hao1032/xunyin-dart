import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/formatters/audio_formatters.dart';
import '../services/playback_queue.dart';
import '../services/controller.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, this.includeBottomSafeArea = true});

  final bool includeBottomSafeArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(appAudioPlayerProvider);
    final current = ref.watch(playbackQueueProvider).current;
    if (current == null) return const SizedBox.shrink();

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        final colors = Theme.of(context).colorScheme;
        return ColoredBox(
          color: colors.surfaceContainerLowest,
          child: SafeArea(
            top: false,
            bottom: includeBottomSafeArea,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Material(
                color: colors.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    AppLogger.userAction(
                      'open_player_from_mini',
                      area: 'player',
                    );
                    context.push('/player');
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 62,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            _MiniCover(url: current.imageUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    current.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  _MiniPlayerTime(player: player),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: playing ? '暂停' : '播放',
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              onPressed: () {
                                final action = playing
                                    ? 'pause_from_mini_player'
                                    : 'play_from_mini_player';
                                AppLogger.userAction(action, area: 'player');
                                playing ? player.pause() : player.play();
                                AppLogger.result(action, area: 'player');
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                      _MiniProgress(player: player),
                    ],
                  ),
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
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
        dimension: 46,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.graphic_eq_rounded),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.graphic_eq_rounded),
              ),
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
                ? formatDuration(position)
                : '${formatDuration(position)} / ${formatDuration(duration)}';
            return Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data?.inMilliseconds ?? 0;
            final position = positionSnapshot.data?.inMilliseconds ?? 0;
            return LinearProgressIndicator(
              minHeight: 2,
              value: duration <= 0 ? 0 : (position / duration).clamp(0, 1),
              backgroundColor: Colors.transparent,
            );
          },
        );
      },
    );
  }
}
