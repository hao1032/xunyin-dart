# SQLite 数据库设计

本文记录寻音已经确认的本地数据模型。应用只有一个层级化播放列表，不支持多个命名播放列表。

## 设计结论

- 使用 Drift 管理 SQLite。
- 只持久化 `series`、`episodes`、`downloads` 三张表。
- 顶级播放项可以是一个 `series`，也可以是一个独立 `episode`。
- 属于 series 的 episode 在界面和播放顺序中都是该 series 的子项；`series_id` 为空表示顶级独立单集。
- series 与独立 episode 共用顶级排序空间。
- 同一远端单集可独立出现一次，也可在每个 series 上下文中各出现一次。
- B 站和 RSS 是内容来源类型。Apple Podcasts 仅是发现来源，最终解析为 RSS，不作为持久化内容来源。

时间字段在 Dart 中使用 `DateTime`，Drift 默认以 UTC Unix 秒级时间戳保存到 SQLite。布尔值在 Dart 中使用 `bool`，Drift 保存为 SQLite 整数值（`0` 与 `1`）。

## 数据表

```sql
CREATE TABLE series (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  source_type TEXT NOT NULL
    CHECK (source_type IN ('bilibili', 'rss')),
  series_kind TEXT NOT NULL
    CHECK (series_kind IN (
      'bilibili_creator',
      'bilibili_collection',
      'rss_podcast'
    )),
  source_series_id TEXT NOT NULL,

  -- 顶级播放项中的位置。
  sort_order INTEGER NOT NULL,

  title TEXT NOT NULL,
  author TEXT,
  description TEXT,
  image_url TEXT,
  original_url TEXT,
  feed_url TEXT,

  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,

  UNIQUE (source_type, series_kind, source_series_id)
);

CREATE TABLE episodes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  -- 为空时表示顶级独立单集。
  series_id INTEGER NULL
    REFERENCES series(id) ON DELETE CASCADE,

  source_type TEXT NOT NULL
    CHECK (source_type IN ('bilibili', 'rss')),
  source_episode_id TEXT NOT NULL,

  -- 独立单集使用顶级位置；series 子单集使用该 series 内的位置。
  sort_order INTEGER NOT NULL,

  title TEXT NOT NULL,
  author TEXT,
  description TEXT,
  image_url TEXT,
  original_url TEXT,

  audio_url TEXT,
  video_url TEXT,
  duration_ms INTEGER,
  audio_bytes INTEGER,
  published_at INTEGER,

  bilibili_bvid TEXT,
  bilibili_aid INTEGER,
  bilibili_cid INTEGER,
  bilibili_page INTEGER,

  progress_ms INTEGER NOT NULL DEFAULT 0,
  last_played_at INTEGER,
  is_completed INTEGER NOT NULL DEFAULT 0
    CHECK (is_completed IN (0, 1)),

  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE downloads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  -- 标识实际媒体，不受其播放列表上下文影响。
  source_type TEXT NOT NULL
    CHECK (source_type IN ('bilibili', 'rss')),
  source_episode_id TEXT NOT NULL,

  -- 下载完成前为空；完成后为本地媒体文件路径。
  file_path TEXT,
  -- 实际写入本地文件的字节数；下载完成前为空。
  bytes INTEGER,
  status TEXT NOT NULL DEFAULT 'downloading'
    CHECK (status IN ('downloading', 'complete', 'failed')),
  error_message TEXT,
  downloaded_at INTEGER,

  UNIQUE (source_type, source_episode_id)
);
```

## 索引与约束

```sql
CREATE INDEX series_top_level_order
ON series(sort_order, id);

CREATE INDEX episodes_top_level_order
ON episodes(sort_order, id)
WHERE series_id IS NULL;

CREATE INDEX episodes_series_order
ON episodes(series_id, sort_order, id)
WHERE series_id IS NOT NULL;

CREATE INDEX episodes_series_last_played
ON episodes(series_id, last_played_at DESC);

CREATE UNIQUE INDEX episodes_unique_standalone
ON episodes(source_type, source_episode_id)
WHERE series_id IS NULL;

CREATE UNIQUE INDEX episodes_unique_in_series
ON episodes(series_id, source_type, source_episode_id)
WHERE series_id IS NOT NULL;
```

repository 在事务中分配和重排 `sort_order`。顶级 series 与独立 episode 共用排序空间，SQLite 无法跨表保证排序值唯一，因此由 repository 维护该约束。

## 身份与媒体规则

- B 站 `source_episode_id` 使用 `"$bvid:$cid"`；视频的每个分 P 都有独立的 `cid`。B 站专用字段保留用于解析播放流的原始 ID。
- RSS `source_episode_id` 优先使用 feed 的 `guid`，缺失时使用 enclosure URL 的稳定哈希。
- `audio_url` 与 `video_url` 是可选的已解析播放地址。RSS 地址通常可以持久化；B 站地址可能过期，播放时仍需通过 `bilibili_bvid` 和 `bilibili_cid` 解析新地址。
- `episodes.audio_bytes` 是远端音频声明的大小，例如 RSS enclosure 的 `length`；它可为空且不保证与实际下载大小一致。`downloads.bytes` 是实际写入本地文件的大小。
- 下载以来源身份而不是本地 `episodes.id` 为键，因此独立单集和 series 内单集可以复用同一个本地文件。
- 下载开始时创建 `downloads` 记录，状态为 `downloading`；成功后写入 `file_path`、`bytes`、`downloaded_at` 并改为 `complete`；失败时改为 `failed` 并写入 `error_message`。
- series 最近播放的单集通过 `WHERE series_id = ? ORDER BY last_played_at DESC LIMIT 1` 查询，不在 `series` 中重复存储。
- 播放达到完成阈值时设置 `is_completed`，用于完成状态展示、断点续播和后续筛选。

## 播放列表投影

顶级界面合并排序后的 `series` 与独立 `episodes`。展开 series 时，按其子 episode 的 `sort_order` 显示。播放器按相同层级规则展平为播放顺序。

删除 series 时会级联删除其 episode 上下文。`downloads` 不关联 episode 外键，repository 必须清理不再被任一 episode 上下文引用的下载记录和本地文件。

## Drift 实现约定

第一版 Drift 数据库的源码结构如下：

```text
lib/
  core/database/
    app_database.dart         # AppDatabase、schema 版本、迁移与索引。
    database_connection.dart  # 生产环境 SQLite 连接。
  features/
    series/table.dart         # series 表。
    episode/table.dart        # episodes 表。
    downloads/table.dart      # downloads 表。
```

- 数据库文件名为 `xunyin.sqlite`，由 `drift_flutter` 保存到操作系统提供的应用私有数据目录，不纳入 Git。
- `AppDatabase` 的 `schemaVersion` 从 `1` 开始；不导入旧 JSON 数据。
- 三张表使用 SQLite 自增整数 `id` 作为主键。`episodes.series_id` 是可空外键，删除 series 时级联删除其子单集。
- 部分唯一索引与排序索引通过建库时的自定义 SQL 创建；顶级跨表排序的唯一性仍由后续 Repository 在事务中维护。
- Drift 的 `app_database.g.dart` 是生成代码，纳入 Git；修改表定义后需要运行 `dart run build_runner build`。
- 本阶段只建立数据库基础设施。Repository、Riverpod Provider、页面迁移与旧 JSON 删除将在后续阶段实现。
