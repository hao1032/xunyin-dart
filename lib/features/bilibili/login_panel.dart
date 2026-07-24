import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'session_store.dart';

class BilibiliLoginPanel extends StatelessWidget {
  const BilibiliLoginPanel({
    required this.loggedIn,
    required this.checking,
    required this.qrCode,
    required this.state,
    required this.error,
    required this.onStart,
    required this.onLogout,
    super.key,
  });

  final bool loggedIn;
  final bool checking;
  final BilibiliQrCode? qrCode;
  final BilibiliQrLoginState? state;
  final String? error;
  final VoidCallback onStart;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('B站登录', style: textTheme.titleLarge),
        if (checking) const Text('正在检查登录状态'),
        if (!checking && loggedIn) ...[
          const Text('已登录，本机请求将携带已保存会话。'),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            tooltip: '退出 B站登录',
          ),
        ],
        if (!checking && !loggedIn) ...[
          if (qrCode == null)
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('获取登录二维码'),
            ),
          if (qrCode != null) ...[
            Center(child: QrImageView(data: qrCode!.url, size: 200)),
            Text(_stateText(state)),
            OutlinedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新二维码'),
            ),
          ],
          const Text('登录会话将以明文保存在本机应用数据目录。'),
        ],
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  String _stateText(BilibiliQrLoginState? value) => switch (value) {
    BilibiliQrLoginState.waitingForScan => '请使用 B站 App 扫码',
    BilibiliQrLoginState.waitingForConfirm => '已扫码，请在 B站 App 确认',
    BilibiliQrLoginState.succeeded => '登录成功',
    BilibiliQrLoginState.expired => '二维码已过期，请刷新',
    null => '',
  };
}
