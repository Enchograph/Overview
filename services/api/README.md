# api

Node.js + TypeScript 后端 API 服务目录。

当前状态：已升级为基于 Express 的 TypeScript API 服务骨架，并接入环境变量校验、lint、format、test 与 build 入口。
当前已补充 PostgreSQL schema、首版 migration 机制，以及日程、任务、备忘的核心 CRUD API。
当前也已补充邮箱注册/登录 API、密码哈希、session token 生成，以及受保护 planning 接口。

## 当前内容

- `src/index.ts`：服务入口
- `src/app.ts`：Express 应用装配
- `src/config/env.ts`：环境变量加载与校验
- `src/db/`：PostgreSQL 连接、migration runner 与 SQL migrations
- `src/auth/`：邮箱认证仓储、密码哈希与请求校验
- `src/planning/`：规划对象仓储、请求校验与错误处理
- `src/routes/`：API 路由模块
- `test/health.test.ts` / `test/auth.test.ts` / `test/planning.test.ts`：健康检查、认证、CRUD 路由与 404/400 行为测试
- `package.json` / `tsconfig*.json`：服务脚本与 TS 配置
- `eslint.config.mjs` / `.prettierrc.json`：代码质量入口

## 本地命令

- `npx pnpm install`
- `npm run api:dev`
- `npm run api:start`
- `npx pnpm --filter @overview/api db:migrate`
- `npm run api:lint`
- `npm run api:format`
- `npm run api:typecheck`
- `npm run api:test`
- `npm run api:build`

## 数据库迁移

1. 复制 `services/api/.env.example` 为本地环境文件并配置 `DATABASE_URL`
2. 确保本地 PostgreSQL 已启动且目标数据库已存在
3. 运行 `npx pnpm --filter @overview/api db:migrate`

当前首个 migration 会创建 `planning_items` 表，用于承载日程、任务、备忘三类核心对象。
第二个 migration 会创建 `users` 与 `auth_sessions` 表，用于承载邮箱认证与 session token。

## 自动化烟测

- `npm run api:test` 现在会额外执行 `test/postgres.smoke.test.ts`
- 该烟测会自动准备 `@embedded-postgres/linux-x64` 所需的动态库链接，启动嵌入式 PostgreSQL、执行 migration，并验证 `/auth/*` 与 `/planning/*` 的 PostgreSQL-backed 流程

## 当前 API

- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `GET|POST /planning/schedules`
- `GET|PATCH|DELETE /planning/schedules/:id`
- `GET|POST /planning/tasks`
- `GET|PATCH|DELETE /planning/tasks/:id`
- `GET|POST /planning/memos`
- `GET|PATCH|DELETE /planning/memos/:id`

## 认证说明

- `/auth/register` 与 `/auth/login` 返回 `token`、`expiresAt` 和 `user`
- `/planning/*` 现在要求请求头携带 `Authorization: Bearer <token>`
- planning 数据按当前登录用户隔离；未授权或 token 失效时返回 `401`
