# Windows 交付验证说明

## 当前目标

在 Windows 主机上补齐客户端桌面构建与最小运行验证，收敛当前 Linux 主机无法完成的交付空缺。

## 当前仓库已完成

- Flutter `windows/` 平台工程已生成
- 桌面宽度布局、显式刷新入口与等效快捷入口策略已落地
- 相关 widget 测试已在当前仓库通过
- Linux 主机已确认 `flutter build windows` 会被 Flutter 官方限制拒绝

## 仍需在 Windows 主机完成的最小验证

1. 安装 Flutter、Visual Studio Desktop C++ 工作负载、Windows SDK
2. 在仓库根执行依赖安装
3. 在 `apps/client` 执行：

```bash
flutter analyze
flutter test
flutter build windows
```

4. 运行生成的 Windows 可执行文件，至少验证：
   - 周视图可打开
   - 添加页可创建条目
   - 设置页可打开账号入口
   - 桌面 app bar 的“打开周视图”“打开添加页”入口可点击
   - 宽窗口下显式刷新按钮可见

## 当前环境为什么不能完成

- 当前仓库运行主机是 Linux
- Flutter 官方限制 `flutter build windows` 只能在 Windows 主机执行
- 因此当前仓库内只能完成代码级验证，不能完成真实 Windows 二进制构建

## 建议的回填方式

- 在可用 Windows 主机上按本文件步骤执行
- 将结果回写到：
  - `docs/PROJECT_STATUS.md`
  - `docs/HANDOFF.md`
  - `docs/KNOWN_LIMITATIONS.md`

## 当前结论

- Windows 不是首个 Android 交付阻塞项
- 但它仍是 P5/P6 剩余未实机闭环的主要平台项
