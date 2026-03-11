# Overview 项目状态

## 当前状态

- 状态：进行中
- 当前阶段：P2 核心数据闭环
- 当前功能块：已完成共享核心数据模型，开始建立 PostgreSQL schema 与首版迁移机制
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

## 进行中

- 建立 PostgreSQL schema 与迁移工具的首版落点
- 规划核心对象 CRUD 的 API 组织方式

## 下一步唯一推荐动作

建立 PostgreSQL schema 与首版迁移机制。

## 当前阻塞

- 当前会话仍不能直接调用裸 `pnpm`，但 `corepack pnpm` 已可用
- Flutter 命令需在沙箱外串行执行，因为 SDK 会写入 `C:\tools\flutter\bin\cache`
- `tsx`/`esbuild` 相关命令在当前工具环境下需沙箱外执行测试或启动验证

## 当前技术默认值

- 客户端：Flutter
- 后端：Node.js + TypeScript
- 数据库：PostgreSQL
- 认证：邮箱 + 密码
- AI：OpenAI API（后端代理）

## 最近稳定提交

- `66c743d feat(client): refine routes and localized shell`

## 备注

- Android 安装包和后端可运行是当前首个交付阻塞线
- Windows 与 Web 继续推进，但不阻塞首个交付节点
- `packages/shared/` 当前定义为契约与共享约定层，而非跨语言运行时代码复用层
- 现已可通过 `npm run api:start` 启动 Express API，通过 `npm run api:test` 完成 Supertest 验证
- Flutter 当前已生成 Android 平台目录，并已验证 `flutter analyze`、`flutter test`
- `packages/shared` 已可通过 `npm run shared:typecheck` 与 `npm run shared:check` 验证核心模型
