export const healthStatus = ['ok'] as const;

export type HealthStatus = (typeof healthStatus)[number];

export interface HealthResponse {
  status: HealthStatus;
  service: 'api';
  timestamp: string;
}

export function createHealthResponse(now = new Date()): HealthResponse {
  return {
    status: 'ok',
    service: 'api',
    timestamp: now.toISOString(),
  };
}

