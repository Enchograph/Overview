# Overview

Overview（览）V1 monorepo。

当前仓库已包含：

- Flutter 客户端：Android、Web 已验证构建；Windows 平台工程已生成
- Node.js + TypeScript API：本地开发模式可启动
- PostgreSQL migration、邮箱认证、规划 CRUD、AI 解析/问答/转写、Android 通知与快捷入口

## 目录

- `apps/client/`：Flutter 客户端
- `services/api/`：Node.js + TypeScript API
- `packages/shared/`：共享契约与检查脚本
- `docs/`：项目状态、交接、路线图与运行规则

## 环境要求

- Node.js 20+
- `npx pnpm`
- Flutter 3.41+
- Android SDK
- Java 17
- PostgreSQL 15+：仅在需要真实数据库运行 API 时必需

可选：

- OpenAI API Key：启用真实 OpenAI provider
- Azure Speech Key/Region：启用真实语音转写
- Windows 主机：构建 Windows 客户端

## 首次安装

1. 安装根依赖：

```bash
npx pnpm install
```

2. 安装 Flutter 客户端依赖：

```bash
cd apps/client
flutter pub get
```

3. 准备 API 环境变量：

```bash
cp services/api/.env.example services/api/.env
```

4. 如需真实 PostgreSQL，修改 `services/api/.env` 里的 `DATABASE_URL`

## 启动 API

开发模式：

```bash
npm run api:dev
```

单次启动：

```bash
npm run api:start
```

无本机 PostgreSQL 时可直接使用嵌入式开发模式：

```bash
npm run api:start:embedded
```

执行 migration：

```bash
npx pnpm --filter @overview/api db:migrate
```

默认地址：

- `http://127.0.0.1:3000`
- 健康检查：`GET /health`

说明：

- `api:start` 适合已准备本机 PostgreSQL 的环境
- `api:start:embedded` 会自动拉起临时 PostgreSQL、执行 migration，并在进程退出后清理临时数据

## 启动客户端

本地示例数据模式：

```bash
cd apps/client
flutter run
```

连接本地 API：

```bash
cd apps/client
flutter run --dart-define=OVERVIEW_API_BASE_URL=http://10.0.2.2:3000
```

说明：

- Android 模拟器访问宿主机 API 时优先使用 `10.0.2.2`
- 桌面/Web 调试时通常可直接使用 `http://127.0.0.1:3000`

## 常用验证命令

客户端：

```bash
cd apps/client
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

API：

```bash
npm run api:lint
npm run api:typecheck
npm run api:test
npm run e2e:client-api
```

共享包：

```bash
npm run shared:typecheck
npm run shared:check
```

## 构建输出

- Android debug APK：`apps/client/build/app/outputs/flutter-apk/app-debug.apk`
- Android release APK：`apps/client/build/app/outputs/flutter-apk/app-release.apk`
- Web 静态资源：`apps/client/build/web`
- Windows：需在 Windows 主机运行 `cd apps/client && flutter build windows`

当前 Android release 构建说明：

- 已在 2026-03-12 通过 `cd apps/client && /home/anon/sdk/flutter/bin/flutter build apk --release --no-pub` 产出首个 release APK
- 当前已支持通过 `apps/client/android/key.properties` 或环境变量注入正式签名材料
- 若未提供签名材料，`release` 会回退到 debug keystore，仅适合开发交付与安装验证，不适合作为正式商店分发签名
- 正式签名切换步骤见 [docs/ANDROID_RELEASE_CHECKLIST.md](/home/anon/文档/GitHub/Overview/docs/ANDROID_RELEASE_CHECKLIST.md)

## AI 与语音

默认行为：

- `AI_PROVIDER=auto`
- 未配置 `OPENAI_API_KEY` 时回退到仓库内 heuristic provider
- `AZURE_SPEECH_LOCALE` 默认 `zh-CN`

启用真实 OpenAI：

- 设置 `OPENAI_API_KEY`
- 可选设置 `OPENAI_MODEL`

启用真实 Azure Speech：

- 设置 `AZURE_SPEECH_KEY`
- 设置 `AZURE_SPEECH_REGION`

## 已知限制

见 [docs/KNOWN_LIMITATIONS.md](/home/anon/文档/GitHub/Overview/docs/KNOWN_LIMITATIONS.md)。
