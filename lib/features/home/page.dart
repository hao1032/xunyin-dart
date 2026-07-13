import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_constants.dart';
import '../discover/pages/main.dart';
import '../player/pages/queue.dart';
import '../settings/page.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  late var _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          QueuePage(),
          DiscoverPage(showSettingsAction: false),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(AppIcons.queueOutlined),
              selectedIcon: Icon(AppIcons.queue),
              label: AppText.playlistTitle,
            ),
            NavigationDestination(
              icon: Icon(AppIcons.explore),
              selectedIcon: Icon(AppIcons.exploreSelected),
              label: AppText.discoverTitle,
            ),
            NavigationDestination(
              icon: Icon(AppIcons.settings),
              selectedIcon: Icon(AppIcons.settingsSelected),
              label: AppText.settingsTitle,
            ),
          ],
        ),
      ),
    );
  }
}
