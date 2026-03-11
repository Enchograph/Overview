# Overview 仓库结构说明

## 顶层目录

- `docs/`
  - 产品文档、运行规则、状态、路线图、TODO、交接记录
- `apps/`
  - 客户端应用
- `services/`
  - 后端服务
- `packages/`
  - 共享模型、契约、工具、设计资源
- `scripts/`
  - 自动化脚本、构建入口、辅助检查

## 当前约定

- 根级 monorepo
  - 使用 `pnpm workspace` 统一管理仓库级命令与 Node.js 工作区
  - 详细约定见 `docs/MONOREPO.md`
- `apps/client/`
  - Flutter 全端客户端主应用
- `services/api/`
  - Node.js + TypeScript 后端 API 服务
- `packages/shared/`
  - 共享接口契约、Schema、公共常量与跨端约定文档

## 变更规则

- 新增顶层目录前，必须先更新本文件
- 新增核心子系统时，必须在对应目录中提供 README 或说明文件
- 不允许将关键代码散落到未登记目录
