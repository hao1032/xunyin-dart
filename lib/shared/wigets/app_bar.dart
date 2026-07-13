import 'package:flutter/material.dart';

import '../../features/player/pages/mini.dart';

class AppPageBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageBar({
    super.key,
    required this.title,
    this.actions,
    this.showMiniPlayer = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showMiniPlayer;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      titleSpacing: canPop ? 0 : null,
      title: showMiniPlayer
          ? _AppPageBarTitle(title)
          : Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions,
    );
  }
}

class _AppPageBarTitle extends StatelessWidget {
  const _AppPageBarTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleMaxWidth = (constraints.maxWidth * 0.42).clamp(72.0, 220.0);
        return Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: titleMaxWidth),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
            const Expanded(child: MiniPlayer(expand: true)),
          ],
        );
      },
    );
  }
}
