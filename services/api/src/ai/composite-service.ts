import { HttpError } from '../planning/errors.js';
import type {
  AiAnswer,
  AiAudioInput,
  AiService,
  AiStructuredSuggestion,
  AiTranscription,
} from './types.js';

export interface AiSpeechTranscriber {
  transcribeAudio(userId: string, input: AiAudioInput): Promise<AiTranscription>;
}

export class CompositeAiService implements AiService {
  constructor(
    private readonly delegate: AiService,
    private readonly speechTranscriber?: AiSpeechTranscriber,
  ) {}

  ingestText(userId: string, text: string): Promise<AiStructuredSuggestion> {
    return this.delegate.ingestText(userId, text);
  }

  answerQuestion(userId: string, question: string): Promise<AiAnswer> {
    return this.delegate.answerQuestion(userId, question);
  }

  transcribeAudio(
    userId: string,
    input: AiAudioInput,
  ): Promise<AiTranscription> {
    if (!this.speechTranscriber) {
      throw new HttpError(
        503,
        'Voice transcription requires Azure Speech configuration.',
      );
    }

    return this.speechTranscriber.transcribeAudio(userId, input);
  }
}
