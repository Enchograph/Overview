# client

Flutter 客户端主应用目录。

当前状态：已完成 Flutter 工程初始化，并为周视图、备忘页、添加页接入应用级状态；默认使用 SharedPreferences 本地仓储持久化数据，并已接入同步骨架初版。
当前也已接入本地持久化的邮箱注册/登录流程、设置页账号入口、带 Bearer token 的受保护 planning 同步请求，以及 AI 文本解析、待确认结构化结果、单轮问答、语音录入、错误处理、Android 本地通知与 Android 平板布局主路径。

## 当前内容

- `lib/main.dart`：应用入口
- `lib/app/`：应用壳、命名路由、底部导航和页面模块
- `lib/app/auth/`：客户端认证仓储、状态管理与作用域
- `lib/app/ai/`：客户端 AI 仓储、录音服务、状态管理与作用域
- `lib/app/launcher/`：Android 快捷入口服务与应用内路由跳转接线
- `lib/app/notifications/`：本地通知服务、权限状态管理与作用域
- `lib/app/planning/`：客户端 planning 模型、仓储、状态和作用域
- `lib/l10n/`：手写中英文本地化资源与文案表
- `integration_test/`：客户端主流程集成测试脚手架
- `windows/`：Flutter Windows 桌面 runner 与 CMake 工程
- `web/`：Flutter Web / PWA 入口、manifest 和图标资源
- `test/widget_test.dart`：导航、语言切换、设置页跳转和添加数据基础验证
- `test/auth/local_auth_repository_test.dart`：会话持久化与退出登录验证
- `test/ai/http_ai_repository_test.dart`：AI 解析/问答/转写 HTTP 请求与 Bearer token 验证
- `test/planning/local_planning_repository_test.dart`：本地仓储持久化与同步骨架验证
- `test/planning/http_planning_repository_test.dart`：真实 HTTP 请求下的远端仓储与 `runSync()` 联调验证，覆盖创建、归档、更新、删除

## 运行命令

安装依赖：

```bash
flutter pub get
```

本地示例数据模式启动：

```bash
flutter run
```

连接本地 API：

```bash
flutter run --dart-define=OVERVIEW_API_BASE_URL=http://10.0.2.2:3000
```

## 当前验证

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `flutter build apk --release --no-pub`
- `flutter build web`

当前环境备注：已在 2026-03-12 通过 `/home/anon/sdk/flutter/bin/flutter` 重新执行并验证上述五条命令。
当前另已写入 `integration_test/main_flow_test.dart`；但本机尝试执行 `flutter test integration_test/main_flow_test.dart -d linux` 时，受限于 Linux 桌面 `clang` 工具链缺失，尚未完成真实运行。
当前 release APK 输出路径为 `build/app/outputs/flutter-apk/app-release.apk`。

## Release 签名

- 可在 `android/key.properties` 中填入签名材料，格式见 `android/key.properties.example`
- 也可通过环境变量提供：
  - `OVERVIEW_ANDROID_STORE_FILE`
  - `OVERVIEW_ANDROID_STORE_PASSWORD`
  - `OVERVIEW_ANDROID_KEY_ALIAS`
  - `OVERVIEW_ANDROID_KEY_PASSWORD`
- 若未提供上述签名材料，release 构建会自动回退到 debug keystore，仅用于交付验证

## 数据接入

- 默认使用 `LocalPlanningRepository` 读写 SharedPreferences，并在首次启动时注入示例数据
- 设置 `--dart-define=OVERVIEW_API_BASE_URL=http://10.0.2.2:3000` 后，客户端会启用“本地优先 + 远端同步骨架”模式，并自动把本地持久化 session token 附加到 `/planning/*` 请求
- 添加页现在可调用 `/ai/ingest/text` 获取 AI 建议，并在确认时间、地点、时长、列表等字段后创建条目
- 添加页现在支持录音并上传到 `/ai/transcribe`；转写完成后会自动复用现有 AI 文本解析流
- AI 页面现在可调用 `/ai/ask` 发起单轮规划问答，并展示回答与引用条目数量
- AI 和语音错误现在按稳定错误码映射为本地化提示，并在问答/录音场景提供重试入口
- Android 端现在会在 planning 刷新后自动重建未来提醒：日程默认在开始前 10 分钟提醒，任务默认在到期前 30 分钟提醒，设置页可查看权限状态、请求通知权限并发送测试通知
- 宽度达到平板断点后，应用壳层会切换为 `NavigationRail`；在更宽的横屏窗口下，导航会扩展显示标签，备忘页也会切换为摘要区 + 列表区分栏布局
- 周视图、添加页和设置页会在平板宽度下切换为双栏/约束布局，避免大屏设备仍保持单列手机排版
- Windows 桌面基础工程现已生成；在桌面宽度下，周视图、备忘页和设置页会显示显式刷新按钮并启用滚动条，不再只依赖移动端下拉刷新
- Web PWA 基础工程现已生成，可通过 `flutter build web` 产出浏览器静态资源；当前自适应壳层会在浏览器宽度下复用桌面/平板布局
- Android 端现已接入应用快捷入口：长按应用图标后可直接进入周视图或添加页，设置页会显示对应说明
- Windows 与 Web 桌面宽度下，app bar 现提供固定“打开周视图”“打开添加页”快捷入口，用于对齐 Android 长按图标快捷入口语义
- Android 模拟器访问本机 API 时优先使用 `10.0.2.2`
- Windows 下 debug APK 构建已在 `android/gradle.properties` 关闭 Kotlin 增量编译，以规避 `shared_preferences_android` 的缓存异常

## 下一步

- 编写安装与运行说明
- 继续推进客户端与 Node API 的单进程端到端验证
