const crypto = require('crypto');

const PREFIX = 'enc:';

function getKey() {
    const hex = process.env.ENCRYPTION_KEY;
    if (!hex || !/^[0-9a-fA-F]{64}$/.test(hex)) {
        throw new Error('ENCRYPTION_KEY must be 64 hex characters');
    }
    return Buffer.from(hex, 'hex');
}

/** AES-256-GCM. Output format: "enc:" + base64(iv[12] + authTag[16] + ciphertext) */
function encrypt(plain) {
    if (plain == null || plain === '') return plain;
    const text = String(plain);
    if (text.startsWith(PREFIX)) return text;
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', getKey(), iv);
    const data = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return PREFIX + Buffer.concat([iv, tag, data]).toString('base64');
}

function decrypt(stored) {
    if (stored == null || stored === '') return stored;
    const text = String(stored);
    // Rows saved before encryption was added are plain text; return them as is.
    if (!text.startsWith(PREFIX)) return text;
    const raw = Buffer.from(text.slice(PREFIX.length), 'base64');
    const iv = raw.subarray(0, 12);
    const tag = raw.subarray(12, 28);
    const data = raw.subarray(28);
    const decipher = crypto.createDecipheriv('aes-256-gcm', getKey(), iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(data), decipher.final()]).toString('utf8');
}

module.exports = { encrypt, decrypt };