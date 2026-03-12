import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const rootDir = path.dirname(fileURLToPath(new URL('../package.json', import.meta.url)));
const clientDir = path.join(rootDir, 'apps', 'client');
const apiBaseUrl = 'http://127.0.0.1:3000';
const flutterBin = process.env.FLUTTER_BIN ?? '/home/anon/sdk/flutter/bin/flutter';
const testEmail = `e2e-${Date.now()}@example.com`;
const testPassword = 'Password123';
const testMemoTitle = `E2E Memo ${Date.now()}`;

function spawnLogged(command, args, options = {}) {
  const child = spawn(command, args, {
    cwd: rootDir,
    stdio: ['ignore', 'pipe', 'pipe'],
    ...options,
  });

  let logs = '';
  child.stdout?.on('data', (chunk) => {
    const text = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    logs += text;
    process.stdout.write(text);
  });
  child.stderr?.on('data', (chunk) => {
    const text = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    logs += text;
    process.stderr.write(text);
  });

  return { child, getLogs: () => logs };
}

async function waitForHealth(timeoutMs = 120_000) {
  const deadline = Date.now() + timeoutMs;
  let lastError = 'health check not attempted';

  while (Date.now() < deadline) {
    try {
      const response = await fetch(`${apiBaseUrl}/health`);
      if (response.ok) {
        const payload = await response.json();
        assert.equal(payload.status, 'ok');
        return;
      }
      lastError = `unexpected status ${response.status}`;
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error);
    }

    await delay(1_000);
  }

  throw new Error(`API health check did not become ready: ${lastError}`);
}

async function requestJson(pathname, { method = 'GET', token, body } = {}) {
  const response = await fetch(`${apiBaseUrl}${pathname}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  const parsed = text ? JSON.parse(text) : null;

  if (!response.ok) {
    throw new Error(
      `${method} ${pathname} failed with ${response.status}: ${text}`,
    );
  }

  return parsed;
}

async function waitForRemoteMemo(token, expectedTitle, timeoutMs = 30_000) {
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    const payload = await requestJson('/planning/memos', { token });
    const items = payload.items ?? [];
    if (items.some((item) => item.title === expectedTitle)) {
      return;
    }
    await delay(1_000);
  }

  throw new Error(`Remote memo "${expectedTitle}" was not found after sync.`);
}

async function waitForExit(child, timeoutMs = 20_000) {
  return await new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(`Process did not exit within ${timeoutMs}ms.`));
    }, timeoutMs);

    child.once('error', (error) => {
      clearTimeout(timer);
      reject(error);
    });
    child.once('exit', (code, signal) => {
      clearTimeout(timer);
      resolve({ code, signal });
    });
  });
}

async function shutdownProcessGroup(child) {
  if (!child.pid) {
    return;
  }

  try {
    process.kill(-child.pid, 'SIGINT');
    await waitForExit(child);
  } catch {
    try {
      process.kill(-child.pid, 'SIGKILL');
    } catch {}
  }
}

async function runCommand(command, args, options = {}) {
  const child = spawn(command, args, options);
  return await new Promise((resolve, reject) => {
    let logs = '';
    child.stdout?.on('data', (chunk) => {
      const text = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
      logs += text;
      process.stdout.write(text);
    });
    child.stderr?.on('data', (chunk) => {
      const text = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
      logs += text;
      process.stderr.write(text);
    });
    child.once('error', reject);
    child.once('exit', (code) => {
      if (code === 0) {
        resolve(logs);
        return;
      }
      reject(new Error(`${command} ${args.join(' ')} failed with ${code}\n${logs}`));
    });
  });
}

async function main() {
  const { child: apiProcess, getLogs } = spawnLogged(
    'npm',
    ['run', 'api:start:embedded'],
    { cwd: rootDir, detached: true },
  );

  try {
    await waitForHealth();

    await requestJson('/auth/register', {
      method: 'POST',
      body: {
        email: testEmail,
        password: testPassword,
      },
    });

    await runCommand(
      flutterBin,
      [
        'test',
        'test/client_api_e2e_test.dart',
        '--dart-define=OVERVIEW_E2E_REMOTE_ENABLED=true',
        `--dart-define=OVERVIEW_API_BASE_URL=${apiBaseUrl}`,
        `--dart-define=OVERVIEW_E2E_EMAIL=${testEmail}`,
        `--dart-define=OVERVIEW_E2E_PASSWORD=${testPassword}`,
        `--dart-define=OVERVIEW_E2E_MEMO_TITLE=${testMemoTitle}`,
      ],
      { cwd: clientDir, stdio: ['ignore', 'pipe', 'pipe'] },
    );

    const loginPayload = await requestJson('/auth/login', {
      method: 'POST',
      body: {
        email: testEmail,
        password: testPassword,
      },
    });
    await waitForRemoteMemo(loginPayload.token, testMemoTitle);
  } catch (error) {
    throw new Error(
      `${error instanceof Error ? error.message : String(error)}\n\nAPI logs:\n${getLogs()}`,
    );
  } finally {
    await shutdownProcessGroup(apiProcess);
  }
}

await main();
