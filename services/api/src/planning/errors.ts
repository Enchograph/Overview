import { ZodError } from 'zod';

export class HttpError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
    public readonly code?: string,
  ) {
    super(message);
  }
}

export function toErrorResponse(error: unknown): {
  statusCode: number;
  payload: { error: string; code?: string; details?: string[] };
} {
  if (error instanceof ZodError) {
    return {
      statusCode: 400,
      payload: {
        error: 'Invalid request',
        code: 'invalid_request',
        details: error.issues.map((issue) => issue.message),
      },
    };
  }

  if (error instanceof HttpError) {
    return {
      statusCode: error.statusCode,
      payload: { error: error.message, code: error.code },
    };
  }

  return {
    statusCode: 500,
    payload: { error: 'Internal Server Error', code: 'internal_server_error' },
  };
}
