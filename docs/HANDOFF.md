# Overview 交接记录

## 最近一次交接

- 日期：2026-03-12
- 阶段：P4
- 完成内容：
  - 确认当前环境 Flutter SDK、Android SDK 与 JDK 可用，完成 `flutter analyze`、`flutter test`、`flutter build apk --debug`
  - 将根级与 API 工作区命令从当前环境不可用的 `corepack pnpm` 切换为 `npx pnpm`
  - 新增 `services/api/scripts/prepare-embedded-postgres.mjs`，在 `pnpm` 忽略 postinstall 时自动补全嵌入式 PostgreSQL 所需的 `.so` 链接
  - 新增 `services/api/test/postgres.smoke.test.ts`，以真实 PostgreSQL 执行 migration 并验证 `/planning/*` CRUD
  - 新增 `apps/client/test/planning/http_planning_repository_test.dart`，以本地 HTTP 服务验证 `HttpPlanningRepository` 与 `LocalPlanningRepository.runSync()` 的创建/归档成功路径
  - 扩展客户端同步队列，支持 schedule/task/memo 的标题更新与删除待同步操作，并补齐本地仓储测试
  - 扩展 HTTP 联调测试桩，覆盖 PATCH/DELETE 场景，验证更新/删除同步成功路径
  - 新增 auth 模块：`users` / `auth_sessions` migration、密码哈希工具、内存/PG 仓储和 `/auth/register`、`/auth/login` 路由
  - 扩展 API 测试与 PostgreSQL 烟测，验证邮箱注册、登录与第二个 migration
  - 新增客户端 auth 模块：本地会话持久化仓储、`AuthStore`、`AuthScope` 与账号页面
  - 将设置页接入真实账号状态展示与入口，并补齐 widget/repository 测试
  - 为 API 新增 Bearer token 校验中间件，并将 `/planning/*` 切换为受保护路由
  - 调整 planning 内存/PostgreSQL 仓储，按 `createdBy` 隔离当前登录用户的数据读写
  - 扩展 planning 测试与 PostgreSQL 烟测，验证未授权 401 与登录后受保护 CRUD 主路径
  - 为客户端 `HttpPlanningRepository` 接入当前 session token，并让应用默认装配复用同一份本地 auth 会话
  - 扩展客户端真实 HTTP 联调测试，强制校验 `Authorization: Bearer <token>` 后再执行 planning CRUD/同步
  - 为本地同步仓储增加 401/未鉴权阻塞语义，保留待同步队列并支持重新鉴权后继续重放
  - 扩展本地同步测试，验证 auth failure -> blocked -> 恢复鉴权后 success 的恢复主路径
  - 为本地同步仓储增加冲突标记语义：远端 404/409 会将对应条目标记为 `conflict`，并移出自动重试队列
  - 扩展同步页状态展示与本地同步测试，显示冲突数量并验证 conflict 状态落盘
  - 新增 AI 模块基础接口：`/ai/ingest/text` 与 `/ai/ask`，并接入受保护路由装配
  - 新增启发式 AI 服务实现，基于当前用户 planning 数据提供文本录入建议与单轮问答占位结果
  - 扩展 AI API 测试与 PostgreSQL 烟测，验证受保护 AI 主路径
  - 为 API 增加 OpenAI provider 工厂、环境变量与 `auto|heuristic|openai` 选择策略
  - 新增 `OpenAiService`，通过官方 `openai` SDK 调用 Responses API，并在无 key 环境下保持 heuristic 回退
  - 新增 AI provider 工厂测试，并修正 embedded Postgres 关闭阶段的 pool error 假红
  - 新增客户端 AI 仓储、作用域与 store，并让应用默认装配 AI HTTP 客户端
  - 将添加页接入 `/ai/ingest/text`，展示 AI 建议卡片、待确认字段和“按建议创建”主路径
  - 扩展客户端 AI HTTP 仓储测试与 widget 测试，验证解析请求和建议落地创建
  - 扩展客户端 AI 仓储与 store，新增 `/ai/ask` 单轮问答请求、回答状态与错误状态
  - 将 `AiRoute` 从占位页改为真实问答页，支持问题输入、提交态、清空操作和回答卡片展示
  - 扩展客户端 AI HTTP 仓储测试与 widget 测试，验证 Bearer token 鉴权下的 AI 问答主路径
  - 扩展 planning 创建接口，允许在创建 schedule/task/memo 时携带 AI 提取出的时间、地点、时长与列表字段
  - 将添加页 AI 建议卡片升级为待确认结构化表单，解析后自动预填字段并在确认后按结构化数据创建条目
  - 扩展本地规划仓储测试，验证 AI 确认流产出的任务字段可持久化落盘
  - 基于“中文优先 + i18n 可扩展”原则选定 Azure Speech 作为语音转写方案，并为 API 增加 `AZURE_SPEECH_*` 环境变量
  - 为 API 新增受保护的 `/ai/transcribe` 路由与 Azure Speech 转写实现；未配置 Azure 时返回可识别的 503 错误
  - 为客户端新增录音服务与状态管理，添加页支持开始录音、停止录音、上传转写，并在成功后自动进入既有 AI 文本解析流
  - 扩展客户端 AI HTTP 仓储测试与 widget 测试，验证 `/ai/transcribe` 和语音录入到 AI 建议卡片的主路径
  - 扩展 API AI 测试，验证 `/ai/transcribe` 在未配置 Azure Speech 时的受保护错误路径
  - 为 AI API 错误响应补齐稳定 `code` 字段，覆盖无鉴权、Azure 未配置、Azure 转写失败/空结果和 OpenAI 解析失败等场景
  - 为客户端 AI 仓储、store 和录音 store 增加错误码语义，避免把后端原始异常文本直接暴露到 UI
  - 为 AI 问答页和添加页补齐本地化错误提示与重试入口，覆盖 AI 鉴权失败、Azure 未配置和录音失败等主路径
  - 扩展客户端 widget 测试与 API 测试，验证本地化错误提示和 `/ai/transcribe` 错误码返回
  - 更新 API/客户端 README 与状态文档，记录新的验证入口与剩余同步风险
- 验证结果：
  - 已通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter analyze`
  - 已通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter test`
  - 已通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter build apk --debug`
  - 已通过 `npm run api:lint`
  - 已通过 `npm run api:typecheck`
  - 已通过 `npm run api:test`
- 当前进行中：
  - 推进 Android 通知，为 P5 建立首条平台能力主链路
- 下一接手顺序：
  1. 评估 Flutter 侧通知插件、Android 13+ 通知权限和本地提醒调度最小闭环
  2. 先让任务或日程能生成本地通知，再补设置页入口与测试
  3. 随后继续推进平板/桌面/Web 适配
  4. 随后考虑把客户端与 Node API 串成单进程端到端验证
- 风险：
  - 客户端还没有自动化串起真实 Node API 进程，当前是“客户端真实 HTTP 联调 + API/PostgreSQL 真实烟测”分层通过
  - 当前 token 仅用于请求鉴权，尚未实现主动登出与 session revoke
  - 当前尚未验证真实 OpenAI 凭据调用；仓库内测试仍以 heuristic/工厂回退为主
  - Azure Speech 真实凭据尚未在仓库内验证；当前只验证了接口与未配置场景
  - Android 通知仍未落地，P5 平台能力还没有开始形成稳定实现

## 交接模板

- 日期：
- 阶段：
- 完成内容：
- 验证结果：
- 未完成点：
- 下一接手顺序：
- 风险或阻塞：
