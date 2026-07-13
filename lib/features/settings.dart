import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_logger.dart';
import '../core/app_layout.dart';
import '../shared/wigets/app_action_card.dart';
import '../shared/wigets/app_bar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: showAppBar ? const AppPageBar(title: '设置') : null,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionTitle(title: '内容', subtitle: '管理订阅、历史和下载'),
                const SizedBox(height: AppSpacing.item),
                AppActionCard(
                  icon: Icons.rss_feed_rounded,
                  title: '订阅',
                  subtitle: '合集、UP主与 RSS 播客',
                  onTap: () {
                    AppLogger.userAction('open_channels', area: 'settings');
                    context.push('/subscriptions');
                  },
                ),
                const SizedBox(height: 10),
                AppActionCard(
                  icon: Icons.history_rounded,
                  title: '历史',
                  subtitle: '继续最近播放的单集',
                  onTap: () {
                    AppLogger.userAction('open_history', area: 'settings');
                    context.push('/history');
                  },
                ),
                const SizedBox(height: 10),
                AppActionCard(
                  icon: Icons.file_download_done_rounded,
                  title: '下载',
                  subtitle: '查看和删除已下载单集',
                  onTap: () {
                    AppLogger.userAction(
                      'open_download_management',
                      area: 'download',
                    );
                    context.push('/downloads');
                  },
                ),
                const SizedBox(height: AppSpacing.section),
                const AppSectionTitle(title: '偏好'),
                const SizedBox(height: AppSpacing.item),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications_none),
                    title: const Text('播放通知'),
                    subtitle: const Text('准备好后可在这里管理播放相关偏好'),
                    value: true,
                    onChanged: null,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('关于寻音'),
                    subtitle: const Text('搜索 B站视频与播客，并整理为播放列表'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
