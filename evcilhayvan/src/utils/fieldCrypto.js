import crypto from 'crypto';

const ALGO = 'aes-256-cbc';

// Startup warning — key eksikse uyar ama crash etme
(function validateFieldEncryptKey() {
  const hex = process.env.FIELD_ENCRYPT_KEY;
  if (!hex) {
    console.warn(
      '[fieldCrypto] FIELD_ENCRYPT_KEY ortam değişkeni tanımlanmamış. ' +
      'Şifreleme devre dışı. Key eklemek için: ' +
      'node -e "console.log(require(\'crypto\').randomBytes(32).toString(\'hex\'))"'
    );
  } else if (hex.length !== 64) {
    console.warn(
      `[fieldCrypto] FIELD_ENCRYPT_KEY geçersiz uzunluk: ${hex.length} karakter (64 gerekli). Şifreleme devre dışı.`
    );
  }
})();

function getKey() {
  const hex = process.env.FIELD_ENCRYPT_KEY;
  if (!hex || hex.length !== 64) return null;
  return Buffer.from(hex, 'hex');
}

/**
 * Metni AES-256-CBC ile şifreler.
 * Key yoksa plain text döner.
 * Döndürür: "ivHex:encryptedHex" veya plain text
 */
export function encrypt(text) {
  if (!text) return null;
  const key = getKey();
  if (!key) return String(text); // key yoksa plain text
  const iv  = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGO, key, iv);
  const encrypted = cipher.update(String(text), 'utf8', 'hex') + cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

/**
 * "ivHex:encryptedHex" formatındaki şifreli metni çözer.
 * Key yoksa ya da format uyuşmazsa input'u döner.
 */
export function decrypt(data) {
  if (!data) return null;
  const key = getKey();
  if (!key) return data; // key yoksa plain text olarak dön
  const [ivHex, encHex] = data.split(':');
  if (!ivHex || !encHex) return data; // şifreli değilse plain text
  try {
    const decipher = crypto.createDecipheriv(ALGO, key, Buffer.from(ivHex, 'hex'));
    return decipher.update(encHex, 'hex', 'utf8') + decipher.final('utf8');
  } catch {
    return data;
  }
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
