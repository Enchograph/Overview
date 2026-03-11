# client

Flutter 客户端主应用目录。

当前状态：已完成 Flutter 工程初始化，并为周视图、备忘页、添加页接入应用级状态和可切换的数据仓储。

## 当前内容

- `lib/main.dart`：应用入口
- `lib/app/`：应用壳、命名路由、底部导航和页面模块
- `lib/app/planning/`：客户端 planning 模型、仓储、状态和作用域
- `lib/l10n/`：手写中英文本地化资源与文案表
- `test/widget_test.dart`：导航、语言切换、设置页跳转和添加数据基础验证

## 当前验证

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

## 数据接入

- 默认使用 `FakePlanningRepository` 提供内置示例数据，便于本地 UI 和测试闭环
- 若要连接 API，启动客户端时传入 `--dart-define=OVERVIEW_API_BASE_URL=http://10.0.2.2:3000`
- Android 模拟器访问本机 API 时优先使用 `10.0.2.2`

## 下一步

- 建立本地存储与同步骨架
- 接入账号、同步与 AI 数据流
