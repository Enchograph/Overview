import { access, readFile, symlink } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { dirname, join, relative } from 'node:path';

const require = createRequire(import.meta.url);
const packageEntry = require.resolve('@embedded-postgres/linux-x64');
const packageDir = dirname(dirname(packageEntry));
const symlinkManifest = join(packageDir, 'native', 'pg-symlinks.json');
const manifestRaw = await readFile(symlinkManifest, 'utf8');
const manifest = JSON.parse(manifestRaw);

for (const entry of manifest) {
  const targetPath = join(packageDir, entry.target);
  const sourcePath = join(packageDir, entry.source);
  const targetDir = dirname(targetPath);
  const relativeSource = relative(targetDir, sourcePath);

  try {
    await symlink(relativeSource, targetPath);
  } catch (error) {
    if (!(error instanceof Error) || !('code' in error) || error.code !== 'EEXIST') {
      throw error;
    }
  }
}

await Promise.all([
  access(join(packageDir, 'native', 'lib', 'libpq.so.5')),
  access(join(packageDir, 'native', 'lib', 'libicuuc.so.60')),
]);
