import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_none),
              title: const Text('播放通知'),
              subtitle: const Text('准备好后可在这里管理播放相关偏好'),
              value: true,
              onChanged: null,
            ),
          ),
          const SizedBox(height: 8),
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
