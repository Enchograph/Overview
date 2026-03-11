# client

Flutter 客户端主应用目录。

当前状态：已完成 Flutter 工程初始化，并建立命名路由、底部导航、四个主页面骨架和中英文本地化资源。

## 当前内容

- `lib/main.dart`：应用入口
- `lib/app/`：应用壳、命名路由、底部导航和页面模块
- `lib/l10n/`：手写中英文本地化资源与文案表
- `test/widget_test.dart`：导航、语言切换和设置页跳转基础验证

## 当前验证

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

## 下一步

- 为客户端页面接入真实数据与状态管理
- 接入账号、同步与 AI 数据流
