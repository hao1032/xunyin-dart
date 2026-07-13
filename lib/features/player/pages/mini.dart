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
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppLogger.userAction('open_player_from_mini', area: 'player');
          context.push('/player');
        },
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: _MarqueeTitle(
                  title: title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
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
          ),
        ),
      ),
    );
  }
}

class _MarqueeTitle extends StatefulWidget {
  const _MarqueeTitle({required this.title, required this.style});

  final String title;
  final TextStyle? style;

  @override
  State<_MarqueeTitle> createState() => _MarqueeTitleState();
}

class _MarqueeTitleState extends State<_MarqueeTitle>
    with SingleTickerProviderStateMixin {
  static const _gap = 32.0;
  static const _pixelsPerSecond = 28.0;

  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didUpdateWidget(covariant _MarqueeTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.style != widget.style) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0 || maxWidth.isInfinite) {
          _controller.stop();
          return Text(widget.title, maxLines: 1, softWrap: false, style: style);
        }

        final textPainter = TextPainter(
          text: TextSpan(text: widget.title, style: style),
          maxLines: 1,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout();
        final textWidth = textPainter.width;
        final overflows = textWidth > maxWidth;
        if (!overflows) {
          _controller.stop();
          _controller.value = 0;
          return Text(widget.title, maxLines: 1, softWrap: false, style: style);
        }

        final distance = textWidth + _gap;
        final duration = Duration(
          milliseconds: (distance / _pixelsPerSecond * 1000).round(),
        );
        if (_controller.duration != duration) {
          _controller.duration = duration;
        }
        if (!_controller.isAnimating) {
          _controller.repeat();
        }

        return ClipRect(
          child: SizedBox(
            width: maxWidth,
            height: textPainter.height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset = -_controller.value * distance;
                return OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: textWidth * 2 + _gap,
                  maxWidth: textWidth * 2 + _gap,
                  child: Transform.translate(
                    offset: Offset(offset, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          softWrap: false,
                          style: style,
                        ),
                        const SizedBox(width: _gap),
                        Text(
                          widget.title,
                          maxLines: 1,
                          softWrap: false,
                          style: style,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
