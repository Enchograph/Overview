# 交付索引

## 核心入口

- 仓库总入口：[README.md](/home/anon/文档/GitHub/Overview/README.md)
- 项目当前状态：[PROJECT_STATUS.md](/home/anon/文档/GitHub/Overview/docs/PROJECT_STATUS.md)
- 当前交接记录：[HANDOFF.md](/home/anon/文档/GitHub/Overview/docs/HANDOFF.md)
- 已知限制：[KNOWN_LIMITATIONS.md](/home/anon/文档/GitHub/Overview/docs/KNOWN_LIMITATIONS.md)
- 剩余阻塞清单：[REMAINING_RELEASE_BLOCKERS.md](/home/anon/文档/GitHub/Overview/docs/REMAINING_RELEASE_BLOCKERS.md)

## 客户端交付

- 客户端说明：[apps/client/README.md](/home/anon/文档/GitHub/Overview/apps/client/README.md)
- Android 正式签名与发布清单：[ANDROID_RELEASE_CHECKLIST.md](/home/anon/文档/GitHub/Overview/docs/ANDROID_RELEASE_CHECKLIST.md)
- Windows 主机构建与验证说明：[WINDOWS_VALIDATION.md](/home/anon/文档/GitHub/Overview/docs/WINDOWS_VALIDATION.md)

## 后端交付

- API 说明：[services/api/README.md](/home/anon/文档/GitHub/Overview/services/api/README.md)
- 嵌入式启动入口：`npm run api:start:embedded`
- API 测试入口：`npm run api:test`

## 验证入口

- 客户端静态与 widget 验证：
  - `cd apps/client && /home/anon/sdk/flutter/bin/flutter analyze`
  - `cd apps/client && /home/anon/sdk/flutter/bin/flutter test`
- 客户端主流程烟测：
  - `cd apps/client && /home/anon/sdk/flutter/bin/flutter test test/main_flow_smoke_test.dart`
- 客户端到 API 单脚本端到端：
  - `npm run e2e:client-api`
- Android release 构建：
  - `cd apps/client && /home/anon/sdk/flutter/bin/flutter build apk --release --no-pub`
- API 验证：
  - `npm run api:lint`
  - `npm run api:typecheck`
  - `npm run api:test`

## 当前仍未闭环

- 正式 Android 发布签名材料尚未进入仓库
- Windows 真实主机构建仍未在仓库内完成
- `integration_test/main_flow_test.dart` 仍未在可用桌面 runner 上真实执行
