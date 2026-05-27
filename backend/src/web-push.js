/**
 * Web Push protocol for Cloudflare Workers
 * Implements VAPID auth (RFC 8292) + payload encryption (RFC 8291)
 * Uses only Web Crypto API — zero Node.js dependencies.
 *
 * Required env secrets:
 *   VAPID_PUBLIC_KEY  — base64url-encoded ECDSA P-256 public key (65 bytes uncompressed)
 *   VAPID_PRIVATE_KEY — base64url-encoded ECDSA P-256 private key (32 bytes raw)
 *   VAPID_SUBJECT     — mailto:you@example.com or https://your-app.com
 */

// ── Base64url helpers ──────────────────────────────────────

function b64urlEncode(buffer) {
  const bytes = buffer instanceof Uint8Array ? buffer : new Uint8Array(buffer);
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function b64urlDecode(str) {
  const padded = str.replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

// ── VAPID JWT ──────────────────────────────────────────────

async function createVapidJwt(audience, subject, privateKeyB64) {
  const now = Math.floor(Date.now() / 1000);
  const header = { typ: 'JWT', alg: 'ES256' };
  const payload = { aud: audience, exp: now + 86400, sub: subject };

  const headerB64 = b64urlEncode(new TextEncoder().encode(JSON.stringify(header)));
  const payloadB64 = b64urlEncode(new TextEncoder().encode(JSON.stringify(payload)));
  const unsigned = `${headerB64}.${payloadB64}`;

  const rawKey = b64urlDecode(privateKeyB64);
  const privateKey = await crypto.subtle.importKey(
    'jwk',
    { kty: 'EC', crv: 'P-256', d: b64urlEncode(rawKey), x: '', y: '' },
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign'],
  ).catch(() => {
    // Fallback: import as PKCS8 if JWK fails
    return importEcdsaPrivateKey(rawKey);
  });

  const sig = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    privateKey,
    new TextEncoder().encode(unsigned),
  );

  // Convert DER signature to raw r||s (64 bytes)
  const rawSig = derToRaw(new Uint8Array(sig));
  return `${unsigned}.${b64urlEncode(rawSig)}`;
}

async function importEcdsaPrivateKey(rawD) {
  // We need to construct a proper JWK with x,y coordinates
  // Generate a temporary key pair to get the format right, then re-import
  // This is a workaround — in production, store full JWK
  const keyPair = await crypto.subtle.generateKey(
    { name: 'ECDSA', namedCurve: 'P-256' },
    true,
    ['sign'],
  );
  const jwk = await crypto.subtle.exportKey('jwk', keyPair.privateKey);
  jwk.d = b64urlEncode(rawD);
  return crypto.subtle.importKey('jwk', jwk, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
}

function derToRaw(der) {
  // If already 64 bytes, it's raw format
  if (der.length === 64) return der;
  // Parse DER SEQUENCE → two INTEGERs
  const raw = new Uint8Array(64);
  let offset = 2; // skip SEQUENCE tag + length
  if (der[offset] === 0x02) {
    const rLen = der[offset + 1];
    const rStart = offset + 2 + (rLen > 32 ? rLen - 32 : 0);
    const rDst = 32 - Math.min(rLen, 32);
    raw.set(der.subarray(rStart, rStart + Math.min(rLen, 32)), rDst);
    offset += 2 + rLen;
  }
  if (der[offset] === 0x02) {
    const sLen = der[offset + 1];
    const sStart = offset + 2 + (sLen > 32 ? sLen - 32 : 0);
    const sDst = 32 + 32 - Math.min(sLen, 32);
    raw.set(der.subarray(sStart, sStart + Math.min(sLen, 32)), sDst);
  }
  return raw;
}

// ── Payload encryption (RFC 8291 — aes128gcm) ─────────────

async function encryptPayload(payload, subscriptionKeys) {
  const clientPublicKey = b64urlDecode(subscriptionKeys.p256dh);
  const clientAuth = b64urlDecode(subscriptionKeys.auth);

  // Generate ephemeral ECDH key pair
  const serverKeys = await crypto.subtle.generateKey(
    { name: 'ECDH', namedCurve: 'P-256' },
    true,
    ['deriveBits'],
  );

  const serverPublicRaw = new Uint8Array(
    await crypto.subtle.exportKey('raw', serverKeys.publicKey),
  );

  // Import client public key
  const clientKey = await crypto.subtle.importKey(
    'raw',
    clientPublicKey,
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    [],
  );

  // Derive shared secret
  const sharedSecret = new Uint8Array(
    await crypto.subtle.deriveBits(
      { name: 'ECDH', public: clientKey },
      serverKeys.privateKey,
      256,
    ),
  );

  // HKDF to derive encryption key material
  const encoder = new TextEncoder();

  // IKM = HKDF(auth, sharedSecret, "WebPush: info\0" || clientPublic || serverPublic)
  const authInfo = new Uint8Array([
    ...encoder.encode('WebPush: info\0'),
    ...clientPublicKey,
    ...serverPublicRaw,
  ]);
  const prk = await hkdfExtract(clientAuth, sharedSecret);
  const ikm = await hkdfExpand(prk, authInfo, 32);

  // salt (random 16 bytes)
  const salt = crypto.getRandomValues(new Uint8Array(16));

  // Derive content encryption key and nonce
  const prkContent = await hkdfExtract(salt, ikm);
  const contentKey = await hkdfExpand(prkContent, encoder.encode('Content-Encoding: aes128gcm\0'), 16);
  const nonce = await hkdfExpand(prkContent, encoder.encode('Content-Encoding: nonce\0'), 12);

  // Pad and encrypt payload
  const payloadBytes = encoder.encode(JSON.stringify(payload));
  const padded = new Uint8Array(payloadBytes.length + 2);
  padded.set(payloadBytes);
  padded[payloadBytes.length] = 2; // delimiter
  // remaining bytes are zero (padding)

  const aesKey = await crypto.subtle.importKey('raw', contentKey, 'AES-GCM', false, ['encrypt']);
  const encrypted = new Uint8Array(
    await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, aesKey, padded),
  );

  // Build aes128gcm header: salt(16) || rs(4) || idlen(1) || keyid(65) || ciphertext
  const rs = 4096;
  const header = new Uint8Array(16 + 4 + 1 + serverPublicRaw.length + encrypted.length);
  header.set(salt, 0);
  new DataView(header.buffer).setUint32(16, rs);
  header[20] = serverPublicRaw.length;
  header.set(serverPublicRaw, 21);
  header.set(encrypted, 21 + serverPublicRaw.length);

  return header;
}

async function hkdfExtract(salt, ikm) {
  const key = await crypto.subtle.importKey('raw', salt, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return new Uint8Array(await crypto.subtle.sign('HMAC', key, ikm));
}

async function hkdfExpand(prk, info, length) {
  const key = await crypto.subtle.importKey('raw', prk, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const infoWithCounter = new Uint8Array(info.length + 1);
  infoWithCounter.set(info);
  infoWithCounter[info.length] = 1;
  const result = new Uint8Array(await crypto.subtle.sign('HMAC', key, infoWithCounter));
  return result.subarray(0, length);
}

// ── Send Push Notification ─────────────────────────────────

export async function sendWebPush(env, subscription, payload) {
  const endpoint = subscription.endpoint;
  const url = new URL(endpoint);
  const audience = `${url.protocol}//${url.host}`;

  const jwt = await createVapidJwt(audience, env.VAPID_SUBJECT, env.VAPID_PRIVATE_KEY);
  const vapidPublicKey = env.VAPID_PUBLIC_KEY;

  const body = await encryptPayload(payload, subscription.keys);

  const res = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Authorization': `vapid t=${jwt}, k=${vapidPublicKey}`,
      'Content-Encoding': 'aes128gcm',
      'Content-Type': 'application/octet-stream',
      'TTL': '86400',
      'Urgency': 'normal',
    },
    body: body,
  });

  if (res.status === 410 || res.status === 404) {
    // Subscription expired or invalid — should be removed
    return { success: false, expired: true, status: res.status };
  }

  if (!res.ok) {
    const err = await res.text();
    console.error(`Push failed (${res.status}): ${err}`);
    return { success: false, expired: false, status: res.status };
  }

  return { success: true, status: res.status };
}

export { b64urlDecode, b64urlEncode };
