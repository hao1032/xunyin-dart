import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/app_logger.dart';
import '../services/controller.dart';
import '../services/playback_queue.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, this.maxWidth, this.expand = false});

  final double? maxWidth;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(appPlayerProvider);
    final current = ref.watch(playbackQueueProvider).current;
    if (current == null) return const SizedBox.shrink();

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? player.playing;
        final processingState =
            state?.processingState ?? player.processingState;
        final loading =
            processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final adaptiveWidth =
            maxWidth ?? (screenWidth * 0.42).clamp(148.0, 260.0);
        final surface = _MiniPlayerSurface(
          title: current.title,
          playing: playing,
          loading: loading,
          onToggle: () {
            final action = playing
                ? 'pause_from_mini_player'
                : 'play_from_mini_player';
            AppLogger.userAction(action, area: 'player');
            playing ? player.pause() : player.play();
            AppLogger.result(action, area: 'player');
          },
        );
        if (expand) return SizedBox(width: double.infinity, child: surface);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: adaptiveWidth),
            child: surface,
          ),
        );
      },
    );
  }
}

class _MiniPlayerSurface extends StatelessWidget {
  const _MiniPlayerSurface({
    required this.title,
    required this.playing,
    required this.loading,
    required this.onToggle,
  });

  final String title;
  final bool playing;
  final bool loading;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppLogger.userAction('open_player_from_mini', area: 'player');
          context.push('/player');
        },
        child: SizedBox(
          height: 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final titleMaxWidth = (constraints.maxWidth - 52).clamp(
                0.0,
                double.infinity,
              );
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: titleMaxWidth),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox.square(
                    dimension: 40,
                    child: IconButton(
                      tooltip: loading ? '加载中' : (playing ? '暂停' : '播放'),
                      icon: loading
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: colors.primary,
                              ),
                            )
                          : Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                      onPressed: loading ? null : onToggle,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
