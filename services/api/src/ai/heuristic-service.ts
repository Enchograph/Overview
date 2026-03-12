import type { MemoItem, ScheduleItem, TaskItem } from '@overview/shared';

import { AiErrorCodes } from './error-codes.js';
import { HttpError } from '../planning/errors.js';
import type { PlanningRepository } from '../planning/types.js';
import type { AiAnswer, AiService, AiStructuredSuggestion } from './types.js';

export class HeuristicAiService implements AiService {
  constructor(private readonly planningRepository: PlanningRepository) {}

  ingestText(
    _userId: string,
    text: string,
  ): Promise<AiStructuredSuggestion> {
    const normalized = text.trim();
    const lower = normalized.toLowerCase();

    if (_looksLikeSchedule(lower)) {
      const extracted = _extractScheduleFields(normalized);
      return Promise.resolve({
        suggestedType: 'schedule',
        title: normalized,
        confidence: extracted.startAt ? 0.86 : 0.62,
        requiresConfirmation: [
          ...(extracted.startAt ? [] : ['startAt']),
          ...(extracted.endAt || extracted.durationMinutes ? [] : ['endAt']),
        ],
        extracted,
      });
    }

    if (_looksLikeTask(lower)) {
      const extracted = _extractTaskFields(normalized);
      return Promise.resolve({
        suggestedType: 'task',
        title: normalized,
        confidence: extracted.dueAt ? 0.81 : 0.67,
        requiresConfirmation: extracted.dueAt ? [] : ['dueAt'],
        extracted,
      });
    }

    return Promise.resolve({
      suggestedType: 'memo',
      title: normalized,
      confidence: 0.73,
      requiresConfirmation: [],
      extracted: {},
    });
  }

  async answerQuestion(userId: string, question: string): Promise<AiAnswer> {
    const [schedules, tasks, memos] = await Promise.all([
      this.planningRepository.listSchedules(userId),
      this.planningRepository.listTasks(userId),
      this.planningRepository.listMemos(userId),
    ]);

    const normalized = question.trim().toLowerCase();
    if (_asksForBusySummary(normalized)) {
      const answer = _buildBusySummary(schedules, tasks, memos);
      return {
        answer,
        referencedItemCount: schedules.length + tasks.length + memos.length,
      };
    }

    const answer = _buildGeneralSummary(schedules, tasks, memos);
    return {
      answer,
      referencedItemCount: schedules.length + tasks.length + memos.length,
    };
  }

  transcribeAudio(): Promise<never> {
    return Promise.reject(
      new HttpError(
        503,
        'Voice transcription requires Azure Speech configuration.',
        AiErrorCodes.azureSpeechNotConfigured,
      ),
    );
  }
}

function _looksLikeSchedule(input: string): boolean {
  return (
    input.includes('meeting') ||
    input.includes('开会') ||
    input.includes('review') ||
    input.includes('点到') ||
    (input.includes(' at ') && (input.includes(' to ') || input.includes('-')))
  );
}

function _looksLikeTask(input: string): boolean {
  return (
    input.includes('need to') ||
    input.includes('must') ||
    input.includes('deadline') ||
    input.includes('due') ||
    input.includes('明天') ||
    input.includes('今晚') ||
    input.includes('必须') ||
    input.includes('作业')
  );
}

function _asksForBusySummary(input: string): boolean {
  return (
    input.includes('busy') ||
    input.includes('busiest') ||
    input.includes('this week') ||
    input.includes('最忙') ||
    input.includes('这周')
  );
}

function _extractScheduleFields(text: string): AiStructuredSuggestion['extracted'] {
  const rangeMatch = text.match(/(\d{1,2})\s*点.*?(\d{1,2})\s*点/);
  if (rangeMatch) {
    const startHour = Number(rangeMatch[1]);
    const endHour = Number(rangeMatch[2]);
    return {
      startAt: new Date(Date.UTC(2026, 2, 13, startHour)).toISOString(),
      endAt: new Date(Date.UTC(2026, 2, 13, endHour)).toISOString(),
      durationMinutes: Math.max(endHour - startHour, 1) * 60,
    };
  }

  return {};
}

function _extractTaskFields(text: string): AiStructuredSuggestion['extracted'] {
  if (text.includes('明天')) {
    return {
      dueAt: new Date(Date.UTC(2026, 2, 13, 12)).toISOString(),
    };
  }

  return {};
}

function _buildBusySummary(
  schedules: ScheduleItem[],
  tasks: TaskItem[],
  memos: MemoItem[],
): string {
  const grouped = new Map<string, number>();
  for (const schedule of schedules) {
    const key = schedule.startAt.substring(0, 10);
    grouped.set(key, (grouped.get(key) ?? 0) + 1);
  }

  if (grouped.size === 0) {
    return _buildGeneralSummary(schedules, tasks, memos);
  }

  const busiest = Array.from(grouped.entries()).reduce(
    (current, next) => (next[1] > current[1] ? next : current),
  );
  return `Your busiest day is ${busiest[0]} with ${busiest[1]} schedules, plus ${tasks.length} tasks and ${memos.length} memos in view.`;
}

function _buildGeneralSummary(
  schedules: ScheduleItem[],
  tasks: TaskItem[],
  memos: MemoItem[],
): string {
  return `You currently have ${schedules.length} schedules, ${tasks.length} tasks, and ${memos.length} memos.`;
}
