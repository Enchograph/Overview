import { execFile } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { access, constants } from 'node:fs/promises';
import { homedir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);
const projectRoot = resolve(fileURLToPath(new URL('..', import.meta.url)));
const androidDir = resolve(projectRoot, 'apps/client/android');
const keyPropertiesPath = resolve(androidDir, 'key.properties');
const apkPath = resolve(
  projectRoot,
  'apps/client/build/app/outputs/flutter-apk/app-release.apk',
);

function readKeyProperties() {
  if (!existsSync(keyPropertiesPath)) {
    return {};
  }

  return Object.fromEntries(
    readFileSync(keyPropertiesPath, 'utf8')
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const separatorIndex = line.indexOf('=');
        return [
          line.slice(0, separatorIndex).trim(),
          line.slice(separatorIndex + 1).trim(),
        ];
      }),
  );
}

function pickSigningValue(properties, propertyName, envName) {
  const propertyValue = properties[propertyName];
  if (propertyValue) {
    return {
      value: propertyValue,
      source: `key.properties:${propertyName}`,
    };
  }

  const envValue = process.env[envName]?.trim();
  if (envValue) {
    return {
      value: envValue,
      source: `env:${envName}`,
    };
  }

  return {
    value: undefined,
    source: 'missing',
  };
}

async function resolveReadableFile(pathValue) {
  if (!pathValue) {
    return 'missing';
  }

  const expandedPath = pathValue.startsWith('~/')
    ? join(homedir(), pathValue.slice(2))
    : pathValue;
  const absolutePath = resolve(expandedPath);

  try {
    await access(absolutePath, constants.R_OK);
    return absolutePath;
  } catch {
    return `unreadable:${absolutePath}`;
  }
}

function sha256OfFile(pathValue) {
  const hash = createHash('sha256');
  hash.update(readFileSync(pathValue));
  return hash.digest('hex');
}

async function detectAdbOutput() {
  try {
    const { stdout } = await execFileAsync('adb', ['devices']);
    return stdout;
  } catch {
    return null;
  }
}

function parseConnectedDevices(adbOutput) {
  if (!adbOutput) {
    return [];
  }

  return adbOutput
    .split(/\r?\n/)
    .slice(1)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('*'))
    .map((line) => line.split(/\s+/)[0])
    .filter(Boolean);
}

async function main() {
  const properties = readKeyProperties();
  const storeFile = pickSigningValue(
    properties,
    'storeFile',
    'OVERVIEW_ANDROID_STORE_FILE',
  );
  const storePassword = pickSigningValue(
    properties,
    'storePassword',
    'OVERVIEW_ANDROID_STORE_PASSWORD',
  );
  const keyAlias = pickSigningValue(
    properties,
    'keyAlias',
    'OVERVIEW_ANDROID_KEY_ALIAS',
  );
  const keyPassword = pickSigningValue(
    properties,
    'keyPassword',
    'OVERVIEW_ANDROID_KEY_PASSWORD',
  );

  const resolvedStoreFile = await resolveReadableFile(storeFile.value);
  const signingReady =
    !!storePassword.value &&
    !!keyAlias.value &&
    !!keyPassword.value &&
    typeof resolvedStoreFile === 'string' &&
    resolvedStoreFile !== 'missing' &&
    !resolvedStoreFile.startsWith('unreadable:');

  const apkExists = existsSync(apkPath);
  const apkSha256 = apkExists ? sha256OfFile(apkPath) : null;
  const adbOutput = await detectAdbOutput();
  const connectedDevices = parseConnectedDevices(adbOutput);

  console.log('Android release readiness');
  console.log(`- key.properties: ${existsSync(keyPropertiesPath) ? 'present' : 'missing'}`);
  console.log(`- storeFile: ${resolvedStoreFile} (${storeFile.source})`);
  console.log(
    `- storePassword: ${storePassword.value ? 'present' : 'missing'} (${storePassword.source})`,
  );
  console.log(`- keyAlias: ${keyAlias.value ?? 'missing'} (${keyAlias.source})`);
  console.log(
    `- keyPassword: ${keyPassword.value ? 'present' : 'missing'} (${keyPassword.source})`,
  );
  console.log(`- release signing ready: ${signingReady ? 'yes' : 'no'}`);
  console.log(`- release apk: ${apkExists ? apkPath : 'missing'}`);
  if (apkSha256) {
    console.log(`- release apk sha256: ${apkSha256}`);
  }
  console.log(`- adb available: ${adbOutput ? 'yes' : 'no'}`);
  console.log(
    `- connected android devices: ${connectedDevices.length > 0 ? connectedDevices.join(', ') : 'none'}`,
  );

  const blockers = [];
  if (!signingReady) {
    blockers.push('formal release signing material is incomplete');
  }
  if (!apkExists) {
    blockers.push('release apk has not been built yet');
  }
  if (connectedDevices.length === 0) {
    blockers.push('no Android device is connected for install verification');
  }

  if (blockers.length > 0) {
    console.log('');
    console.log('Blocking gaps:');
    for (const blocker of blockers) {
      console.log(`- ${blocker}`);
    }
    process.exitCode = 1;
    return;
  }

  console.log('');
  console.log('Ready to run signed release install verification.');
}

await main();
