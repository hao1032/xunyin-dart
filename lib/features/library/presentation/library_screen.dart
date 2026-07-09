import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../player/presentation/mini_player.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('资料库')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.subscriptions_outlined),
                    title: const Text('订阅'),
                    subtitle: const Text('查看和管理已订阅内容'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      AppLogger.userAction(
                        'open_subscriptions',
                        area: 'library',
                      );
                      context.push('/subscriptions');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('历史记录'),
                    subtitle: const Text('查看播放过的单集'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      AppLogger.userAction('open_history', area: 'library');
                      context.push('/history');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.offline_pin_outlined),
                    title: const Text('缓存管理'),
                    subtitle: const Text('查看和删除本地缓存'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      AppLogger.userAction(
                        'open_cache_management',
                        area: 'cache',
                      );
                      context.push('/cache');
                    },
                  ),
                ),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
