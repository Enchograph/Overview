import type OpenAI from 'openai';

import { HttpError } from '../planning/errors.js';
import type {
  AiAnswer,
  AiProviderContext,
  AiService,
  AiStructuredSuggestion,
} from './types.js';

interface OpenAiStructuredResponse {
  suggestedType: 'schedule' | 'task' | 'memo';
  title: string;
  confidence: number;
  requiresConfirmation: string[];
  extracted: {
    startAt?: string;
    endAt?: string;
    dueAt?: string;
    location?: string;
    durationMinutes?: number;
  };
}

interface OpenAiAnswerResponse {
  answer: string;
}

export class OpenAiService implements AiService {
  constructor(
    private readonly client: OpenAI,
    private readonly model: string,
    private readonly loadContext: (userId: string) => Promise<AiProviderContext>,
  ) {}

  async ingestText(
    userId: string,
    text: string,
  ): Promise<AiStructuredSuggestion> {
    const context = await this.loadContext(userId);
    const response = await this.client.responses.create({
      model: this.model,
      instructions:
        'You convert planning text into a single structured suggestion. Return JSON only with keys: suggestedType, title, confidence, requiresConfirmation, extracted.',
      input: [
        {
          role: 'user',
          content: [
            {
              type: 'input_text',
              text:
                `Current user planning context:\n${context.schedulesSummary}\n${context.tasksSummary}\n${context.memosSummary}\n\nText to parse:\n${text}`,
            },
          ],
        },
      ],
    });

    return _parseStructuredResponse(response.output_text);
  }

  async answerQuestion(userId: string, question: string): Promise<AiAnswer> {
    const context = await this.loadContext(userId);
    const response = await this.client.responses.create({
      model: this.model,
      instructions:
        'You answer one planning question using only the provided user planning context. Return JSON only with key: answer.',
      input: [
        {
          role: 'user',
          content: [
            {
              type: 'input_text',
              text:
                `Current user planning context:\n${context.schedulesSummary}\n${context.tasksSummary}\n${context.memosSummary}\n\nQuestion:\n${question}`,
            },
          ],
        },
      ],
    });

    const parsed = _parseAnswerResponse(response.output_text);
    const referencedItemCount = _countContextItems(context);
    return {
      answer: parsed.answer,
      referencedItemCount,
    };
  }
}

function _parseStructuredResponse(output: string): AiStructuredSuggestion {
  try {
    const parsed = JSON.parse(output) as OpenAiStructuredResponse;
    return {
      suggestedType: parsed.suggestedType,
      title: parsed.title,
      confidence: parsed.confidence,
      requiresConfirmation: parsed.requiresConfirmation ?? [],
      extracted: parsed.extracted ?? {},
    };
  } catch (error) {
    throw new HttpError(
      502,
      `Failed to parse OpenAI structured response: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

function _parseAnswerResponse(output: string): OpenAiAnswerResponse {
  try {
    const parsed = JSON.parse(output) as OpenAiAnswerResponse;
    return {
      answer: parsed.answer,
    };
  } catch (error) {
    throw new HttpError(
      502,
      `Failed to parse OpenAI answer response: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

function _countContextItems(context: AiProviderContext): number {
  return [context.schedulesSummary, context.tasksSummary, context.memosSummary]
      .map((summary) => summary.split('\n').filter((line) => line.startsWith('- ')).length)
      .reduce((total, count) => total + count, 0);
}
