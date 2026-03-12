export const AiErrorCodes = {
  authorizationRequired: 'authorization_required',
  azureSpeechNotConfigured: 'azure_speech_not_configured',
  azureSpeechFailed: 'azure_speech_failed',
  azureSpeechEmpty: 'azure_speech_empty',
  openAiStructuredInvalid: 'openai_structured_invalid',
  openAiAnswerInvalid: 'openai_answer_invalid',
} as const;

export type AiErrorCode =
  (typeof AiErrorCodes)[keyof typeof AiErrorCodes];
