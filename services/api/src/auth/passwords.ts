import { randomBytes, scrypt as nodeScrypt, timingSafeEqual } from 'node:crypto';
const keyLength = 64;

async function scrypt(password: string, salt: string): Promise<Buffer> {
  return await new Promise((resolve, reject) => {
    nodeScrypt(password, salt, keyLength, (error, derivedKey) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(derivedKey);
    });
  });
}

export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16).toString('hex');
  const derivedKey = await scrypt(password, salt);
  return `${salt}:${derivedKey.toString('hex')}`;
}

export async function verifyPassword(
  password: string,
  passwordHash: string,
): Promise<boolean> {
  const [salt, storedHash] = passwordHash.split(':');
  if (!salt || !storedHash) {
    return false;
  }

  const derivedBuffer = await scrypt(password, salt);
  const storedBuffer = Buffer.from(storedHash, 'hex');

  if (derivedBuffer.length != storedBuffer.length) {
    return false;
  }

  return timingSafeEqual(derivedBuffer, storedBuffer);
}
