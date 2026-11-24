import crypto from 'node:crypto';

export const HANDOVER_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
export const HANDOVER_CODE_LENGTH = 6;
export const HANDOVER_TTL_MS = 24 * 60 * 60 * 1000;
export const HANDOVER_MAX_ATTEMPTS = 5;

/**
 * Generates a cryptographically random 6-character uppercase alphanumeric code
 * from [A-HJ-NP-Z2-9] (32 unambiguous symbols, zero modulo bias on 256-byte range).
 */
export function generateHandoverCode(
  randomBytesFn: (size: number) => Buffer = crypto.randomBytes,
): string {
  const bytes = randomBytesFn(HANDOVER_CODE_LENGTH);
  if (bytes.length < HANDOVER_CODE_LENGTH) {
    throw new Error('Insufficient random bytes generated for handover code.');
  }
  let code = '';
  for (let i = 0; i < HANDOVER_CODE_LENGTH; i += 1) {
    code += HANDOVER_CODE_ALPHABET[bytes[i] % HANDOVER_CODE_ALPHABET.length];
  }
  return code;
}

/**
 * Generates a 128-bit per-request hex salt for handover code hashing.
 */
export function generateHandoverSalt(
  randomBytesFn: (size: number) => Buffer = crypto.randomBytes,
): string {
  return randomBytesFn(16).toString('hex');
}

/**
 * Normalizes user-supplied handover codes prior to hashing/comparison.
 */
export function normalizeHandoverCode(code: string): string {
  return code.trim().toUpperCase();
}

/**
 * Computes SHA-256(salt + ':' + normalizedCode) as lowercase hex.
 */
export function hashHandoverCode(code: string, salt: string): string {
  const normalized = normalizeHandoverCode(code);
  return crypto
    .createHash('sha256')
    .update(`${salt}:${normalized}`, 'utf8')
    .digest('hex');
}

/**
 * Constant-time SHA-256 verification against a stored salt and hex digest.
 */
export function verifyHandoverCodeHash(
  candidateCode: string,
  salt: string,
  expectedHashHex: string,
): boolean {
  if (!candidateCode || !salt || !expectedHashHex) {
    return false;
  }
  const actualHex = hashHandoverCode(candidateCode, salt);
  const actualBuf = Buffer.from(actualHex, 'hex');
  const expectedBuf = Buffer.from(expectedHashHex, 'hex');
  if (actualBuf.length === 0 || actualBuf.length !== expectedBuf.length) {
    return false;
  }
  return crypto.timingSafeEqual(actualBuf, expectedBuf);
}
