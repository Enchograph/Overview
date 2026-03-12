import { HttpError } from '../planning/errors.js';
import type { AiAudioInput, AiTranscription } from './types.js';
import type { AiSpeechTranscriber } from './composite-service.js';

interface AzureSpeechResponse {
  RecognitionStatus?: string;
  DisplayText?: string;
  Offset?: number;
  Duration?: number;
}

export class AzureSpeechTranscriber implements AiSpeechTranscriber {
  constructor(
    private readonly key: string,
    private readonly region: string,
  ) {}

  async transcribeAudio(
    _userId: string,
    input: AiAudioInput,
  ): Promise<AiTranscription> {
    const response = await fetch(
      `https://${this.region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=${encodeURIComponent(input.locale)}&format=simple`,
      {
        method: 'POST',
        headers: {
          Accept: 'application/json;text/xml',
          'Content-Type': input.mimeType,
          'Ocp-Apim-Subscription-Key': this.key,
        },
        body: Buffer.from(input.audioBase64, 'base64'),
      },
    );

    if (!response.ok) {
      throw new HttpError(
        502,
        `Azure Speech transcription failed with ${response.status}.`,
      );
    }

    const payload = (await response.json()) as AzureSpeechResponse;
    if (
      payload.RecognitionStatus !== 'Success' ||
      !payload.DisplayText ||
      payload.DisplayText.trim().length === 0
    ) {
      throw new HttpError(502, 'Azure Speech returned an empty transcription.');
    }

    return {
      text: payload.DisplayText.trim(),
      locale: input.locale,
    };
  }
}
