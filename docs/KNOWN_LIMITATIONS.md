# 已知限制

## 当前环境限制

- 当前主机不是 Windows，仓库内无法真实执行 `flutter build windows`
- 当前 Linux 主机缺少 Flutter Linux runner 所需的完整 `clang` 工具链，`flutter test integration_test/main_flow_test.dart -d linux` 暂未跑通

## 客户端限制

- Android 快捷入口已实现；Android 主屏小组件仍未实现
- 当前 Android release APK 仍使用 debug keystore 签名，尚未接入正式发布签名材料
- 通知调度当前使用固定策略：
  - 日程开始前 10 分钟
  - 任务到期前 30 分钟
- 通知策略尚未接入共享模型中的 reminders 字段
- Windows 平台工程已生成，但仍缺少 Windows 主机上的真实构建验证

## Web / 桌面限制

- Web PWA 已完成基础构建，但尚未补离线缓存、安装提示与浏览器专属体验优化
- Windows 与 Web 已有等效快捷入口，但仍未补更深的桌面端键鼠优化

## API / AI 限制

- OpenAI 真实凭据尚未在仓库内完成自动化验证
- Azure Speech 真实凭据尚未在仓库内完成自动化验证
- 当前客户端与 Node API 尚未建立单进程端到端自动化编排

## 测试限制

- 已有主流程集成测试脚手架，但当前仓库内仅完成静态落地，未在可用桌面 runner 上真实执行
- 当前自动化仍以：
  - Flutter widget / repository 测试
  - API 路由测试
  - PostgreSQL 烟测
  为主
