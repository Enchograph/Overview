# api

Node.js + TypeScript 后端 API 服务目录。

当前状态：已升级为基于 Express 的 TypeScript API 服务骨架，并接入环境变量校验、lint、format、test 与 build 入口。

## 当前内容

- `src/index.ts`：服务入口
- `src/app.ts`：Express 应用装配
- `src/config/env.ts`：环境变量加载与校验
- `src/routes/`：API 路由模块
- `test/health.test.ts`：健康检查与 404 行为测试
- `package.json` / `tsconfig*.json`：服务脚本与 TS 配置
- `eslint.config.mjs` / `.prettierrc.json`：代码质量入口

## 本地命令

- `corepack pnpm install`
- `npm run api:dev`
- `npm run api:start`
- `npm run api:lint`
- `npm run api:format`
- `npm run api:typecheck`
- `npm run api:test`
- `npm run api:build`
