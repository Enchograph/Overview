# Overview 交接记录

## 最近一次交接

- 日期：2026-03-12
- 阶段：P6
- 完成内容：
  - 为 Flutter 客户端新增 `lib/app/notifications/` 模块，封装通知权限状态、测试通知与本地提醒调度能力
  - 接入 `flutter_local_notifications` 与 `timezone`，为 Android Manifest 增加 `POST_NOTIFICATIONS` 权限，并在 Android Gradle 配置中补齐 desugaring 依赖
  - 将 `PlanningStore.refresh()` 接入本地通知重建逻辑：未来日程默认在开始前 10 分钟提醒，未完成任务默认在到期前 30 分钟提醒，并限制仅调度最近 8 条
  - 将设置页接入通知状态卡片，提供“启用通知”和“发送测试通知”入口
  - 扩展客户端 i18n 文案，补齐中英文通知状态与操作文案
  - 扩展本地仓储测试与 widget 测试，验证 planning refresh 后的通知调度，以及设置页通知入口可触发测试通知
  - 为应用壳层增加宽屏断点逻辑，在平板宽度下使用 `NavigationRail` 取代底部导航
  - 将周视图、添加页和设置页升级为平板竖屏双栏/约束布局，避免大宽度下仍沿用单列手机排版
  - 在更宽的横屏窗口下扩展 `NavigationRail` 标签展示，并将备忘页升级为摘要区 + 备忘列表分栏布局
  - 为客户端生成 `windows/` 平台工程，补齐 Flutter Windows runner 与 CMake 配置
  - 为周视图、备忘页和设置页补齐桌面宽度下的显式刷新按钮与滚动条，避免桌面端仍依赖移动端下拉刷新手势
  - 扩展 widget 测试覆盖桌面显式刷新入口，并更新客户端 README 与项目状态
  - 为客户端生成 `web/` 平台工程，补齐 PWA manifest、Web 图标与浏览器入口文件
  - 复用现有自适应壳层到浏览器窗口，并完成 `flutter build web` 构建验证
  - 为客户端新增 `lib/app/launcher/` 模块，接入 `quick_actions` 并注册“打开周视图”“打开添加页”两个 Android 快捷入口
  - 为应用壳层增加快捷入口回调接线，支持从系统快捷入口直接路由到周视图或添加页
  - 将设置页补充为可见的快捷入口说明区，并扩展 widget 测试覆盖快捷入口注册与跳转
  - 为桌面与浏览器宽度下的 app bar 增加固定“打开周视图”“打开添加页”快捷入口，对齐 Android 快捷入口语义
  - 扩展 widget 测试覆盖桌面固定快捷入口跳转，并完成 Web/Android 构建回归
  - 新增 `integration_test/main_flow_test.dart`，覆盖启动应用、核心导航、添加条目、账号入口与 Android 快捷入口跳转主链路
  - 新增根级 `README.md`，补齐仓库安装、API 启动、客户端运行、Android/Web/Windows 构建与 AI 环境变量说明
  - 新增 `docs/KNOWN_LIMITATIONS.md`，沉淀 Windows 主机构建、Linux 集成测试工具链、通知策略与 AI 凭据验证等已知限制
  - 更新客户端与 API README，并在 P6 TODO 中关闭“安装与运行说明”“整理已知限制”
  - 执行 `flutter build apk --release --no-pub`，产出 `apps/client/build/app/outputs/flutter-apk/app-release.apk`
  - 通过 `build.gradle.kts` 与本机 debug keystore 核对，确认当前 release 仍使用 debug keystore 签名
  - 将 release APK 产物路径与 debug 签名限制回写到仓库文档和项目状态
  - 修复 API 环境解析缺陷：`.env.example` 中的空 AI 凭据现会被视为未配置，不再阻塞 migration 与启动
  - 新增 `npm run api:start:embedded`，可自动拉起嵌入式 PostgreSQL、执行 migration 并启动本地 API
  - 已在本机通过 `curl http://127.0.0.1:3000/health` 验证嵌入式开发模式下的健康检查返回
  - 新增 `services/api/test/start.embedded.test.ts`，把嵌入式 PostgreSQL 启动、API 拉起、`/health` 探活与进程回收沉淀为自动化烟测
  - 为 Android release 增加可选正式签名配置：支持 `android/key.properties` 与 `OVERVIEW_ANDROID_*` 环境变量
  - 新增 `apps/client/android/key.properties.example`，沉淀正式签名配置模板
  - 在未提供正式签名材料时重新通过 `flutter build apk --release --no-pub`，确认 debug 回退路径仍可用
  - 新增 `apps/client/test/main_flow_smoke_test.dart`，把主导航、Capture、Notes、Settings、Account 与快捷入口跳转沉淀为可执行 widget smoke
  - 已通过 `flutter test test/main_flow_smoke_test.dart`，并在新增主流程烟测后继续通过 `flutter test` 与 `flutter analyze`
  - 新增 `scripts/e2e-client-api.mjs` 与根级 `npm run e2e:client-api`，自动拉起嵌入式 API、预注册账号、运行客户端真实 HTTP 测试并校验远端写入
  - 新增 `apps/client/test/client_api_e2e_test.dart`，覆盖客户端登录、memo 创建与 `runSync()` 通过真实 API 成功落库
  - 修复 `HttpPlanningRepository` 对可选字段发送 `null` 导致服务端 400 的真实同步缺陷
- 验证结果：
  - 已通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter analyze`
  - 已通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter test`
  - 已通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter build apk --debug`
  - 已通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter build apk --release --no-pub`
  - 已尝试 `cd apps/client && /home/anon/sdk/flutter/bin/flutter build windows`，Flutter 返回“only supported on Windows hosts”
  - 已通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter build web`
  - 已尝试 `cd apps/client && /home/anon/sdk/flutter/bin/flutter test integration_test/main_flow_test.dart -d linux`，当前 Linux 主机因 Flutter Linux runner 缺少 `clang` 工具链而失败
  - 已通过 `npm run api:lint`
  - 已通过 `npm run api:typecheck`
  - 已通过 `npm run api:test`
  - 已通过 `npm run api:start:embedded`
  - 已通过 `curl -sS http://127.0.0.1:3000/health`
  - 已通过 `npm run e2e:client-api`
- 当前进行中：
  - 推进正式发布收尾，优先补齐 Android 正式签名材料接入说明与发布前检查清单
- 下一接手顺序：
  1. 整理 Android 正式签名接入说明与发布前检查清单
  2. 随后回看 Windows 真实主机构建验证与其他 P6 交付事项
  3. 随后继续收敛剩余已知限制与发布说明
- 风险：
  - Azure Speech 真实凭据尚未在仓库内验证；当前只验证了接口与未配置场景
  - 当前通知策略仍基于 `ScheduleItem.startAt` / `TaskItem.dueAt` 的固定偏移量，尚未接入共享模型中的 reminders 字段
  - 当前环境不是 Windows 主机，仓库内无法完成真实 Windows 二进制构建验证
  - 当前 Linux 主机缺少 Flutter Linux runner 所需的完整 `clang` 工具链，`integration_test` 尚未真实执行
  - 当前 Android release 仍是 debug keystore 签名，不适合正式商店分发
  - 嵌入式 PostgreSQL 开发启动当前仅在 Linux x64 环境完成验证

## 交接模板

- 日期：
- 阶段：
- 完成内容：
- 验证结果：
- 未完成点：
- 下一接手顺序：
- 风险或阻塞：
