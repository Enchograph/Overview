# shared

共享类型、接口契约、公共常量目录。

当前状态：已建立基础健康检查契约与核心规划数据模型，并可编译为 workspace 共享包供服务端消费。

## 当前内容

- `src/contracts.ts`：共享健康检查响应结构
- `src/planning.ts`：日程、任务、备忘、提醒、重复规则等核心模型
- `src/index.ts`：共享导出入口
- `package.json`：workspace 包声明与构建脚本
- `tsconfig.json`：共享包编译配置
