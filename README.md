# 寻音

寻音是一个 Flutter 音频应用，用来搜索、整理和播放 B 站视频与播客内容。它把 B站合集、B站UP主和 RSS 播客统一成「频道」，把视频、分 P 与播客单集统一成「单集」，让不同来源的长内容拥有一致的订阅、播放和缓存体验。

## 功能概览

- 搜索 B 站视频、Apple Podcast，或同时搜索全部来源。
- 将 B 站单视频、分 P 视频、UGC 合集解析为可播放频道与单集。
- 支持从 Apple Podcast 搜索结果加载 RSS feed 并解析节目单集。
- 播放音频内容，支持播放列表、迷你播放器和独立播放页。
- 自动记录播放历史与播放进度，下次播放时恢复位置。
- 支持在同一级别订阅 B站合集、B站UP主与 RSS 播客频道。
- 查看历史记录、管理本地音频缓存。
- B 站音频播放和缓存会按需解析真实音频地址，并带上必要请求头。
- macOS 运行时使用接近移动端的固定窗口尺寸，便于调试移动体验。

## 技术栈

- Flutter / Dart
- Riverpod：依赖注入与状态管理
- go_router：页面路由
- Dio：HTTP 请求与文件下载
- just_audio / audio_session：音频播放与系统音频会话
- xml：RSS 解析
- path_provider：应用数据与缓存目录
- window_manager：macOS 桌面窗口控制

## 运行项目

确认本机已安装 Flutter，并且 SDK 版本满足 `pubspec.yaml` 中的要求。

```sh
flutter pub get
flutter run
```

运行到指定平台：

```sh
flutter run -d macos
flutter run -d android
flutter run -d ios
```

## 打包应用

```sh
flutter build apk --release
```

## 测试

```sh
flutter test
```

当前测试覆盖了：

- RSS feed 解析
- Apple Podcast 搜索响应解析
- B 站搜索结果清洗
- B 站单视频、分 P、合集、UP 主投稿到节目模型的转换

## 目录结构

```text
lib/
  core/
    app.dart                 # 应用入口组件
    theme/                   # Material 3 明暗主题
    formatters/              # 共享时间与时长格式化
    errors/                  # 应用错误模型
    logging/                 # 结构化日志
    network/                 # Dio 客户端
    routing/                 # go_router 路由
    storage/                 # JSON 本地存储
    text/                    # 文本清洗工具
  features/
    audio/                   # 通用音频组件
    bilibili/services/       # B 站接口与数据转换
    cache/                   # 音频缓存
    channel/                 # 跨来源统一频道模型与加载服务
    home/                    # 底部导航主界面
    library/                 # 频道、历史与播放进度
    player/                  # 播放器、播放队列、B 站音频源
    podcast/                 # 单集模型、RSS 与 Apple Podcast
    search/                  # 搜索页面与聚合服务
    settings/                # 设置页
test/                        # 数据层和解析逻辑测试
```

## 本地数据

应用通过 `path_provider` 获取平台应用支持目录，并以 JSON 文件保存资料库数据：

- `subscriptions.json`：订阅节目
- `history.json`：播放历史
- `cached_episodes.json`：缓存单集索引
- `playback_positions.json`：播放进度

音频文件缓存在应用支持目录下的 `cache/audio` 中。删除应用数据会清空这些本地记录和缓存文件。

## 开发提示

- 搜索入口位于 `SearchPage`，数据聚合逻辑在 `SearchRepository`。
- B 站相关解析集中在 `BilibiliRepository`，底层请求在 `BilibiliClient`。
- 播客 RSS 加载和解析由 `PodcastRepository` 与 `RssParser` 负责。
- 跨来源频道加载集中在 `ChannelService`，页面不再分别判断 B站UP主或 RSS 播客。
- 播放控制集中在 `PlaybackController`，它负责解析音频地址、恢复进度、记录历史和优先播放本地缓存。
- 本地资料库写入通过 `LibraryRepository` 和 `LibraryStore` 完成。

## 项目状态

项目已完成跨来源频道模型和主要收听链路，当前重点是继续完善真实设备体验、频道发现能力与播放稳定性。
