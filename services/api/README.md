# api

Node.js + TypeScript 后端 API 服务目录。

当前状态：已升级为基于 Express 的 TypeScript API 服务骨架，并接入环境变量校验、lint、format、test 与 build 入口。
当前已补充 PostgreSQL schema、首版 migration 机制，以及日程、任务、备忘的核心 CRUD API。
当前也已补充邮箱注册/登录 API、密码哈希、session token 生成、受保护 planning 接口，以及带 OpenAI provider、Azure Speech 转写入口、通用 speech provider 抽象和稳定错误码的 AI 服务接口基础。

## 当前内容

- `src/index.ts`：服务入口
- `src/app.ts`：Express 应用装配
- `src/config/env.ts`：环境变量加载与校验
- `src/db/`：PostgreSQL 连接、migration runner 与 SQL migrations
- `src/auth/`：邮箱认证仓储、密码哈希与请求校验
- `src/ai/`：AI 服务抽象、OpenAI provider、speech provider 装配、Azure Speech 转写与请求校验
- `src/planning/`：规划对象仓储、请求校验与错误处理
- `src/routes/`：API 路由模块
- `test/health.test.ts` / `test/auth.test.ts` / `test/planning.test.ts` / `test/ai.test.ts`：健康检查、认证、CRUD、AI 路由与 404/400 行为测试
- `package.json` / `tsconfig*.json`：服务脚本与 TS 配置
- `eslint.config.mjs` / `.prettierrc.json`：代码质量入口

## 本地命令

- `npx pnpm install`
- `npm run api:dev`
- `npm run api:start`
- `npm run api:start:embedded`
- `npx pnpm --filter @overview/api db:migrate`
- `npm run api:lint`
- `npm run api:format`
- `npm run api:typecheck`
- `npm run api:test`
- `npm run api:build`

## 快速启动

1. 复制环境变量模板：

```bash
cp services/api/.env.example services/api/.env
```

2. 如需真实 PostgreSQL，修改 `DATABASE_URL`

3. 执行 migration：

```bash
npx pnpm --filter @overview/api db:migrate
```

4. 启动服务：

```bash
npm run api:start
```

如本机没有可用 PostgreSQL，可直接使用：

```bash
npm run api:start:embedded
```

默认监听：

- `http://127.0.0.1:3000`
- `GET /health`

说明：

- `api:start` 仍要求 `.env` 中的 `DATABASE_URL` 指向可连接 PostgreSQL
- `api:start:embedded` 会自动启动临时嵌入式 PostgreSQL、执行 migration 并启动 API，适合本地开发与交付验证

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
- `POST /ai/ingest/text`
- `POST /ai/ask`
- `POST /ai/transcribe`

## 认证说明

- `/auth/register` 与 `/auth/login` 返回 `token`、`expiresAt` 和 `user`
- `/planning/*` 与 `/ai/*` 现在要求请求头携带 `Authorization: Bearer <token>`
- planning 数据和 AI 可访问的数据按当前登录用户隔离；未授权或 token 失效时返回 `401`

## AI 说明

- `/ai/ingest/text` 接收自然语言文本，返回结构化建议对象与待确认字段
- `/ai/ask` 接收单轮问题，返回基于当前用户 planning 数据的回答
- `/ai/transcribe` 接收 Base64 编码的短音频和 locale，当前默认使用 Azure Speech 转写后返回文本结果
- AI 错误响应现在会返回稳定 `code`，客户端可据此映射本地化提示与恢复动作
- `AI_PROVIDER=auto` 时，若存在 `OPENAI_API_KEY` 则优先使用 OpenAI，否则回退到仓库内 heuristic provider
- `AI_SPEECH_PROVIDER` 当前支持 `azure` 与 `none`；当前正式选型是 `azure`
- 可显式设置 `AI_PROVIDER=openai` 强制启用 OpenAI；此时若缺少 `OPENAI_API_KEY` 会在启动阶段快速失败
- `OPENAI_MODEL` 默认使用 `gpt-4.1-mini`
- 配置 `AZURE_SPEECH_KEY` 与 `AZURE_SPEECH_REGION` 后可启用语音转写；`AZURE_SPEECH_LOCALE` 默认是 `zh-CN`
- 服务端会把输入 locale 规范化为适合语音服务的 BCP-47 值，当前已覆盖中文、英文及部分后续扩展语言默认映射
