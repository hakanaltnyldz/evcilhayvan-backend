import crypto from 'crypto';

const ALGO = 'aes-256-cbc';

function getKey() {
  const hex = process.env.FIELD_ENCRYPT_KEY;
  if (!hex || hex.length !== 64) {
    throw new Error('FIELD_ENCRYPT_KEY env değişkeni eksik veya hatalı (64 hex karakter gerekli)');
  }
  return Buffer.from(hex, 'hex');
}

/**
 * Metni AES-256-CBC ile şifreler.
 * Döndürür: "ivHex:encryptedHex"
 */
export function encrypt(text) {
  if (!text) return null;
  const key = getKey();
  const iv  = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGO, key, iv);
  const encrypted = cipher.update(String(text), 'utf8', 'hex') + cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

/**
 * "ivHex:encryptedHex" formatındaki şifreli metni çözer.
 */
export function decrypt(data) {
  if (!data) return null;
  const [ivHex, encHex] = data.split(':');
  if (!ivHex || !encHex) return null;
  const key = getKey();
  const decipher = crypto.createDecipheriv(ALGO, key, Buffer.from(ivHex, 'hex'));
  return decipher.update(encHex, 'hex', 'utf8') + decipher.final('utf8');
}

/**
 * Şifreli TC'yi maskeli gösterir: "123*****456"
 */
export function maskNationalId(encrypted) {
  if (!encrypted) return null;
  try {
    const plain = decrypt(encrypted);
    if (!plain || plain.length < 6) return '***';
    return plain.slice(0, 3) + '*****' + plain.slice(-3);
  } catch {
    return '***';
  }
}
