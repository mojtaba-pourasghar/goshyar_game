/**
 * Goshyar asset gateway: serves the game's images and audio from a private R2 bucket.
 *
 * Paths are versioned (/goshyar/v1/...), so every file is immutable and can be cached
 * for a year at the edge and on the device. Only packs.json (the pack index) is short-lived.
 * The bucket stays private; this Worker is the only public way in, and it only allows GET/HEAD.
 */

const ALLOWED_PREFIX = 'goshyar/';
const TYPES = {
  mp3: 'audio/mpeg',
  m4a: 'audio/mp4',
  ogg: 'audio/ogg',
  webp: 'image/webp',
  png: 'image/png',
  jpg: 'image/jpeg',
  json: 'application/json; charset=utf-8',
};

function corsHeaders(env) {
  return {
    'Access-Control-Allow-Origin': env.ALLOWED_ORIGIN || '*',
    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    'Access-Control-Max-Age': '86400',
  };
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(env) });
    }
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', { status: 405, headers: { Allow: 'GET, HEAD, OPTIONS' } });
    }

    const url = new URL(request.url);
    const key = decodeURIComponent(url.pathname.replace(/^\/+/, ''));
    if (!key.startsWith(ALLOWED_PREFIX) || key.includes('..')) {
      return new Response('Not Found', { status: 404 });
    }

    const cache = caches.default;
    const cached = await cache.match(request);
    if (cached) return cached;

    const object = await env.ASSETS.get(key, { range: request.headers, onlyIf: request.headers });
    if (object === null) return new Response('Not Found', { status: 404, headers: corsHeaders(env) });

    const ext = key.split('.').pop().toLowerCase();
    const headers = new Headers(corsHeaders(env));
    object.writeHttpMetadata(headers);
    headers.set('Content-Type', TYPES[ext] || 'application/octet-stream');
    headers.set('ETag', object.httpEtag);
    headers.set(
      'Cache-Control',
      key.endsWith('/packs.json') ? 'public, max-age=300' : 'public, max-age=31536000, immutable',
    );
    headers.set('X-Content-Type-Options', 'nosniff');

    if (!('body' in object) || !object.body) {
      return new Response(null, { status: 304, headers });
    }
    // R2 fills object.range even for whole-object reads; only answer 206 when a Range was asked for.
    const partial = request.headers.has('Range') && object.range && 'offset' in object.range;
    if (partial) {
      const start = object.range.offset;
      const end = start + object.range.length - 1;
      headers.set('Content-Range', `bytes ${start}-${end}/${object.size}`);
    }
    headers.set('Accept-Ranges', 'bytes');
    const status = partial ? 206 : 200;
    const response = new Response(request.method === 'HEAD' ? null : object.body, { status, headers });
    if (status === 200 && request.method === 'GET') ctx.waitUntil(cache.put(request, response.clone()));
    return response;
  },
};
