import 'package:flutter/material.dart';

class AppListItem extends StatelessWidget {
  const AppListItem({
    super.key,
    required this.title,
    required this.metadata,
    this.coverUrl,
    this.coverSize = 56,
    this.actions = const [],
    this.onTap,
    this.placeholderIcon = Icons.podcasts,
    this.enabled = true,
  });

  final String title;
  final String metadata;
  final String? coverUrl;
  final double coverSize;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final IconData placeholderIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackActions = actions.length > 2 && constraints.maxWidth < 520;
        final details = Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: enabled ? null : Theme.of(context).disabledColor,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  metadata,
                  maxLines: stackActions ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: enabled
                        ? colors.onSurfaceVariant
                        : Theme.of(context).disabledColor,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        );
        final header = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppCover(url: coverUrl, size: coverSize, icon: placeholderIcon),
            const SizedBox(width: 12),
            details,
            if (actions.isNotEmpty && !stackActions) ...[
              const SizedBox(width: 6),
              Row(mainAxisSize: MainAxisSize.min, children: actions),
            ],
          ],
        );
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 8, stackActions ? 6 : 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  if (stackActions)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(icon),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(icon),
                ),
              ),
      ),
    );
  }
}
