import { z } from 'zod';

export const ingestTextSchema = z.object({
  text: z.string().trim().min(1).max(500),
});

export const askQuestionSchema = z.object({
  question: z.string().trim().min(1).max(500),
});
