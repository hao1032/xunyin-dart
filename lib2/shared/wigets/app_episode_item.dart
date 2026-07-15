import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/app_constants.dart';
import '../../core/app_layout.dart';
import '../../core/app_logger.dart';
import '../../core/display_formatters.dart';
import '../../features/episode/model.dart';
import '../../features/episode/page.dart';
import '../../features/player/services/controller.dart';
import '../../features/player/services/playback_queue.dart';
import '../../features/series/model.dart';
import 'app_cover.dart';

class AppEpisodeItem extends ConsumerWidget {
  const AppEpisodeItem({
    super.key,
    required this.episode,
    this.subtitle,
    this.metadata,
    this.relatedSeries = const [],
    this.coverSize = 56,
    this.leading,
    this.enabled = true,
    this.embedded = false,
    this.selected = false,
    this.margin,
    this.padding,
    this.onTap,
    this.onOpen,
    this.onRemove,
    this.removeTooltip = '移除',
    this.onAddToQueue,
    this.isQueued = false,
    this.onDownload,
    this.onRemoveDownload,
    this.isDownloaded = false,
    this.isDownloadBusy = false,
    this.onPlay,
    this.onPause,
    this.isPlaying = false,
    this.isBusy = false,
    this.placeholderIcon = AppIcons.music,
  });

  final Episode episode;
  final String? subtitle;
  final String? metadata;
  final List<Series> relatedSeries;
  final double coverSize;
  final Widget? leading;
  final bool enabled;
  final bool embedded;
  final bool selected;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;
  final String removeTooltip;
  final VoidCallback? onAddToQueue;
  final bool isQueued;
  final VoidCallback? onDownload;
  final VoidCallback? onRemoveDownload;
  final bool isDownloaded;
  final bool isDownloadBusy;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final bool isPlaying;
  final bool isBusy;
  final IconData placeholderIcon;

  static String subtitleOf(Episode episode, {String? fallback}) {
    return fallback ?? episode.author ?? episode.sourceType.label;
  }

  static String metadataOf(Episode episode) {
    return [
      if (episode.publishedAt != null) formatRelativeDate(episode.publishedAt!),
      if (episode.duration != null) formatDuration(episode.duration!),
    ].join(' · ');
  }

  static void open(
    BuildContext context,
    Episode episode, {
    List<Series> relatedSeries = const [],
    VoidCallback? onOpen,
  }) {
    onOpen?.call();
    AppLogger.userAction(
      'open_episode',
      area: 'episode',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        if (relatedSeries.isNotEmpty) 'seriesId': relatedSeries.first.id,
      },
    );
    context.push(
      '/episode',
      extra: relatedSeries.isEmpty
          ? episode
          : EpisodePageArgs(episode: episode, relatedSeries: relatedSeries),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = _showsPlayAction ? ref.watch(appPlayerProvider) : null;
    final currentEpisodeId = _showsPlayAction
        ? ref.watch(playbackQueueProvider).current?.id
        : null;
    final isCurrent = currentEpisodeId == episode.id;
    final colors = Theme.of(context).colorScheme;
    final disabledColor = Theme.of(context).disabledColor;
    final borderRadius = BorderRadius.circular(
      embedded ? AppRadii.sm : AppRadii.md,
    );
    final contentPadding =
        padding ??
        (embedded
            ? const EdgeInsets.fromLTRB(
                AppSpacing.item,
                AppSpacing.sm,
                AppSpacing.item,
                AppSpacing.sm - 2,
              )
            : const EdgeInsets.fromLTRB(
                AppSpacing.item,
                AppSpacing.md,
                AppSpacing.item,
                AppSpacing.sm - 2,
              ));
    final itemSubtitle = subtitle;
    final itemMetadata = metadata ?? metadataOf(episode);

    final content = InkWell(
      borderRadius: borderRadius,
      onTap: enabled
          ? onTap ??
                () => open(
                  context,
                  episode,
                  relatedSeries: relatedSeries,
                  onOpen: onOpen,
                )
          : null,
      child: Padding(
        padding: contentPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                AppCover(
                  url: episode.imageUrl,
                  size: coverSize,
                  icon: placeholderIcon,
                ),
                const SizedBox(width: AppSpacing.item),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: enabled
                              ? (selected ? colors.primary : null)
                              : disabledColor,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (itemSubtitle != null && itemSubtitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          itemSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: enabled
                                    ? colors.onSurfaceVariant
                                    : disabledColor,
                                height: 1.3,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (itemMetadata.isNotEmpty || _hasActions) ...[
              const SizedBox(height: AppSpacing.xxs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (itemMetadata.isNotEmpty)
                    Expanded(
                      child: Text(
                        itemMetadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: enabled
                              ? colors.onSurfaceVariant
                              : disabledColor,
                          height: 1.35,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (_hasActions) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButtonTheme(
                      data: IconButtonThemeData(
                        style: IconButton.styleFrom(
                          minimumSize: AppSizes.compactIconButtonMin,
                          padding: AppInsets.compactIconButton,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onAddToQueue != null) _buildQueueButton(context),
                          if (onRemove != null) _buildRemoveButton(context),
                          if (_showsDownloadAction)
                            _buildDownloadButton(context),
                          if (_showsPlayAction)
                            _buildPlayButton(context, player!, isCurrent),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (embedded) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: selected
              ? colors.primaryContainer.withValues(alpha: .58)
              : AppColors.transparent,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return Card(
      margin: margin ?? EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  bool get _hasActions {
    return onAddToQueue != null ||
        onRemove != null ||
        _showsDownloadAction ||
        _showsPlayAction;
  }

  bool get _showsPlayAction {
    return onPlay != null || onPause != null;
  }

  bool get _showsDownloadAction {
    return onDownload != null ||
        onRemoveDownload != null ||
        isDownloaded ||
        isDownloadBusy;
  }

  Widget _buildQueueButton(BuildContext context) {
    return IconButton(
      tooltip: isQueued ? AppText.addedToQueueFull : AppText.addToQueueFull,
      icon: Icon(isQueued ? AppIcons.addedToQueue : AppIcons.addToQueue),
      onPressed: isQueued ? null : onAddToQueue,
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    return IconButton(
      tooltip: removeTooltip,
      icon: const Icon(AppIcons.remove),
      onPressed: onRemove,
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    final downloading = isDownloadBusy;
    final hasRemoveAction = onRemoveDownload != null;
    final tooltip = hasRemoveAction
        ? '删除下载'
        : (isDownloaded ? AppText.downloaded : AppText.download);
    final icon = downloading
        ? const SizedBox.square(
            dimension: AppSizes.indicator,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            hasRemoveAction
                ? AppIcons.trash
                : (isDownloaded ? AppIcons.downloadDone : AppIcons.download),
          );
    return IconButton(
      tooltip: downloading ? AppText.loading : tooltip,
      icon: icon,
      onPressed: downloading
          ? null
          : (hasRemoveAction
                ? onRemoveDownload
                : (isDownloaded ? null : onDownload)),
    );
  }

  Widget _buildPlayButton(
    BuildContext context,
    AudioPlayer player,
    bool isCurrent,
  ) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final processingState =
            state?.processingState ?? player.processingState;
        final playing =
            isPlaying || (isCurrent && (state?.playing ?? player.playing));
        final busy =
            isBusy ||
            (isCurrent &&
                (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) &&
                !playing);
        return IconButton(
          tooltip: busy
              ? AppText.loading
              : (playing ? AppText.pause : AppText.play),
          icon: busy
              ? const SizedBox.square(
                  dimension: AppSizes.indicator,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(playing ? AppIcons.pause : AppIcons.play),
          onPressed: busy ? null : (playing ? onPause : onPlay),
        );
      },
    );
  }
}
