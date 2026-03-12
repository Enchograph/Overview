# AI 语音转写选型

## 当前结论

Overview V1 当前正式语音转写选型确定为 `Azure Speech`。

选择原因：

- 当前产品优先面向中文用户，默认 locale 设为 `zh-CN`
- Azure Speech 已能覆盖简体中文、繁体中文与英文等后续 i18n 扩展所需的 BCP-47 locale
- 现有 API 已经落地 Azure 接入，继续保留可减少返工
- 当前仓库已抽象为通用 speech provider 接口，后续如需增加第二供应商，不需要重写客户端主链路

## 当前实现约束

- 服务端新增 `AI_SPEECH_PROVIDER`，当前支持：
  - `azure`
  - `none`
- 当 `AI_SPEECH_PROVIDER=azure` 且配置了 `AZURE_SPEECH_KEY`、`AZURE_SPEECH_REGION` 时启用真实语音转写
- 客户端与服务端都会把应用 locale 规范化为适合语音服务的 BCP-47 locale
- 当前默认中文使用 `zh-CN`
- 当前已为后续语言扩展预留：
  - `zh-TW`
  - `zh-HK`
  - `en-US`
  - `en-GB`
  - `ja-JP`
  - `ko-KR`
  - `fr-FR`
  - `de-DE`
  - `es-ES`

## 当前未完成

- 真实 Azure Speech 凭据仍未在仓库内验证
- 中文短音频真转写仍需至少完成一次真实录音验证

## 下一步

1. 提供 `AZURE_SPEECH_KEY`
2. 提供 `AZURE_SPEECH_REGION`
3. 启动 API
4. 通过客户端录音流或 `/ai/transcribe` 完成一次中文真音频验证
