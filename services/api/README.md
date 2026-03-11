# api

Node.js + TypeScript 后端 API 服务目录。

当前状态：已升级为基于 Express 的 TypeScript API 服务骨架，并接入环境变量校验、lint、format、test 与 build 入口。
当前已补充 PostgreSQL schema 与首版 migration 机制，供 P2 核心数据闭环继续推进。

## 当前内容

- `src/index.ts`：服务入口
- `src/app.ts`：Express 应用装配
- `src/config/env.ts`：环境变量加载与校验
- `src/db/`：PostgreSQL 连接、migration runner 与 SQL migrations
- `src/routes/`：API 路由模块
- `test/health.test.ts`：健康检查与 404 行为测试
- `package.json` / `tsconfig*.json`：服务脚本与 TS 配置
- `eslint.config.mjs` / `.prettierrc.json`：代码质量入口

## 本地命令

- `corepack pnpm install`
- `npm run api:dev`
- `npm run api:start`
- `corepack pnpm --filter @overview/api db:migrate`
- `npm run api:lint`
- `npm run api:format`
- `npm run api:typecheck`
- `npm run api:test`
- `npm run api:build`

## 数据库迁移

1. 复制 `services/api/.env.example` 为本地环境文件并配置 `DATABASE_URL`
2. 确保本地 PostgreSQL 已启动且目标数据库已存在
3. 运行 `corepack pnpm --filter @overview/api db:migrate`

当前首个 migration 会创建 `planning_items` 表，用于承载日程、任务、备忘三类核心对象。
