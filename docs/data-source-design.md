# 数据源与 Debug 页面设计

本文记录在实现 Repository 和正式页面之前，内容如何从网络读取到应用的已确认约定。

## 目标与边界

- 新代码从 `lib/` 重新实现，不复用、导入或修改 `lib2/` 中的客户端、模型、Repository 或 Provider。
- 第一阶段先建立可复用的数据源接口，并用 debug 页面验证真实网络请求。
- 本阶段只读网络数据，不向 Drift 的 `series`、`episodes` 或 `downloads` 写入数据。
- 后续的导入 Repository、正式发现页和播放器都复用本阶段的数据源接口与远端模型。

## 内容来源

持久化内容来源仍然只有 `bilibili` 与 `rss`。

Apple Podcasts 只作为播客目录服务：用于关键词搜索和发现 RSS Feed URL。Apple 搜索结果不能直接写入数据库；加载其 `feedUrl` 并解析后，内容才是 `rss` 来源。

## 数据源接口

### B 站

在 `features/bilibili/` 中定义 B 站客户端及其独立远端模型。

- `searchVideos(keyword)`：按关键词返回视频搜索结果。
- `getVideoDetail(bvid)`：返回视频详情、所有分 P，以及可识别的合集信息。
- 模型保留后续功能需要的原始身份：`bvid`、`aid`、`cid`、`page`。
- 搜索与详情请求重新实现 WBI 签名、必要请求头和错误转换。

第一版只支持视频搜索和视频详情，不实现 UP 主视频列表、合集订阅或音视频播放地址解析。

### Apple Podcasts 与 RSS

在 `features/podcast/` 中分别实现 Apple Podcasts 客户端、RSS 客户端与 RSS 解析器。

- `ApplePodcastClient.search(keyword)`：调用 iTunes Search API，返回播客标题、作者、封面、详情页和 `feedUrl`。
- `RssClient.loadFeed(feedUrl)`：下载 Feed XML。
- `RssParser`：解析播客元数据和单集，提供标题、作者、描述、封面、发布时间、时长、`audioUrl` 与 `audioBytes`。
- RSS 单集身份优先使用 `guid`；若无 `guid`，使用 enclosure URL 的 SHA-256 作为稳定身份。

RSS 响应为 HTML、XML 无效、缺少 `channel` 或单集没有音频地址时，应返回可展示的明确错误。

## Debug 页面

在 `features/debug/` 实现新的应用首屏，用于验证数据源接口，不承担导入或正式产品流程。

- 页面包含 `B站` 与 `播客` 两个 Tab、关键词输入框及搜索操作。
- B 站搜索结果点击后加载并展示视频详情、分 P 与可识别合集信息。
- 播客搜索结果点击后使用其 `feedUrl` 加载并展示 RSS 播客元数据和单集列表。
- 页面需处理初始、加载、空结果和错误状态。
- 使用 Riverpod 仅进行 `Dio` 和客户端的依赖注入；业务查询流与写入命令 Provider 留到后续阶段。

## 代码组织

```text
lib/
  core/
    http_client.dart             # Dio 配置和公共请求头。
  features/
    bilibili/                    # 搜索、视频详情、远端模型与客户端。
    podcast/                     # Apple 搜索、RSS 请求、RSS 解析与远端模型。
    debug/                       # 只读数据源验证页面。
  main.dart                      # 以 debug 页面作为当前应用入口。
```

## 后续阶段

完成数据源验证后，再实现 Repository 和 Riverpod 业务状态：

1. 将远端模型转换为 Drift 的 `series` 与 `episodes` 记录，并维护 `sort_order` 与去重规则。
2. 提供播放列表、series 单集、下载状态的查询流与写入命令。
3. 建立正式发现页、播放列表页和播放器；B 站播放时再按 `bvid` 与 `cid` 解析可能过期的媒体地址。
