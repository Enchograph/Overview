# 剩余发布阻塞清单

## 当前结论

截至 2026-03-12，Overview V1 的仓库内主要能力已经打通：

- Android debug 与 release APK 可构建
- API 可本地启动
- 客户端主流程 smoke 可执行
- 客户端到 API 的单脚本端到端验证可执行

当前剩余阻塞主要集中在“正式发布材料”与“跨主机/外部凭据验证”。

## 阻塞项 1：Android 正式签名材料缺失

现状：

- 仓库已支持 `key.properties` / `OVERVIEW_ANDROID_*` 环境变量
- 未提供正式签名材料时，release 会回退到 debug keystore

要闭环此项，需要：

1. 准备正式 keystore 与密码材料
2. 通过 `apps/client/android/key.properties` 或环境变量注入
3. 重新执行：

```bash
cd apps/client
/home/anon/sdk/flutter/bin/flutter build apk --release --no-pub
```

4. 记录正式签名 APK 的 `sha256`
5. 至少完成一次真机安装验证

参考：

- [ANDROID_RELEASE_CHECKLIST.md](/home/anon/文档/GitHub/Overview/docs/ANDROID_RELEASE_CHECKLIST.md)

## 阻塞项 2：Windows 真实主机构建未验证

现状：

- 仓库内已完成 Windows 工程与桌面布局代码级验证
- 当前 Linux 主机无法执行 `flutter build windows`

要闭环此项，需要在 Windows 主机执行：

```bash
cd apps/client
flutter analyze
flutter test
flutter build windows
```

并完成最小手工验证：

- 周视图可打开
- 添加页可创建条目
- 设置页账号入口可打开
- 桌面快捷入口与刷新按钮可用

参考：

- [WINDOWS_VALIDATION.md](/home/anon/文档/GitHub/Overview/docs/WINDOWS_VALIDATION.md)

## 阻塞项 3：Azure Speech 真实凭据未验证

现状：

- API 与客户端语音转写接口已完成
- 自动化覆盖了未配置与错误码路径
- 真实 Azure Speech key/region 尚未验证

要闭环此项，需要：

1. 提供 `AZURE_SPEECH_KEY`
2. 提供 `AZURE_SPEECH_REGION`
3. 启动 API
4. 通过客户端录音流或 `/ai/transcribe` 实际验证一次中文短音频转写

## 阻塞项 4：`integration_test` 真实 runner 未执行

现状：

- `integration_test/main_flow_test.dart` 已存在
- 当前 Linux 主机缺少 Flutter Linux runner 所需 `clang` 工具链
- Web runner 目前不支持 Flutter integration test

已替代的仓库内验证：

- `flutter test test/main_flow_smoke_test.dart`
- `npm run e2e:client-api`

要闭环此项，需要：

- 在具备可用 Flutter runner 的主机上执行真实 `integration_test`
- 或补齐当前 Linux 主机所需桌面 runner 工具链

## 推荐执行顺序

1. 正式签名材料接入与 Android 真机安装验证
2. Windows 主机构建与最小手工验证
3. Azure Speech 真实凭据验证
4. 真实 `integration_test` runner 验证

## 说明

- 上述 4 项中，仓库内当前无法自主完成的核心原因分别是：
  - 缺签名材料
  - 缺 Windows 主机
  - 缺 Azure 真实凭据
  - 缺可用 integration runner 环境
- 因此当前最有效的仓库内动作应以文档清单化和入口收敛为主，而不是伪造通过状态
