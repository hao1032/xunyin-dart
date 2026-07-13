import 'package:flutter/material.dart';

abstract final class AppColors {
  static const seed = Color(0xff6750a4);
  static const transparent = Colors.transparent;
}

abstract final class AppRadii {
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 10.0;
}

abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 10.0;
  static const item = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const page = 20.0;
  static const xxl = 24.0;
  static const section = 28.0;
  static const emptyState = 32.0;
}

abstract final class AppSizes {
  static const buttonMin = Size(48, 48);
  static const iconButtonMin = Size.square(48);
  static const compactIconButtonMin = Size.square(36);
  static const indicator = 18.0;
  static const emptyStateIconBox = 72.0;
  static const emptyStateIcon = 32.0;
  static const actionIconBox = 44.0;
  static const detailPageMaxWidth = 620.0;
  static const seriesPageMaxWidth = 760.0;
  static const contentMaxWidth = 720.0;
}

abstract final class AppInsets {
  static const zero = EdgeInsets.zero;
  static const page = EdgeInsets.fromLTRB(
    AppSpacing.page,
    AppSpacing.sm,
    AppSpacing.page,
    AppSpacing.section,
  );
  static const detailPage = EdgeInsets.fromLTRB(
    AppSpacing.page,
    AppSpacing.sm,
    AppSpacing.page,
    AppSpacing.emptyState,
  );
  static const button = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.item,
  );
  static const iconButton = EdgeInsets.all(AppSpacing.sm);
  static const compactIconButton = EdgeInsets.all(AppSpacing.sm - 2);
  static const input = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
  static const actionCard = EdgeInsets.all(14);
  static const emptyState = EdgeInsets.all(AppSpacing.emptyState);
}

abstract final class AppIcons {
  static const addToQueue = Icons.playlist_add;
  static const addedToQueue = Icons.playlist_add_check_rounded;
  static const back = Icons.navigate_before;
  static const blocked = Icons.block;
  static const checkDownload = Icons.file_download_done_rounded;
  static const chevronRight = Icons.chevron_right_rounded;
  static const download = Icons.download_outlined;
  static const downloadDone = Icons.file_download_done_rounded;
  static const error = Icons.error_outline;
  static const expandMore = Icons.expand_more_rounded;
  static const explore = Icons.explore_outlined;
  static const exploreSelected = Icons.explore_rounded;
  static const history = Icons.history_rounded;
  static const info = Icons.info_outline;
  static const music = Icons.music_note;
  static const next = Icons.navigate_next;
  static const notifications = Icons.notifications_none;
  static const notificationsActive = Icons.notifications_active_outlined;
  static const pause = Icons.pause_rounded;
  static const play = Icons.play_arrow;
  static const playRounded = Icons.play_arrow_rounded;
  static const podcast = Icons.podcasts;
  static const podcasts = Icons.podcasts_rounded;
  static const queue = Icons.queue_music_rounded;
  static const queueOutlined = Icons.queue_music_outlined;
  static const refresh = Icons.refresh;
  static const remove = Icons.remove_circle_outline_rounded;
  static const replay10 = Icons.replay_10;
  static const rss = Icons.rss_feed_rounded;
  static const search = Icons.search_rounded;
  static const settings = Icons.settings_outlined;
  static const settingsSelected = Icons.settings_rounded;
  static const submit = Icons.arrow_forward_rounded;
  static const forward10 = Icons.forward_10;
  static const trash = Icons.delete_outline;
  static const user = Icons.person;
  static const userRounded = Icons.person_rounded;
  static const videoLibrary = Icons.video_library_rounded;
  static const waves = Icons.waves_rounded;
}

abstract final class AppText {
  static const appName = '寻音';
  static const detailTitle = '详情';
  static const settingsTitle = '设置';
  static const discoverTitle = '发现';
  static const nowPlayingTitle = '正在播放';
  static const playlistTitle = '播放列表';
  static const descriptionTitle = '简介';
  static const episodesTitle = '单集';
  static const retry = '重试';
  static const loading = '加载中';
  static const loadingMore = '加载更多';
  static const loadingContent = '正在加载';
  static const play = '播放';
  static const pause = '暂停';
  static const preparingPlayback = '准备播放';
  static const addToQueue = '加入列表';
  static const addToQueueFull = '加入播放列表';
  static const addedToQueue = '已加入';
  static const addedToQueueFull = '已加入播放列表';
  static const download = '下载到本地';
  static const downloaded = '已下载';
  static const downloadedLocal = '已下载到本地';
  static const checkDownload = '检查下载';
  static const downloading = '下载中';
  static const readDownload = '读取下载';
  static const settings = '设置';
  static const search = '搜索';
  static const searchHint = '搜索视频、UP主或播客';
}
