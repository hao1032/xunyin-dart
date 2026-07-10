import 'package:flutter/material.dart';

class AudioListItem extends StatelessWidget {
  const AudioListItem({
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
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AudioCover(
                url: coverUrl,
                size: coverSize,
                icon: placeholderIcon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: enabled ? null : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: enabled
                        ? colors.onSurfaceVariant
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: content,
      ),
    );
  }
}

String formatAudioDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatAudioRelativeDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final today = DateUtils.dateOnly(DateTime.now());
  final day = DateUtils.dateOnly(local);
  final days = today.difference(day).inDays;
  if (days == 0) return '今天';
  if (days == 1) return '昨天';
  if (days > 1 && days < 7) return '$days天前';
  if (days >= 7 && days < 30) return '${days ~/ 7}周前';
  if (days >= 30 && days < 365) return '${days ~/ 30}个月前';
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

class _AudioCover extends StatelessWidget {
  const _AudioCover({
    required this.url,
    required this.size,
    required this.icon,
  });

  final String? url;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(icon),
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}
