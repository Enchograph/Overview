# Overview 项目状态

## 当前状态

- 状态：进行中
- 当前阶段：P3 账号、同步与离线
- 当前功能块：客户端 HTTP 同步联调测试已落地，继续扩展更新/删除同步场景
- 最后更新：2026-03-12

## 已完成

- 产品需求文档初版已建立
- 项目执行原则、阶段路线图与任务体系已确定
- 治理层文档已写入仓库
- 基础目录骨架已建立
- 固定接力提示词已建立
- 命令默认自动执行、无人工审批、任务完成后自动续跑的治理规则已纳入治理层
- 已确定根级 monorepo 管理方式为 `pnpm workspace`
- 已建立根级 `package.json` 与 `pnpm-workspace.yaml`
- 已建立 `packages/shared` 基础健康检查契约
- 已建立 `services/api` 零依赖 TypeScript 最小服务与 `/health` 测试
- 已完成 `apps/client` Flutter Android 工程初始化
- 已通过客户端最小验证：`flutter analyze`、`flutter test`
- 已完成客户端命名路由、四个主页面骨架与 AI/同步子路由
- 已完成手写中英文 i18n 资源拆分与页面文案补全
- 已完成 `npx pnpm install` 并生成 workspace 锁文件
- 已完成 API 正式服务栈：Express、Zod、Dotenv、ESLint、Prettier、TypeScript build
- 已完成 `packages/shared` 构建产物导出，供 API 正式构建与运行消费
- 已完成日程、任务、备忘、提醒、重复规则与同步状态的共享核心模型定义
- 已完成 API 侧 PostgreSQL 连接配置、SQL migration runner 与首个 `planning_items` schema
- 已完成日程、任务、备忘的核心 CRUD API、请求校验与内存仓储测试装配
- 已完成客户端 planning 模型、可切换仓储、应用级 store，以及周视图/备忘/添加页的数据接入
- 已完成客户端本地存储仓储，默认使用 SharedPreferences 持久化 planning 数据
- 已完成客户端本地存储验证与 Android debug APK 构建验证
- 已完成客户端同步骨架初版：本地待同步队列、同步状态快照、同步页状态展示与手动同步入口
- 已确认当前环境 Flutter SDK 可用，并完成 `flutter analyze`、`flutter test`、`flutter build apk --debug`
- 已完成 API 真实 PostgreSQL 烟测：自动准备嵌入式 PostgreSQL 二进制链接、执行 migration，并验证 PostgreSQL-backed CRUD
- 已将根级与 API 工作区命令从 `corepack pnpm` 切换为当前环境可执行的 `npx pnpm`
- 已完成客户端真实 HTTP 联调测试：`HttpPlanningRepository` 与 `LocalPlanningRepository.runSync()` 可通过本地 HTTP 服务验证创建与归档成功路径

## 进行中

- 扩展同步队列到 schedule/task/memo 的更新与删除场景，并补齐对应联调测试

## 下一步唯一推荐动作

扩展同步队列到 schedule/task/memo 的更新与删除场景，并补齐对应 HTTP 联调测试。

## 当前阻塞

- Flutter 到 Node API 的单进程端到端编排仍未落地；当前为“客户端真实 HTTP 联调 + API/PostgreSQL 真实烟测”分层通过
- 当前同步队列仍仅覆盖创建与 memo 归档写路径，更新与删除场景尚未实现

## 当前技术默认值

- 客户端：Flutter
- 后端：Node.js + TypeScript
- 数据库：PostgreSQL
- 认证：邮箱 + 密码
- AI：OpenAI API（后端代理）

## 最近稳定提交

- `3d8b59f Linux环境配置更新追追追追追追追追追追至`

## 备注

- Android 安装包和后端可运行是当前首个交付阻塞线
- Windows 与 Web 继续推进，但不阻塞首个交付节点
- `packages/shared/` 当前定义为契约与共享约定层，而非跨语言运行时代码复用层
- 现已可通过 `npm run api:start` 启动 Express API，通过 `npm run api:test` 完成 Supertest 验证
- Flutter 当前已生成 Android 平台目录，并已验证 `flutter analyze`、`flutter test`、`flutter build apk --debug`
- `packages/shared` 已可通过 `npm run shared:typecheck` 与 `npm run shared:check` 验证核心模型
- API 已提供 `npx pnpm --filter @overview/api db:migrate` 入口，并通过嵌入式 PostgreSQL 自动化烟测验证首版 schema 迁移
- API 已提供 `/planning/schedules`、`/planning/tasks`、`/planning/memos` 的 CRUD 路由；当前同时具备内存仓储测试与 PostgreSQL-backed 烟测
- 客户端默认使用 SharedPreferences 本地仓储，并在首次启动时注入示例数据；设置 `--dart-define=OVERVIEW_API_BASE_URL=...` 后将启用“本地优先 + 远端同步骨架”模式，且现已具备真实 HTTP 同步联调测试
- Android 构建已在 `apps/client/android/gradle.properties` 关闭 Kotlin 增量编译，以规避 Windows 下 `shared_preferences_android` 的缓存关闭异常
