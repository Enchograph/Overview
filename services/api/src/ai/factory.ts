import OpenAI from 'openai';

import type { AppEnv } from '../config/env.js';
import type { PlanningRepository } from '../planning/types.js';
import { HeuristicAiService } from './heuristic-service.js';
import { OpenAiService } from './openai-service.js';
import type { AiProviderContext, AiService } from './types.js';

export function createAiService(
  env: AppEnv,
  planningRepository: PlanningRepository,
): AiService {
  const heuristic = new HeuristicAiService(planningRepository);

  if (env.AI_PROVIDER === 'heuristic') {
    return heuristic;
  }

  if (env.AI_PROVIDER === 'openai' || env.OPENAI_API_KEY) {
    if (!env.OPENAI_API_KEY) {
      throw new Error('OPENAI_API_KEY is required when AI_PROVIDER=openai.');
    }

    return new OpenAiService(
      new OpenAI({ apiKey: env.OPENAI_API_KEY }),
      env.OPENAI_MODEL,
      (userId) => loadAiContext(planningRepository, userId),
    );
  }

  return heuristic;
}

async function loadAiContext(
  planningRepository: PlanningRepository,
  userId: string,
): Promise<AiProviderContext> {
  const [schedules, tasks, memos] = await Promise.all([
    planningRepository.listSchedules(userId),
    planningRepository.listTasks(userId),
    planningRepository.listMemos(userId),
  ]);

  return {
    schedulesSummary: [
      'Schedules:',
      ...schedules.map((item) => `- ${item.title} @ ${item.startAt}`),
    ].join('\n'),
    tasksSummary: [
      'Tasks:',
      ...tasks.map((item) => `- ${item.title} due ${item.dueAt} status=${item.status}`),
    ].join('\n'),
    memosSummary: [
      'Memos:',
      ...memos.map((item) => `- ${item.title} status=${item.status}`),
    ].join('\n'),
  };
}
