import { sendWebPush } from './web-push.js';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
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

      // ── Web Push endpoints ──
      if (path === '/push/vapid-key') {
        return jsonResponse({ publicKey: env.VAPID_PUBLIC_KEY });
      }

      if (path === '/push/subscribe' && request.method === 'POST') {
        return await handlePushSubscribe(request, env);
      }

      if (path === '/push/unsubscribe' && request.method === 'POST') {
        return await handlePushUnsubscribe(request, env);
      }

      return jsonResponse({ error: 'Ruta no encontrada' }, 404);
    } catch (err) {
      return jsonResponse({ error: 'Error interno del servidor' }, 500);
    }
  },

  async scheduled(event, env) {
    await fetchAndStoreRate(env);
    await checkAndSendAlerts(env);
    await sendSmartNotifications(env);
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

    // Sin índice central: se itera usando TASAVE_KV.list({ prefix: 'alert_device_' }) en el cron

    return jsonResponse({ status: 'registered', deviceHash: tokenHash });
  } catch (err) {
    return jsonResponse({ error: 'Error registrando alerta' }, 500);
  }
}

async function checkAndSendAlerts(env) {
  try {
    const currentRate = await env.TASAVE_KV.get(KV_KEYS.CURRENT_RATE, 'json');
    if (!currentRate) return;

    const bcvUsd = currentRate.bcvUsd;
    const usdtP2P = currentRate.usdtP2P;
    const spreadPercent = usdtP2P && bcvUsd > 0
      ? ((usdtP2P - bcvUsd) / bcvUsd * 100)
      : 0;

    // Iterar sobre todos los dispositivos usando prefijo (sin índice central)
    let cursor = undefined;
    let hasMore = true;

    while (hasMore) {
      const listed = await env.TASAVE_KV.list({ prefix: 'alert_device_', cursor, limit: 100 });
      hasMore = !listed.list_complete;
      cursor = listed.cursor;

      for (const key of listed.keys) {
        const deviceData = await env.TASAVE_KV.get(key.name, 'json');
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
            // p2p_above y spread_above son equivalentes: comparan la brecha % P2P vs BCV
            case 'p2p_above':
            case 'spread_above':
              if (Math.abs(spreadPercent) >= alert.threshold) {
                messages.push(`Diferencia P2P en ${spreadPercent.toFixed(1)}% (umbral: ${alert.threshold.toFixed(1)}%)`);
              }
              break;
            case 'ritmo_inusual': {
              // Comparar con la tasa del día anterior para detectar cambios rápidos
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
        }

        // Enviar notificación push si alguna alerta fue disparada
        if (messages.length > 0) {
          // Intentar Web Push (suscripción web) primero, FCM legacy como fallback
          if (deviceData.subscription) {
            const result = await sendWebPush(env, deviceData.subscription, {
              title: 'TasaVe - Alerta',
              body: messages.join(' · '),
              data: { bcvUsd: String(bcvUsd), spread: String(spreadPercent.toFixed(1)) },
            });
            if (result.expired) {
              await env.TASAVE_KV.delete(key.name);
            }
          }
        }
      }
    }
  } catch (err) {
    console.error('Error checking alerts:', err.message);
  }
}

// ── Web Push subscription handlers ───────────────────────────────────────────

async function handlePushSubscribe(request, env) {
  try {
    const body = await request.json();
    const { subscription, alerts } = body;

    if (!subscription || !subscription.endpoint || !subscription.keys) {
      return jsonResponse({ error: 'subscription es requerido con endpoint y keys' }, 400);
    }

    const subHash = await hashToken(subscription.endpoint);
    const deviceData = {
      subscription,
      alerts: alerts || [{ type: 'daily_rate', enabled: true }],
      updatedAt: new Date().toISOString(),
    };

    await env.TASAVE_KV.put(
      `alert_device_${subHash}`,
      JSON.stringify(deviceData),
      { expirationTtl: 60 * 60 * 24 * 90 }
    );

    return jsonResponse({ status: 'subscribed', id: subHash });
  } catch (err) {
    return jsonResponse({ error: 'Error registrando suscripción push' }, 500);
  }
}

async function handlePushUnsubscribe(request, env) {
  try {
    const body = await request.json();
    const { endpoint } = body;
    if (!endpoint) return jsonResponse({ error: 'endpoint requerido' }, 400);

    const subHash = await hashToken(endpoint);
    await env.TASAVE_KV.delete(`alert_device_${subHash}`);
    return jsonResponse({ status: 'unsubscribed' });
  } catch (err) {
    return jsonResponse({ error: 'Error eliminando suscripción' }, 500);
  }
}

// ── Sistema de notificaciones push ───────────────────────────────────────────
// Límite Cloudflare Free: 50 subrequests por invocación de cron.
// Enviamos en lotes de MAX_BATCH para no superarlo (cada push = 1 subrequest).
const MAX_BATCH = 40;

/**
 * Envía una notificación a todos los suscriptores que tengan habilitado `alertType`.
 * Respeta MAX_BATCH para no superar el límite de subrequests del plan free.
 */
async function broadcastNotification(env, alertType, payload) {
  let cursor = undefined;
  let hasMore = true;
  let sent = 0;
  let batch = 0;

  while (hasMore && batch < MAX_BATCH) {
    const listed = await env.TASAVE_KV.list({ prefix: 'alert_device_', cursor, limit: 50 });
    hasMore = !listed.list_complete;
    cursor = listed.cursor;

    for (const key of listed.keys) {
      if (batch >= MAX_BATCH) break;
      const deviceData = await env.TASAVE_KV.get(key.name, 'json');
      if (!deviceData?.subscription) continue;

      // Respetar preferencia del usuario — si el tipo está explícitamente desactivado, saltar
      const pref = deviceData.alerts?.find(a => a.type === alertType);
      if (pref && pref.enabled === false) continue;

      const result = await sendWebPush(env, deviceData.subscription, payload);
      batch++;
      if (result.expired) {
        await env.TASAVE_KV.delete(key.name);
      } else if (result.success) {
        sent++;
      }
    }
  }

  console.log(`[push:${alertType}] enviadas: ${sent}`);
  return sent;
}

/**
 * Construye y despacha todas las notificaciones según el contexto actual.
 * Se llama desde scheduled() después de fetchAndStoreRate().
 */
async function sendSmartNotifications(env) {
  const currentRate = await env.TASAVE_KV.get(KV_KEYS.CURRENT_RATE, 'json');
  if (!currentRate) return;

  const history = await env.TASAVE_KV.get(KV_KEYS.HISTORY, 'json') || [];
  const now = new Date();
  const utcHour = now.getUTCHours();
  const utcDay = now.getUTCDay(); // 0=Dom, 1=Lun

  // ── Calcular métricas ──────────────────────────────────────────────────────
  const bcvUsd = currentRate.bcvUsd;
  const p2p = currentRate.usdtP2P;
  const eur = currentRate.bcvEur || 0;
  const yesterday = history[1]; // history[0] es hoy, history[1] es ayer
  const variation = yesterday ? ((bcvUsd - yesterday.bcvUsd) / yesterday.bcvUsd * 100) : 0;
  const spread = p2p && bcvUsd ? ((p2p - bcvUsd) / bcvUsd * 100) : 0;
  const allTimeHigh = history.length > 0 ? Math.max(...history.map(e => e.bcvUsd)) : 0;
  const variationStr = (variation >= 0 ? '+' : '') + variation.toFixed(2) + '%';

  // ── 1. TASA DIARIA — enviar solo en ventana BCV (20-22 UTC) ───────────────
  if (utcHour >= BCV_WINDOW_END_UTC && utcHour < BCV_WINDOW_END_UTC + 2) {
    // Solo si la tasa es de hoy (no caché antigua)
    const today = now.toISOString().split('T')[0];
    const rateIsToday = currentRate.timestamp?.startsWith(today);

    if (rateIsToday) {
      const trendIcon = variation > 0 ? '📈' : variation < 0 ? '📉' : '➡️';
      await broadcastNotification(env, 'daily_rate', {
        title: `${trendIcon} BCV hoy: ${bcvUsd.toFixed(2)} Bs/$`,
        body: p2p
          ? `P2P: ${p2p.toFixed(2)} Bs · Spread ${spread.toFixed(1)}% · Variación ${variationStr}`
          : `Variación: ${variationStr} · EUR: ${eur.toFixed(2)} Bs/€`,
        icon: '/icons/Icon-192.png',
        data: { url: '/', type: 'daily_rate' },
      });
    }
  }

  // ── 2. CAMBIO GRANDE — variación ≥ 1% respecto a ayer ────────────────────
  if (Math.abs(variation) >= 1.0) {
    const alreadySent = await env.TASAVE_KV.get(`notif_big_change_${now.toISOString().split('T')[0]}`);
    if (!alreadySent) {
      const dir = variation > 0 ? 'subió' : 'bajó';
      const icon = variation > 0 ? '🚨' : '⚠️';
      await broadcastNotification(env, 'rate_change_big', {
        title: `${icon} La tasa ${dir} ${Math.abs(variation).toFixed(1)}%`,
        body: `BCV: ${bcvUsd.toFixed(2)} Bs/$ · ${variationStr} vs ayer · Toca para calcular`,
        icon: '/icons/Icon-192.png',
        data: { url: '/', type: 'rate_change_big' },
      });
      // Marcar como enviada hoy para no repetir
      await env.TASAVE_KV.put(`notif_big_change_${now.toISOString().split('T')[0]}`, '1', { expirationTtl: 86400 });
    }
  }

  // ── 3. SPREAD ALTO — P2P supera BCV + 5% ─────────────────────────────────
  if (spread >= 5.0) {
    const alreadySent = await env.TASAVE_KV.get(`notif_spread_${now.toISOString().split('T')[0]}`);
    if (!alreadySent) {
      await broadcastNotification(env, 'spread_alert', {
        title: `🔔 Spread P2P/BCV alto: ${spread.toFixed(1)}%`,
        body: `BCV: ${bcvUsd.toFixed(2)} · P2P: ${p2p.toFixed(2)} Bs · Brecha inusual en el mercado`,
        icon: '/icons/Icon-192.png',
        data: { url: '/', type: 'spread_alert' },
      });
      await env.TASAVE_KV.put(`notif_spread_${now.toISOString().split('T')[0]}`, '1', { expirationTtl: 86400 });
    }
  }

  // ── 4. MÁXIMO HISTÓRICO ────────────────────────────────────────────────────
  if (bcvUsd > allTimeHigh && allTimeHigh > 0) {
    const alreadySent = await env.TASAVE_KV.get(`notif_ath_${now.toISOString().split('T')[0]}`);
    if (!alreadySent) {
      await broadcastNotification(env, 'rate_new_high', {
        title: `🏆 Nuevo máximo histórico: ${bcvUsd.toFixed(2)} Bs/$`,
        body: `La tasa BCV supera el récord anterior de ${allTimeHigh.toFixed(2)} Bs/$`,
        icon: '/icons/Icon-192.png',
        data: { url: '/history', type: 'rate_new_high' },
      });
      await env.TASAVE_KV.put(`notif_ath_${now.toISOString().split('T')[0]}`, '1', { expirationTtl: 86400 });
    }
  }

  // ── 5. BCV NO PUBLICÓ — si son las 7PM VET (23 UTC) sin tasa de hoy ───────
  if (utcHour === 23) {
    const today = now.toISOString().split('T')[0];
    const rateIsToday = currentRate.timestamp?.startsWith(today);
    const alreadySent = await env.TASAVE_KV.get(`notif_no_rate_${today}`);
    if (!rateIsToday && !alreadySent) {
      await broadcastNotification(env, 'bcv_closed', {
        title: `ℹ️ BCV no publicó tasa hoy`,
        body: `Usando la tasa del día anterior: ${bcvUsd.toFixed(2)} Bs/$. Actualizamos en cuanto esté disponible.`,
        icon: '/icons/Icon-192.png',
        data: { url: '/', type: 'bcv_closed' },
      });
      await env.TASAVE_KV.put(`notif_no_rate_${today}`, '1', { expirationTtl: 86400 });
    }
  }

  // ── 6. RESUMEN SEMANAL — lunes 12 UTC (8 AM VET) ─────────────────────────
  if (utcDay === 1 && utcHour === 12) {
    const alreadySent = await env.TASAVE_KV.get(`notif_weekly_${now.toISOString().split('T')[0]}`);
    if (!alreadySent && history.length >= 7) {
      const week = history.slice(0, 7);
      const weekMin = Math.min(...week.map(e => e.bcvUsd));
      const weekMax = Math.max(...week.map(e => e.bcvUsd));
      const weekStart = week[week.length - 1].bcvUsd;
      const weekChange = ((bcvUsd - weekStart) / weekStart * 100);
      const weekChangeStr = (weekChange >= 0 ? '+' : '') + weekChange.toFixed(2) + '%';

      await broadcastNotification(env, 'weekly_summary', {
        title: `📊 Resumen semanal — ${weekChangeStr}`,
        body: `BCV esta semana: mín ${weekMin.toFixed(2)} · máx ${weekMax.toFixed(2)} · hoy ${bcvUsd.toFixed(2)} Bs/$`,
        icon: '/icons/Icon-192.png',
        data: { url: '/history', type: 'weekly_summary' },
      });
      await env.TASAVE_KV.put(`notif_weekly_${now.toISOString().split('T')[0]}`, '1', { expirationTtl: 86400 });
    }
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
  const variationPct = (lastEntry && lastEntry.bcvUsd > 0)
    ? Math.round((variation / lastEntry.bcvUsd) * 10000) / 100  // 2 decimales
    : 0;

  // Si ya hay entrada de hoy, actualizarla
  const todayIndex = history.findIndex(e => e.date.startsWith(today));
  const entry = {
    date: new Date().toISOString(),
    bcvUsd: rateData.bcvUsd,
    bcvEur: rateData.bcvEur,
    variation: variation,
    variationPct: variationPct,
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
