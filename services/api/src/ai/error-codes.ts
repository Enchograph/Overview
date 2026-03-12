export const AiErrorCodes = {
  authorizationRequired: 'authorization_required',
  speechNotConfigured: 'speech_not_configured',
  speechFailed: 'speech_failed',
  speechEmpty: 'speech_empty',
  openAiStructuredInvalid: 'openai_structured_invalid',
  openAiAnswerInvalid: 'openai_answer_invalid',
} as const;

export type AiErrorCode =
  (typeof AiErrorCodes)[keyof typeof AiErrorCodes];
