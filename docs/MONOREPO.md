# Overview Monorepo 管理方案

## 结论

Overview 采用 `pnpm workspace` 作为根级 monorepo 管理方式。

当前不引入 `melos`、`turbo`、`nx` 等额外编排层，原因是 P0/P1 阶段只有一个 Flutter 客户端、一个 Node.js 后端和少量共享定义，先保持工具链最小化。

## 选择理由

- 对 `services/*` 与未来的 TypeScript 工具包支持直接、成熟
- 根目录可以统一维护脚本入口，便于后续接入 lint、test、build、dev
- 不强耦合 Flutter 工程结构，`apps/client` 继续使用原生 `flutter pub`
- 学习和维护成本低，适合当前仓库从 0 到 1 的初始化阶段

## 工作区边界

- `apps/client/`
  - Flutter 客户端工程
  - 依赖管理由 `flutter pub` 负责
- `services/api/`
  - Node.js + TypeScript 后端
  - 依赖管理由 `pnpm` 负责
- `packages/shared/`
  - 跨端共享的接口契约、JSON Schema、OpenAPI 定义、常量文档
  - 不默认承诺“同一份运行时代码同时给 Flutter 和 Node 直接复用”

## 根目录约定

- 根目录保留 `package.json` 作为统一命令入口
- 根目录保留 `pnpm-workspace.yaml` 管理 `services/*` 与 `packages/*`
- Flutter 相关命令通过根脚本转发到 `apps/client`
- 仓库级自动化脚本放在 `scripts/`

## 暂不采用的方案

- `melos`
  - 更适合多 Dart/Flutter package 仓库；当前只有单一 Flutter 应用，收益不足
- `turbo` / `nx`
  - 适合更复杂的多包增量编排；当前阶段会引入额外心智负担

## 后续落地顺序

1. 初始化根目录 `package.json` 与 `pnpm-workspace.yaml`
2. 初始化 `apps/client` Flutter 工程
3. 初始化 `services/api` Node.js + TypeScript 工程
4. 为根目录补齐统一 `dev`、`build`、`test` 命令入口
