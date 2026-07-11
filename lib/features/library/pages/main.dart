import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_logger.dart';
import '../../../core/app_layout.dart';
import '../../player/pages/mini.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, this.showMiniPlayer = true});

  final bool showMiniPlayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资料库'),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                AppContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.tertiaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.graphic_eq_rounded,
                              size: 34,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              '你的声音空间',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            const Text('频道、收听历史与离线内容，都在这里。'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      const AppSectionTitle(
                        title: '我的内容',
                        subtitle: '管理订阅、历史记录和离线音频',
                      ),
                      const SizedBox(height: AppSpacing.item),
                      _LibraryActionCard(
                        icon: Icons.rss_feed_rounded,
                        title: '我的频道',
                        subtitle: '合集、UP主与 RSS 播客',
                        onTap: () {
                          AppLogger.userAction(
                            'open_subscriptions',
                            area: 'library',
                          );
                          context.push('/subscriptions');
                        },
                      ),
                      const SizedBox(height: 10),
                      _LibraryActionCard(
                        icon: Icons.history_rounded,
                        title: '收听历史',
                        subtitle: '继续最近播放的内容',
                        onTap: () {
                          AppLogger.userAction('open_history', area: 'library');
                          context.push('/history');
                        },
                      ),
                      const SizedBox(height: 10),
                      _LibraryActionCard(
                        icon: Icons.download_done_rounded,
                        title: '离线内容',
                        subtitle: '管理已下载的单集',
                        onTap: () {
                          AppLogger.userAction(
                            'open_download_management',
                            area: 'download',
                          );
                          context.push('/downloads');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showMiniPlayer) const MiniPlayer(),
        ],
      ),
    );
  }
}

class _LibraryActionCard extends StatelessWidget {
  const _LibraryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
