import { ZodError } from 'zod';

export class HttpError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
  }
}

export function toErrorResponse(error: unknown): {
  statusCode: number;
  payload: { error: string; details?: string[] };
} {
  if (error instanceof ZodError) {
    return {
      statusCode: 400,
      payload: {
        error: 'Invalid request',
        details: error.issues.map((issue) => issue.message),
      },
    };
  }

  if (error instanceof HttpError) {
    return {
      statusCode: error.statusCode,
      payload: { error: error.message },
    };
  }

  return {
    statusCode: 500,
    payload: { error: 'Internal Server Error' },
  };
}
