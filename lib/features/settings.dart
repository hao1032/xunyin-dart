import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_logger.dart';
import '../shared/wigets/app_action_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          AppActionCard(
            icon: Icons.subscriptions_outlined,
            title: '订阅',
            subtitle: '查看和管理已订阅内容',
            onTap: () {
              AppLogger.userAction('open_subscriptions', area: 'library');
              context.push('/subscriptions');
            },
          ),
          const SizedBox(height: 8),
          AppActionCard(
            icon: Icons.history,
            title: '历史记录',
            subtitle: '查看播放过的单集',
            onTap: () {
              AppLogger.userAction('open_history', area: 'library');
              context.push('/history');
            },
          ),
          const SizedBox(height: 8),
          AppActionCard(
            icon: Icons.offline_pin_outlined,
            title: '下载管理',
            subtitle: '查看和删除已下载单集',
            onTap: () {
              AppLogger.userAction(
                'open_download_management',
                area: 'download',
              );
              context.push('/downloads');
            },
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_none),
              title: const Text('播放通知'),
              subtitle: const Text('准备好后可在这里管理播放相关偏好'),
              value: true,
              onChanged: null,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于寻音'),
              subtitle: const Text('搜索 B站视频与播客，并整理为播放列表'),
            ),
          ),
        ],
      ),
    );
  }
}
