const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json; charset=utf-8',
};

const KV_KEYS = {
  CURRENT_RATE: 'current_rate',
  HISTORY: 'rate_history',
};

// BCV publica tasa 1 vez al día entre 4:00 PM - 6:00 PM VET (UTC-4)
// Ventana de actualización: 4:00 PM - 6:00 PM VET = 20:00 - 22:00 UTC
const BCV_WINDOW_START_UTC = 20; // 4 PM VET
const BCV_WINDOW_END_UTC = 22;   // 6 PM VET
const CACHE_TTL_IN_WINDOW = 900;      // 15 minutos durante ventana BCV
const CACHE_TTL_OUTSIDE_WINDOW = 14400; // 4 horas fuera de ventana (ya tenemos la tasa del día)

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/tasa') {
        return await handleCurrentRate(env);
      }

      if (path === '/tasa/history') {
        const days = parseInt(url.searchParams.get('days') || '30');
        return await handleHistory(env, days);
      }

      if (path === '/health') {
        return jsonResponse({ status: 'ok', timestamp: new Date().toISOString() });
      }

      // ── Alert endpoints ──
      if (path === '/alerts/register' && request.method === 'POST') {
        return await handleAlertRegister(request, env);
      }

      return jsonResponse({ error: 'Ruta no encontrada' }, 404);
    } catch (err) {
      return jsonResponse({ error: 'Error interno del servidor' }, 500);
    }
  },

  async scheduled(event, env) {
    await fetchAndStoreRate(env);
    await checkAndSendAlerts(env);
  },
};

// ── Handlers ───────────────────────────────────────────────

async function handleCurrentRate(env) {
  const cached = await env.TASAVE_KV.get(KV_KEYS.CURRENT_RATE, 'json');

  if (cached) {
    const age = (Date.now() - new Date(cached.timestamp).getTime()) / 1000;
    const ttl = isInBcvWindow() ? CACHE_TTL_IN_WINDOW : CACHE_TTL_OUTSIDE_WINDOW;

    if (age < ttl) {
      return jsonResponse({ ...cached, nextUpdate: getNextUpdateInfo() });
    }
  }

  const fresh = await fetchAndStoreRate(env);
  if (fresh) {
    return jsonResponse({ ...fresh, nextUpdate: getNextUpdateInfo() });
  }

  if (cached) {
    return jsonResponse({ ...cached, nextUpdate: getNextUpdateInfo() });
  }

  return jsonResponse({ error: 'No se pudo obtener la tasa' }, 503);
}

function isInBcvWindow() {
  const now = new Date();
  const hour = now.getUTCHours();
  return hour >= BCV_WINDOW_START_UTC && hour < BCV_WINDOW_END_UTC;
}

function getNextUpdateInfo() {
  const now = new Date();
  const hour = now.getUTCHours();

  if (hour >= BCV_WINDOW_START_UTC && hour < BCV_WINDOW_END_UTC) {
    return { status: 'watching', message: 'Monitoreando BCV (publica entre 4:00-6:00 PM)' };
  } else if (hour >= BCV_WINDOW_END_UTC) {
    return { status: 'done', message: 'Tasa del día actualizada' };
  } else {
    return { status: 'waiting', message: 'BCV publica entre 4:00-6:00 PM hora Venezuela' };
  }
}

async function handleHistory(env, days) {
  const allHistory = await env.TASAVE_KV.get(KV_KEYS.HISTORY, 'json') || [];

  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days);

  const filtered = allHistory
    .filter(entry => new Date(entry.date) >= cutoff)
    .sort((a, b) => new Date(b.date) - new Date(a.date));

  return jsonResponse(filtered);
}

// ── Scraper BCV ────────────────────────────────────────────

async function fetchAndStoreRate(env) {
  try {
    let rates = null;

    // Fuente 1: DolarAPI.com (más confiable desde Cloudflare)
    rates = await fetchFromDolarApi();

    // Fuente 2: Scraping directo BCV (fallback)
    if (!rates) {
      rates = await fetchFromBcvDirect();
    }

    // Fuente 3: API exchangemonitor (segundo fallback)
    if (!rates) {
      rates = await fetchFromExchangeMonitor();
    }

    if (!rates || !rates.bcvUsd || !rates.bcvEur) {
      throw new Error('Ninguna fuente de datos disponible');
    }

    const [usdtP2P, yadioRate, extraRates] = await Promise.all([
      fetchUsdtP2P(),
      fetchYadioRate(),
      fetchExtraRatesFromBcv(),
    ]);

    const rateData = {
      bcvUsd: rates.bcvUsd,
      bcvEur: rates.bcvEur,
      usdtP2P: usdtP2P,
      yadioRate: yadioRate,
      bcvCop: extraRates?.bcvCop || null,
      bcvBrl: extraRates?.bcvBrl || null,
      bcvCny: extraRates?.bcvCny || null,
      bcvTry: extraRates?.bcvTry || null,
      bcvRub: extraRates?.bcvRub || null,
      timestamp: new Date().toISOString(),
    };

    await env.TASAVE_KV.put(KV_KEYS.CURRENT_RATE, JSON.stringify(rateData));

    await appendToHistory(env, rateData);

    return rateData;
  } catch (err) {
    console.error('Error obteniendo tasas:', err.message);
    return null;
  }
}

async function fetchFromDolarApi() {
  try {
    const [usdRes, eurRes] = await Promise.all([
      fetch('https://ve.dolarapi.com/v1/dolares/oficial', {
        headers: { 'Accept': 'application/json' },
      }),
      fetch('https://ve.dolarapi.com/v1/euros/oficial', {
        headers: { 'Accept': 'application/json' },
      }),
    ]);

    if (!usdRes.ok) return null;

    const usdData = await usdRes.json();
    const eurData = eurRes.ok ? await eurRes.json() : null;

    const bcvUsd = usdData?.promedio;
    const bcvEur = eurData?.promedio || null;

    if (!bcvUsd) return null;
    return { bcvUsd: roundTwo(bcvUsd), bcvEur: bcvEur ? roundTwo(bcvEur) : null };
  } catch {
    return null;
  }
}

async function fetchFromBcvDirect() {
  try {
    const response = await fetch('https://www.bcv.org.ve/', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'es-VE,es;q=0.9',
      },
    });
    if (!response.ok) return null;

    const html = await response.text();
    return parseBcvHtml(html);
  } catch {
    return null;
  }
}

async function fetchFromExchangeMonitor() {
  try {
    const response = await fetch('https://exchangemonitor.net/dolar-venezuela-bcv', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html',
      },
    });
    if (!response.ok) return null;

    const html = await response.text();
    const usdMatch = html.match(/BCV[\s\S]*?(\d+[.,]\d{2})/i);
    if (usdMatch) {
      return { bcvUsd: parseVenezuelanNumber(usdMatch[1]), bcvEur: null };
    }
    return null;
  } catch {
    return null;
  }
}

function roundTwo(n) {
  return Math.round(n * 100) / 100;
}

function parseBcvHtml(html) {
  const result = { bcvUsd: null, bcvEur: null };

  // El BCV muestra las tasas en elementos con id "dolar" y "euro"
  // Formato: <strong>XX,XXXXXXXX</strong>
  const usdMatch = html.match(/id="dolar"[^>]*>[\s\S]*?<strong>([\d,]+)/i);
  if (usdMatch) {
    result.bcvUsd = parseVenezuelanNumber(usdMatch[1]);
  }

  const eurMatch = html.match(/id="euro"[^>]*>[\s\S]*?<strong>([\d,]+)/i);
  if (eurMatch) {
    result.bcvEur = parseVenezuelanNumber(eurMatch[1]);
  }

  // Fallback: buscar en div.col-sm-6.col-xs-6 con la clase del dólar
  if (!result.bcvUsd) {
    const altUsdMatch = html.match(/USD[\s\S]*?<strong>([\d,.]+)/i);
    if (altUsdMatch) {
      result.bcvUsd = parseVenezuelanNumber(altUsdMatch[1]);
    }
  }

  if (!result.bcvEur) {
    const altEurMatch = html.match(/EUR[\s\S]*?<strong>([\d,.]+)/i);
    if (altEurMatch) {
      result.bcvEur = parseVenezuelanNumber(altEurMatch[1]);
    }
  }

  return result;
}

function parseVenezuelanNumber(str) {
  // BCV usa formato venezolano: "47,32" o "47,3200000"
  const cleaned = str.trim().replace(/\./g, '').replace(',', '.');
  const num = parseFloat(cleaned);
  return isNaN(num) ? null : Math.round(num * 100) / 100;
}

async function fetchUsdtP2P() {
  try {
    // Binance P2P API para USDT/VES
    const response = await fetch('https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        asset: 'USDT',
        fiat: 'VES',
        merchantCheck: true,
        page: 1,
        rows: 5,
        tradeType: 'SELL',
        payTypes: [],
      }),
    });

    if (!response.ok) return null;

    const data = await response.json();
    const ads = data?.data || [];
    if (ads.length === 0) return null;

    // Promedio de los primeros 5 anuncios
    const prices = ads.map(ad => parseFloat(ad.adv.price));
    const avg = prices.reduce((a, b) => a + b, 0) / prices.length;
    return Math.round(avg * 100) / 100;
  } catch {
    return null;
  }
}

async function fetchExtraRatesFromBcv() {
  try {
    // DolarAPI provee tasas BCV para múltiples monedas
    const currencies = ['cop', 'brl', 'cny', 'try', 'rub'];
    const results = await Promise.allSettled(
      currencies.map(c =>
        fetch(`https://ve.dolarapi.com/v1/dolares/${c}`, {
          headers: { 'Accept': 'application/json' },
        }).then(r => r.ok ? r.json() : null).catch(() => null)
      )
    );

    const [cop, brl, cny, tryRate, rub] = results.map(r =>
      r.status === 'fulfilled' && r.value?.promedio
        ? roundTwo(r.value.promedio)
        : null
    );

    return { bcvCop: cop, bcvBrl: brl, bcvCny: cny, bcvTry: tryRate, bcvRub: rub };
  } catch {
    return null;
  }
}

async function fetchYadioRate() {
  try {
    const response = await fetch('https://yadio.io/exrates/VES', {
      headers: { 'Accept': 'application/json' },
    });
    if (!response.ok) return null;
    const data = await response.json();
    // Yadio returns { VES: { USD: rate } } or { USD: rate }
    const rate = data?.VES?.USD || data?.USD;
    if (rate && rate > 0) {
      return Math.round((1 / rate) * 100) / 100; // Convert to VES per 1 USD
    }
    // Alternative: direct VES value
    if (data?.VES && typeof data.VES === 'number') {
      return Math.round(data.VES * 100) / 100;
    }
    return null;
  } catch {
    return null;
  }
}

// ── Alert System ─────────────────────────────────────────

async function handleAlertRegister(request, env) {
  try {
    const body = await request.json();
    const { token, alerts } = body;

    if (!token || !alerts) {
      return jsonResponse({ error: 'token y alerts son requeridos' }, 400);
    }

    // Store device alert preferences in KV
    // Key: alert_device_{token_hash} → { token, alerts, updatedAt }
    const tokenHash = await hashToken(token);
    const deviceData = {
      token,
      alerts,
      updatedAt: new Date().toISOString(),
    };

    await env.TASAVE_KV.put(
      `alert_device_${tokenHash}`,
      JSON.stringify(deviceData),
      { expirationTtl: 60 * 60 * 24 * 90 } // 90 days TTL
    );

    // Add token hash to the device index for cron iteration
    const deviceIndex = await env.TASAVE_KV.get('alert_device_index', 'json') || [];
    if (!deviceIndex.includes(tokenHash)) {
      deviceIndex.push(tokenHash);
      await env.TASAVE_KV.put('alert_device_index', JSON.stringify(deviceIndex));
    }

    return jsonResponse({ status: 'registered', deviceHash: tokenHash });
  } catch (err) {
    return jsonResponse({ error: 'Error registrando alerta' }, 500);
  }
}

async function checkAndSendAlerts(env) {
  try {
    const currentRate = await env.TASAVE_KV.get(KV_KEYS.CURRENT_RATE, 'json');
    if (!currentRate) return;

    const deviceIndex = await env.TASAVE_KV.get('alert_device_index', 'json') || [];
    if (deviceIndex.length === 0) return;

    const fcmKey = env.FCM_SERVER_KEY;
    if (!fcmKey) {
      console.error('FCM_SERVER_KEY not configured');
      return;
    }

    const bcvUsd = currentRate.bcvUsd;
    const usdtP2P = currentRate.usdtP2P;
    const spreadPercent = usdtP2P && bcvUsd > 0
      ? ((usdtP2P - bcvUsd) / bcvUsd * 100)
      : 0;

    for (const tokenHash of deviceIndex) {
      const deviceData = await env.TASAVE_KV.get(`alert_device_${tokenHash}`, 'json');
      if (!deviceData) continue;

      const { token, alerts } = deviceData;
      const messages = [];

      for (const alert of alerts) {
        if (!alert.enabled) continue;

        switch (alert.type) {
          case 'bcv_above':
            if (alert.threshold > 0 && bcvUsd >= alert.threshold) {
              messages.push(`BCV alcanzó ${bcvUsd.toFixed(2)} Bs/$ (umbral: ${alert.threshold.toFixed(2)})`);
            }
            break;
          case 'spread_above':
            if (Math.abs(spreadPercent) >= alert.threshold) {
              messages.push(`Spread en ${spreadPercent.toFixed(1)}% (umbral: ${alert.threshold.toFixed(1)}%)`);
            }
            break;
          case 'ritmo_inusual':
            // Compare with previous rate for rapid change detection
            const history = await env.TASAVE_KV.get(KV_KEYS.HISTORY, 'json') || [];
            if (history.length >= 2) {
              const prev = history[1]?.bcvUsd || history[0]?.bcvUsd;
              const changePercent = prev > 0 ? Math.abs((bcvUsd - prev) / prev * 100) : 0;
              if (changePercent >= alert.threshold) {
                messages.push(`Cambio rápido: ${changePercent.toFixed(1)}% en el último periodo`);
              }
            }
            break;
        }
      }

      // Send push notification if any alert triggered
      if (messages.length > 0) {
        await sendFcmNotification(fcmKey, token, {
          title: 'TasaVe - Alerta',
          body: messages.join(' · '),
          data: { bcvUsd: String(bcvUsd), spread: String(spreadPercent.toFixed(1)) },
        });
      }
    }
  } catch (err) {
    console.error('Error checking alerts:', err.message);
  }
}

async function sendFcmNotification(serverKey, token, notification) {
  try {
    await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${serverKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title: notification.title,
          body: notification.body,
          icon: '/icons/Icon-192.png',
        },
        data: notification.data || {},
      }),
    });
  } catch (err) {
    console.error('FCM send error:', err.message);
  }
}

async function hashToken(token) {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hash = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hash));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('').substring(0, 16);
}

// ── History ──────────────────────────────────────────────

async function appendToHistory(env, rateData) {
  const history = await env.TASAVE_KV.get(KV_KEYS.HISTORY, 'json') || [];
  const today = new Date().toISOString().split('T')[0];

  // Calcular variación respecto al día anterior
  const lastEntry = history[0];
  const variation = lastEntry ? Math.round((rateData.bcvUsd - lastEntry.bcvUsd) * 100) / 100 : 0;

  // Si ya hay entrada de hoy, actualizarla
  const todayIndex = history.findIndex(e => e.date.startsWith(today));
  const entry = {
    date: new Date().toISOString(),
    bcvUsd: rateData.bcvUsd,
    bcvEur: rateData.bcvEur,
    variation: variation,
  };

  if (todayIndex >= 0) {
    history[todayIndex] = entry;
  } else {
    history.unshift(entry);
  }

  // Mantener máximo 90 días
  const trimmed = history.slice(0, 90);
  await env.TASAVE_KV.put(KV_KEYS.HISTORY, JSON.stringify(trimmed));
}

// ── Utils ──────────────────────────────────────────────────

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: CORS_HEADERS,
  });
}
