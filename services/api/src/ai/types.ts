export interface AiStructuredSuggestion {
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

export interface AiAnswer {
  answer: string;
  referencedItemCount: number;
}

export interface AiService {
  ingestText(userId: string, text: string): Promise<AiStructuredSuggestion>;
  answerQuestion(userId: string, question: string): Promise<AiAnswer>;
}
