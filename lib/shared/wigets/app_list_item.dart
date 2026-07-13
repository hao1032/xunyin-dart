import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import 'cached_cover_image.dart';

class AppListItem extends StatelessWidget {
  const AppListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.metadata = '',
    this.coverUrl,
    this.coverSize = 56,
    this.actions = const [],
    this.onTap,
    this.placeholderIcon = AppIcons.podcast,
    this.enabled = true,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final String metadata;
  final String? coverUrl;
  final double coverSize;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final IconData placeholderIcon;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: compact ? AppSpacing.xxs : AppSpacing.xs + 1,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: compact
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.item,
                  AppSpacing.sm,
                  AppSpacing.item,
                  AppSpacing.xs,
                )
              : const EdgeInsets.fromLTRB(
                  AppSpacing.item,
                  AppSpacing.md,
                  AppSpacing.item,
                  AppSpacing.sm - 2,
                ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCover(
                    url: coverUrl,
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
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: enabled
                                    ? null
                                    : Theme.of(context).disabledColor,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: enabled
                                      ? colors.onSurfaceVariant
                                      : Theme.of(context).disabledColor,
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (metadata.isNotEmpty || actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (metadata.isNotEmpty)
                      Expanded(
                        child: Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: enabled
                                    ? colors.onSurfaceVariant
                                    : Theme.of(context).disabledColor,
                                height: 1.35,
                              ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (actions.isNotEmpty) ...[
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
                          children: actions,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppCover extends StatelessWidget {
  const AppCover({
    super.key,
    required this.url,
    required this.size,
    required this.icon,
    this.borderRadius = 0,
  });

  final String? url;
  final double size;
  final IconData icon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.square(
        dimension: size,
        child: CachedCoverImage(
          url: url,
          decodeLogicalSize: Size.square(size),
          placeholderBuilder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(icon),
          ),
          errorBuilder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}
