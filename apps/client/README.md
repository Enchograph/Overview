# client

Flutter 客户端主应用目录。

当前状态：已完成 Flutter 工程初始化，并为周视图、备忘页、添加页接入应用级状态，默认使用 SharedPreferences 本地仓储持久化数据。

## 当前内容

- `lib/main.dart`：应用入口
- `lib/app/`：应用壳、命名路由、底部导航和页面模块
- `lib/app/planning/`：客户端 planning 模型、仓储、状态和作用域
- `lib/l10n/`：手写中英文本地化资源与文案表
- `test/widget_test.dart`：导航、语言切换、设置页跳转和添加数据基础验证
- `test/planning/local_planning_repository_test.dart`：本地仓储持久化验证

## 当前验证

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

## 数据接入

- 默认使用 `LocalPlanningRepository` 读写 SharedPreferences，并在首次启动时注入示例数据
- 若要连接 API，启动客户端时传入 `--dart-define=OVERVIEW_API_BASE_URL=http://10.0.2.2:3000`
- Android 模拟器访问本机 API 时优先使用 `10.0.2.2`
- Windows 下 debug APK 构建已在 `android/gradle.properties` 关闭 Kotlin 增量编译，以规避 `shared_preferences_android` 的缓存异常

## 下一步

- 规划同步骨架
- 接入账号、同步与 AI 数据流
