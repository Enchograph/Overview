import assert from 'node:assert/strict';
import { spawn, type ChildProcess } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';

async function waitForHealth(port: number): Promise<void> {
  const deadline = Date.now() + 90_000;
  let lastError: unknown;

  while (Date.now() < deadline) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/health`);
      if (response.ok) {
        const body = (await response.json()) as { status?: string };
        assert.equal(body.status, 'ok');
        return;
      }

      lastError = new Error(`Unexpected status code: ${response.status}`);
    } catch (error) {
      lastError = error;
    }

    await delay(1_000);
  }

  throw new Error(
    `Embedded startup health check did not become ready in time: ${String(lastError)}`,
  );
}

async function stopChild(child: ChildProcess): Promise<number | null> {
  if (child.pid) {
    process.kill(-child.pid, 'SIGINT');
  } else {
    child.kill('SIGINT');
  }

  return await new Promise((resolvePromise, reject) => {
    child.once('error', reject);
    child.once('exit', (code) => resolvePromise(code));
  });
}

async function main(): Promise<void> {
  const port = 3100;
  const apiDir = fileURLToPath(new URL('..', import.meta.url));
  const child = spawn('npx', ['pnpm', 'start:embedded'], {
    cwd: apiDir,
    detached: true,
    env: {
      ...process.env,
      HOST: '127.0.0.1',
      PORT: String(port),
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  let logs = '';
  child.stdout.on('data', (chunk: Buffer | string) => {
    logs += typeof chunk === 'string' ? chunk : chunk.toString('utf8');
  });
  child.stderr.on('data', (chunk: Buffer | string) => {
    logs += typeof chunk === 'string' ? chunk : chunk.toString('utf8');
  });

  try {
    await waitForHealth(port);
  } catch (error) {
    child.kill('SIGKILL');
    throw new Error(
      `Embedded startup smoke test failed before health check succeeded.\n${logs}\n${String(error)}`,
    );
  }

  const exitCode = await stopChild(child);
  assert.ok(
    exitCode === 0 || exitCode === null,
    `Embedded startup exited with code ${exitCode}.\n${logs}`,
  );
}

await main();
