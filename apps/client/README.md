# client

Flutter 客户端主应用目录。

当前状态：已完成 Flutter 工程初始化，并为周视图、备忘页、添加页接入应用级状态；默认使用 SharedPreferences 本地仓储持久化数据，并已接入同步骨架初版。

## 当前内容

- `lib/main.dart`：应用入口
- `lib/app/`：应用壳、命名路由、底部导航和页面模块
- `lib/app/planning/`：客户端 planning 模型、仓储、状态和作用域
- `lib/l10n/`：手写中英文本地化资源与文案表
- `test/widget_test.dart`：导航、语言切换、设置页跳转和添加数据基础验证
- `test/planning/local_planning_repository_test.dart`：本地仓储持久化与同步骨架验证
- `test/planning/http_planning_repository_test.dart`：真实 HTTP 请求下的远端仓储与 `runSync()` 联调验证，覆盖创建、归档、更新、删除

## 当前验证

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

当前环境备注：已在 2026-03-12 通过 `/home/anon/sdk/flutter/bin/flutter` 重新执行并验证上述三条命令。

## 数据接入

- 默认使用 `LocalPlanningRepository` 读写 SharedPreferences，并在首次启动时注入示例数据
- 设置 `--dart-define=OVERVIEW_API_BASE_URL=http://10.0.2.2:3000` 后，客户端会启用“本地优先 + 远端同步骨架”模式
- Android 模拟器访问本机 API 时优先使用 `10.0.2.2`
- Windows 下 debug APK 构建已在 `android/gradle.properties` 关闭 Kotlin 增量编译，以规避 `shared_preferences_android` 的缓存异常

## 下一步

- 接入账号注册、登录与认证状态管理
- 接入账号、同步与 AI 数据流
