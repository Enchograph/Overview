# Overview 项目状态

## 当前状态

- 状态：进行中
- 当前阶段：P2 核心数据闭环
- 当前功能块：已完成客户端页面数据接入与基础状态管理，开始建立本地存储
- 最后更新：2026-03-11

## 已完成

- 产品需求文档初版已建立
- 项目执行原则、阶段路线图与任务体系已确定
- 治理层文档已写入仓库
- 基础目录骨架已建立
- 固定接力提示词已建立
- 高风险命令审批规则已纳入治理层
- 已确定根级 monorepo 管理方式为 `pnpm workspace`
- 已建立根级 `package.json` 与 `pnpm-workspace.yaml`
- 已建立 `packages/shared` 基础健康检查契约
- 已建立 `services/api` 零依赖 TypeScript 最小服务与 `/health` 测试
- 已完成 `apps/client` Flutter Android 工程初始化
- 已通过客户端最小验证：`flutter analyze`、`flutter test`
- 已完成客户端命名路由、四个主页面骨架与 AI/同步子路由
- 已完成手写中英文 i18n 资源拆分与页面文案补全
- 已完成 `corepack pnpm install` 并生成 workspace 锁文件
- 已完成 API 正式服务栈：Express、Zod、Dotenv、ESLint、Prettier、TypeScript build
- 已完成 `packages/shared` 构建产物导出，供 API 正式构建与运行消费
- 已完成日程、任务、备忘、提醒、重复规则与同步状态的共享核心模型定义
- 已完成 API 侧 PostgreSQL 连接配置、SQL migration runner 与首个 `planning_items` schema
- 已完成日程、任务、备忘的核心 CRUD API、请求校验与内存仓储测试装配
- 已完成客户端 planning 模型、可切换仓储、应用级 store，以及周视图/备忘/添加页的数据接入

## 进行中

- 建立本地存储
- 规划同步骨架

## 下一步唯一推荐动作

建立本地存储。

## 当前阻塞

- 当前会话仍不能直接调用裸 `pnpm`，但 `corepack pnpm` 已可用
- Flutter 命令需在沙箱外串行执行，因为 SDK 会写入 `C:\tools\flutter\bin\cache`
- `tsx`/`esbuild` 相关命令在当前工具环境下需沙箱外执行测试或启动验证
- 当前环境未提供可用的本地 PostgreSQL 实例；`127.0.0.1:5432` 未监听，migration runner 尚未做真实连库烟测

## 当前技术默认值

- 客户端：Flutter
- 后端：Node.js + TypeScript
- 数据库：PostgreSQL
- 认证：邮箱 + 密码
- AI：OpenAI API（后端代理）

## 最近稳定提交

- `981b5aa feat(api): add core item crud`

## 备注

- Android 安装包和后端可运行是当前首个交付阻塞线
- Windows 与 Web 继续推进，但不阻塞首个交付节点
- `packages/shared/` 当前定义为契约与共享约定层，而非跨语言运行时代码复用层
- 现已可通过 `npm run api:start` 启动 Express API，通过 `npm run api:test` 完成 Supertest 验证
- Flutter 当前已生成 Android 平台目录，并已验证 `flutter analyze`、`flutter test`
- `packages/shared` 已可通过 `npm run shared:typecheck` 与 `npm run shared:check` 验证核心模型
- API 已提供 `corepack pnpm --filter @overview/api db:migrate` 入口，待本地 PostgreSQL 就绪后可执行首版 schema 迁移
- API 已提供 `/planning/schedules`、`/planning/tasks`、`/planning/memos` 的 CRUD 路由；当前测试使用可替换内存仓储完成接口验证
- 客户端默认使用内置示例数据仓储；可通过 `--dart-define=OVERVIEW_API_BASE_URL=...` 切换到真实 API
