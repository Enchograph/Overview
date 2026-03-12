import type { AppEnv } from '../config/env.js';
import { AzureSpeechTranscriber } from './azure-speech-transcriber.js';
import type { AiSpeechTranscriber } from './composite-service.js';

export function createSpeechTranscriber(
  env: AppEnv,
): AiSpeechTranscriber | undefined {
  if (env.AI_SPEECH_PROVIDER === 'none') {
    return undefined;
  }

  if (!env.AZURE_SPEECH_KEY || !env.AZURE_SPEECH_REGION) {
    return undefined;
  }

  return new AzureSpeechTranscriber(
    env.AZURE_SPEECH_KEY,
    env.AZURE_SPEECH_REGION,
    env.AZURE_SPEECH_LOCALE,
  );
}
