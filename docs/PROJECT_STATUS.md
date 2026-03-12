# Overview 项目状态

## 当前状态

- 状态：进行中
- 当前阶段：P6 测试、打包与交付
- 当前功能块：后端本地运行已闭环，继续推进自动化集成验证
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
- 已完成客户端更新/删除同步队列扩展，覆盖 schedule/task/memo 的更新与删除待同步操作
- 已完成客户端更新/删除 HTTP 联调测试，验证本地队列到远端仓储的更新与删除成功路径
- 已完成邮箱注册/登录 API：新增 `users`、`auth_sessions` schema、密码哈希、内存/PG 仓储与 `/auth/register`、`/auth/login` 路由
- 已完成认证相关 API 测试与 PostgreSQL 烟测扩展，验证 auth migration 与真实登录流程
- 已完成客户端 auth flow：新增本地会话持久化、认证状态 store、设置页账号状态卡片和邮箱注册/登录页面
- 已完成客户端认证测试，验证本地会话持久化与设置页登录主路径
- 已完成服务端 token 校验与受保护 planning 接口：`Authorization: Bearer <token>` 已接入 `/planning/*`，并按当前登录用户隔离读写
- 已完成受保护 planning API 测试扩展，验证未授权 401、内存仓储与 PostgreSQL 烟测下的受保护 CRUD 主路径
- 已完成客户端 planning/sync token 透传：`HttpPlanningRepository` 会自动附带当前 session token，应用默认装配已复用同一份本地 auth 会话
- 已完成受保护客户端 HTTP 联调测试与 Android 构建验证，确认带 token 的 planning CRUD/同步主路径可用
- 已完成同步恢复第一版：本地同步队列可识别 401/未鉴权阻塞态，重新鉴权后可继续执行待同步操作
- 已完成冲突策略第一版：远端 404/409 会把对应条目标记为 `conflict`、移出自动重试队列，并在同步页显示冲突数量
- 已完成 AI 服务接口基础：新增受保护的 `/ai/ingest/text` 与 `/ai/ask` 路由，并以启发式服务闭环文本录入与单轮问答占位能力
- 已完成 AI API 测试与 PostgreSQL 烟测扩展，验证未授权 401、登录后 AI 文本解析与问答主路径
- 已完成 OpenAI provider 接入：API 新增 `AI_PROVIDER`、`OPENAI_API_KEY`、`OPENAI_MODEL` 配置，可在 `auto` 模式下自动选择 OpenAI 或 heuristic provider
- 已完成 OpenAI provider 工厂测试，验证无 key 回退 heuristic、有显式 `openai` 配置时缺 key 会快速失败
- 已完成客户端文本录入解析流：添加页可调用 `/ai/ingest/text`，展示 AI 结构化建议并按建议类型创建基础条目
- 已完成客户端 AI HTTP 仓储测试与 widget 测试，验证 Bearer token 鉴权下的解析请求和建议应用主路径
- 已完成客户端 AI 单轮问答页：AI 路由已接通 `/ai/ask`，支持输入问题、提交、清空、错误展示和回答卡片
- 已完成客户端 AI 问答 HTTP 仓储测试与 widget 测试，验证 Bearer token 鉴权下的问答请求和回答展示主路径
- 已完成 AI 待确认结构化结果流：添加页会在 AI 解析后预填时间、地点、时长、列表等字段，并在确认后按结构化字段创建条目
- 已完成结构化结果本地持久化验证：客户端本地仓储测试覆盖 AI 确认后的任务时间、地点和时长字段落盘
- 已完成客户端语音入口：添加页支持录音、停止录音、语音转写中状态，并在转写完成后自动复用现有 AI 文本解析流
- 已完成 API 语音转写入口：新增受保护的 `/ai/transcribe`，支持 Azure Speech 短音频转写并返回文本结果
- 已完成客户端与 API 语音转写测试：客户端 HTTP 仓储测试覆盖 `/ai/transcribe`，widget 测试覆盖录音后自动触发 AI 解析，API 测试覆盖未配置 Azure Speech 时的 503 路径
- 已完成 AI 错误处理：AI API 返回稳定错误 `code`，客户端按错误码映射为本地化、可恢复的提示，并在问答/录音场景提供重试入口
- 已完成 AI 错误处理测试：客户端 widget 测试覆盖 AI 鉴权失败和 Azure Speech 未配置提示，API 测试覆盖 `/ai/transcribe` 错误码返回
- 已完成 Android 通知第一版：客户端接入 `flutter_local_notifications`，按日程开始前 10 分钟与任务到期前 30 分钟自动重建本地提醒，并在设置页提供权限状态、启用通知与测试通知入口
- 已完成 Android 通知验证：客户端测试覆盖 planning refresh 后的提醒调度与设置页通知入口，Android debug APK 已在通知插件与 desugaring 配置下重新构建通过
- 已完成 Android 平板竖屏适配第一版：应用壳层在宽屏下切换为 `NavigationRail`，周视图/添加页/设置页在约 900px 断点下切换为双栏约束布局
- 已完成 Android 平板竖屏验证：客户端 widget 测试覆盖宽屏导航和设置页卡片展示，Android debug APK 已在宽屏布局调整后重新构建通过
- 已完成 Android 平板横屏适配第一版：更宽窗口下 `NavigationRail` 会扩展显示标签，备忘页在横屏宽度下切换为摘要区 + 备忘列表分栏布局
- 已完成 Android 平板横屏验证：客户端 widget 测试覆盖横屏备忘页布局，Android debug APK 已在横屏布局调整后重新构建通过
- 已完成 Windows 平台工程与桌面布局第一版：客户端已生成 `windows/` 平台目录，桌面宽度下为周视图、备忘页和设置页补齐显式刷新按钮与滚动条，避免依赖移动端下拉手势
- 已完成 Windows 桌面代码级验证：客户端 widget 测试覆盖桌面显式刷新入口，Android debug APK 回归构建通过；当前 Linux 主机已尝试 `flutter build windows`，但 Flutter 明确限制仅支持在 Windows 主机执行
- 已完成 Web PWA 基础适配：客户端已生成 `web/` 平台目录、manifest、图标与入口文件，现有自适应壳层可在浏览器窗口下复用桌面/平板布局
- 已完成 Web 构建验证：客户端已通过 `flutter build web`，生成 `apps/client/build/web`
- 已完成 Android 快捷入口第一版：客户端接入 `quick_actions`，长按应用图标后可直接进入周视图或添加页；设置页同步展示快捷入口说明
- 已完成 Android 快捷入口验证：客户端 widget 测试覆盖快捷入口注册与跳转到添加页，Android debug APK 已在接入快捷入口后重新构建通过
- 已完成 Windows 与 Web 等效入口策略：桌面与浏览器宽度下，应用壳层 app bar 现提供固定“打开周视图”“打开添加页”快捷入口，与 Android 长按图标快捷入口保持一致语义
- 已完成等效入口验证：客户端 widget 测试覆盖桌面固定快捷入口跳转到添加页，Web 与 Android 构建已在接入后重新通过
- 已完成主流程集成测试脚手架：客户端新增 `integration_test/main_flow_test.dart`，覆盖启动应用、核心导航、添加条目、账号入口与 Android 快捷入口跳转主链路
- 已完成主流程测试静态验证：客户端 `flutter analyze`、`flutter test` 继续通过；当前 Linux 主机在尝试执行 `flutter test integration_test/main_flow_test.dart -d linux` 时暴露本地 `clang` 工具链缺失，尚未完成真实运行
- 已完成安装与运行说明：新增根级 `README.md`，补齐仓库安装、API 启动、客户端运行、Android/Web/Windows 构建和 AI 环境变量说明
- 已完成已知限制清单第一版：新增 `docs/KNOWN_LIMITATIONS.md`，沉淀 Windows 主机构建、Linux 集成测试工具链、通知策略和 AI 凭据验证限制
- 已完成 Android 首个交付构建：通过 `flutter build apk --release --no-pub` 产出 `apps/client/build/app/outputs/flutter-apk/app-release.apk`
- 已确认当前 Android release 仍使用 debug keystore 签名，适用于当前仓库交付验证，不适用于正式商店分发
- 已完成后端本地运行闭环修复：`.env.example` 空 AI 凭据现可正常解析，新增 `npm run api:start:embedded` 可自动拉起嵌入式 PostgreSQL、执行 migration 并启动 API
- 已完成后端本地运行验证：本机已通过 `npm run api:start:embedded` 启动 API，并通过 `curl http://127.0.0.1:3000/health` 验证健康检查返回 `status=ok`

## 进行中

- 推进自动化集成验证，优先把本地启动与健康检查沉淀为可重复执行的测试

## 下一步唯一推荐动作

为后端本地启动新增自动化烟测，覆盖 `api:start:embedded` 到 `/health` 的可执行验证。

## 当前阻塞

- Flutter 到 Node API 的单进程端到端编排仍未落地；当前为“客户端真实 HTTP 联调 + API/PostgreSQL 真实烟测”分层通过
- Azure Speech 真实凭据尚未在仓库内验证；当前自动化仅覆盖接口、回退和未配置场景
- 当前环境不是 Windows 主机，`flutter build windows` 无法在仓库内完成真实构建验证
- P5 仍缺少 Windows 主机上的真实构建验证
- 当前 Linux 主机缺少 Flutter Linux runner 所需的完整 `clang` 工具链，`integration_test` 尚未在仓库内真实执行
- Android release 现阶段仍使用 debug keystore；正式发布签名材料与流程尚未进入仓库

## 当前技术默认值

- 客户端：Flutter
- 后端：Node.js + TypeScript
- 数据库：PostgreSQL
- 认证：邮箱 + 密码
- AI：OpenAI API（后端代理） + Azure Speech（语音转写）

## 最近稳定提交

- `3d8b59f Linux环境配置更新追追追追追追追追追追至`

## 备注

- Android 安装包和后端可运行是当前首个交付阻塞线
- Android release APK 与后端本地开发启动现已打通，当前剩余首个交付阻塞点集中在正式签名材料缺失与更强的自动化集成验证
- Windows 与 Web 继续推进，但不阻塞首个交付节点
- `packages/shared/` 当前定义为契约与共享约定层，而非跨语言运行时代码复用层
- 现已可通过 `npm run api:start` 启动 Express API，通过 `npm run api:test` 完成 Supertest 验证
- Flutter 当前已生成 Android 平台目录，并已验证 `flutter analyze`、`flutter test`、`flutter build apk --debug`
- `packages/shared` 已可通过 `npm run shared:typecheck` 与 `npm run shared:check` 验证核心模型
- API 已提供 `npx pnpm --filter @overview/api db:migrate` 入口，并通过嵌入式 PostgreSQL 自动化烟测验证首版 schema 迁移
- API 已提供 `/planning/schedules`、`/planning/tasks`、`/planning/memos` 的 CRUD 路由；当前同时具备内存仓储测试与 PostgreSQL-backed 烟测
- API 已提供 `/auth/register`、`/auth/login` 邮箱认证入口，当前返回 session token、过期时间与用户基本信息；`/planning/*` 现要求 `Authorization: Bearer <token>`
- 客户端默认使用 SharedPreferences 本地仓储，并在首次启动时注入示例数据；设置 `--dart-define=OVERVIEW_API_BASE_URL=...` 后将启用“本地优先 + 远端同步骨架”模式，且现已具备创建、归档、更新、删除以及 Bearer token 鉴权的真实 HTTP 同步联调测试
- 客户端已支持本地持久化邮箱会话，并可从设置页进入账号页面执行注册、登录、退出登录
- Android 构建已在 `apps/client/android/gradle.properties` 关闭 Kotlin 增量编译，以规避 Windows 下 `shared_preferences_android` 的缓存关闭异常
- P3 阶段的邮箱认证、受保护同步、离线恢复与最小冲突标记已全部闭环，P4 当前已完成文本解析、待确认结构化结果、单轮问答、语音入口与 AI 错误处理
