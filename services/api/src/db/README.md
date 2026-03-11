# db

Overview API 的数据库接入与迁移目录。

## 当前内容

- `client.ts`：基于 `pg` 的 PostgreSQL 连接配置
- `migrate.ts`：顺序执行 SQL migration 的 runner
- `migrations/`：按版本号排序的 SQL migration 文件

## 约定

- migration 文件名使用 `0001_name.sql` 形式
- 迁移记录默认写入 `${DATABASE_SCHEMA}.schema_migrations`
- 当前核心表为 `planning_items`，先承载日程、任务、备忘三类对象
