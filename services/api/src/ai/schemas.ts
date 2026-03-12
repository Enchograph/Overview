import { z } from 'zod';

export const ingestTextSchema = z.object({
  text: z.string().trim().min(1).max(500),
});

export const askQuestionSchema = z.object({
  question: z.string().trim().min(1).max(500),
});

export const transcribeAudioSchema = z.object({
  audioBase64: z.string().trim().min(1),
  mimeType: z.string().trim().min(1).max(100),
  locale: z.string().trim().min(2).max(20).default('zh-CN'),
});
