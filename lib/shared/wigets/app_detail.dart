import 'package:flutter/material.dart';

import '../../core/app_layout.dart';
import 'detail_cover.dart';

class AppDetail extends StatelessWidget {
  const AppDetail({
    super.key,
    required this.title,
    this.coverUrl,
    this.coverIcon = Icons.podcasts,
    this.coverMaxContentWidth = 520,
    this.metadata,
    this.subtitle,
    this.actions,
    this.actionStatus,
    this.description,
    this.descriptionTitle = '简介',
    this.children = const [],
  });

  final String title;
  final String? coverUrl;
  final IconData coverIcon;
  final double coverMaxContentWidth;
  final String? metadata;
  final Widget? subtitle;
  final Widget? actions;
  final Widget? actionStatus;
  final String? description;
  final String descriptionTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDetailCover(
          url: coverUrl,
          icon: coverIcon,
          maxContentWidth: coverMaxContentWidth,
        ),
        const SizedBox(height: 22),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (metadata != null && metadata!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            metadata!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (subtitle != null) ...[const SizedBox(height: 10), subtitle!],
        if (actions != null) ...[const SizedBox(height: 22), actions!],
        if (actionStatus != null) ...[
          const SizedBox(height: 12),
          actionStatus!,
        ],
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          AppSectionTitle(title: descriptionTitle),
          const SizedBox(height: 10),
          Text(description!, style: const TextStyle(height: 1.6)),
        ],
        ...children,
      ],
    );
  }
}

class AppDetailEpisodeList extends StatelessWidget {
  const AppDetailEpisodeList({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.loading = false,
    this.error,
    this.errorTitle,
    this.onRetry,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final bool loading;
  final Object? error;
  final String? errorTitle;
  final VoidCallback? onRetry;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        AppSectionTitle(title: title, subtitle: loading ? '正在加载' : subtitle),
        const SizedBox(height: 10),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (error != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(errorTitle ?? '$title加载失败'),
              subtitle: Text(error.toString()),
              trailing: onRetry == null
                  ? null
                  : TextButton(onPressed: onRetry, child: const Text('重试')),
            ),
          ),
        ...children,
        if (footer != null) ...[const SizedBox(height: 12), footer!],
      ],
    );
  }
}
