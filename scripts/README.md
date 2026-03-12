# scripts

自动化脚本、构建入口、辅助检查目录。

当前状态：已初始化基础检查脚本。

## 当前内容

- `check-api.ts`：共享健康检查契约的最小验证脚本
- `e2e-client-api.mjs`：拉起嵌入式 API、运行 Flutter 远端主流程测试，并校验 planning 写入已落到真实后端
