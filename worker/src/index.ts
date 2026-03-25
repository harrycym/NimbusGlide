export interface Env {
  GROQ_API_KEY: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
}

// Cache JWKS keys in memory (persists across requests on same isolate)
let cachedJWKS: Record<string, CryptoKey> = {};
let jwksFetchedAt = 0;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, content-type",
        },
      });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // Public demo endpoint — no auth, IP rate-limited
    if (path === "/demo") {
      return await handleDemo(request, env);
    }

    try {
      const authHeader = request.headers.get("Authorization");
      if (!authHeader?.startsWith("Bearer ")) {
        return jsonResponse({ error: "Missing authorization" }, 401);
      }
      const token = authHeader.slice(7);

      const payload = await verifyJWT(token, env.SUPABASE_URL);
      if (!payload) {
        return jsonResponse({ error: "Invalid token" }, 401);
      }
      const userId = payload.sub as string;

      switch (path) {
        case "/transcribe":
          return await handleTranscribe(request, env, userId);
        case "/process":
          return await handleProcess(request, env, userId);
        default:
          return jsonResponse({ error: "Not found" }, 404);
      }
    } catch (err) {
      return jsonResponse({ error: (err as Error).message }, 500);
    }
  },
};

// ============================================================
// USAGE CHECK (fast Supabase REST call)
// ============================================================

async function checkUsageLimit(env: Env, userId: string): Promise<{ allowed: boolean; wordsUsed: number; wordLimit: number | null }> {
  try {
    const resp = await fetch(
      `${env.SUPABASE_URL}/rest/v1/subscriptions?user_id=eq.${userId}&select=words_used,word_limit,plan`,
      {
        headers: {
          apikey: env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );
    const rows = (await resp.json()) as { words_used: number; word_limit: number | null; plan: string }[];
    if (!rows?.[0]) return { allowed: true, wordsUsed: 0, wordLimit: 2000 }; // no subscription = allow (new user)

    const { words_used, word_limit } = rows[0];
    if (word_limit === null) return { allowed: true, wordsUsed: words_used, wordLimit: null }; // pro = unlimited
    return { allowed: words_used < word_limit, wordsUsed: words_used, wordLimit: word_limit };
  } catch {
    return { allowed: true, wordsUsed: 0, wordLimit: 2000 }; // on error, allow (don't block paying users)
  }
}

// ============================================================
// TRANSCRIBE
// ============================================================

async function handleTranscribe(request: Request, env: Env, userId: string): Promise<Response> {
  // Check usage limit before wasting a Groq call
  const usage = await checkUsageLimit(env, userId);
  if (!usage.allowed) {
    return jsonResponse({
      error: "usage_limit_reached",
      words_used: usage.wordsUsed,
      word_limit: usage.wordLimit,
    }, 403);
  }

  const formData = await request.formData();
  const audioFile = formData.get("file");
  if (!audioFile || !(audioFile instanceof File)) {
    return jsonResponse({ error: "No audio file" }, 400);
  }

  const groqForm = new FormData();
  groqForm.append("model", "whisper-large-v3");
  groqForm.append("response_format", "text");
  groqForm.append("file", audioFile, audioFile.name);

  const groqResp = await fetch("https://api.groq.com/openai/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${env.GROQ_API_KEY}` },
    body: groqForm,
  });

  if (!groqResp.ok) {
    const errBody = await groqResp.text();
    return jsonResponse({ error: `Groq error (${groqResp.status}): ${errBody}` }, 502);
  }

  const transcript = (await groqResp.text()).trim();
  return jsonResponse({ transcript });
}

// ============================================================
// PROCESS
// ============================================================

async function handleProcess(request: Request, env: Env, userId: string): Promise<Response> {
  // Check usage limit
  const usage = await checkUsageLimit(env, userId);
  if (!usage.allowed) {
    return jsonResponse({
      error: "usage_limit_reached",
      words_used: usage.wordsUsed,
      word_limit: usage.wordLimit,
    }, 403);
  }

  const body = (await request.json()) as Record<string, unknown>;
  const { model, messages, temperature, max_tokens } = body;

  if (!messages || !Array.isArray(messages)) {
    return jsonResponse({ error: "messages required" }, 400);
  }

  const groqResp = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.GROQ_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: model || "llama-3.3-70b-versatile",
      messages,
      temperature: temperature ?? 0.0,
      max_tokens: max_tokens ?? 2048,
    }),
  });

  if (!groqResp.ok) {
    const errBody = await groqResp.text();
    return jsonResponse({ error: `Groq error: ${errBody}` }, 502);
  }

  const groqJson = (await groqResp.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const resultText = groqJson.choices?.[0]?.message?.content?.trim() ?? "";
  const wordCount = resultText.split(/\s+/).filter((w) => w.length > 0).length;

  // Report usage in background (non-blocking)
  reportUsageAsync(env, userId, wordCount);

  return jsonResponse({ result: resultText, words: wordCount });
}

// ============================================================
// USAGE REPORTING (fire-and-forget)
// ============================================================

function reportUsageAsync(env: Env, userId: string, words: number) {
  // Log usage (always works, no increment needed)
  fetch(`${env.SUPABASE_URL}/rest/v1/usage_log`, {
    method: "POST",
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ user_id: userId, words, action: "dictation" }),
  }).catch(() => {});

  // Increment words_used via raw SQL (Supabase supports this via RPC)
  // Fall back to fetching current value and updating
  fetch(`${env.SUPABASE_URL}/rest/v1/subscriptions?user_id=eq.${userId}&select=words_used`, {
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    },
  })
    .then((r) => r.json())
    .then((data: unknown) => {
      const rows = data as { words_used: number }[];
      if (rows?.[0]) {
        const newCount = rows[0].words_used + words;
        fetch(`${env.SUPABASE_URL}/rest/v1/subscriptions?user_id=eq.${userId}`, {
          method: "PATCH",
          headers: {
            apikey: env.SUPABASE_SERVICE_ROLE_KEY,
            Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
            "Content-Type": "application/json",
            Prefer: "return=minimal",
          },
          body: JSON.stringify({ words_used: newCount }),
        }).catch(() => {});
      }
    })
    .catch(() => {});
}

// ============================================================
// DEMO ENDPOINT (public, rate-limited, no auth)
// ============================================================

// In-memory rate limit store (resets when isolate recycles, ~fine for demo)
const demoRateLimit: Map<string, { count: number; resetAt: number }> = new Map();
const DEMO_MAX_REQUESTS = 5;
const DEMO_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const DEMO_MAX_AUDIO_BYTES = 5 * 1024 * 1024; // 5MB (~30s of audio)

function checkDemoRate(ip: string): boolean {
  const now = Date.now();
  const entry = demoRateLimit.get(ip);
  if (!entry || now > entry.resetAt) {
    demoRateLimit.set(ip, { count: 1, resetAt: now + DEMO_WINDOW_MS });
    return true;
  }
  if (entry.count >= DEMO_MAX_REQUESTS) return false;
  entry.count++;
  return true;
}

async function handleDemo(request: Request, env: Env): Promise<Response> {
  if (request.method !== "POST") {
    return jsonResponse({ error: "POST required" }, 405);
  }

  const ip = request.headers.get("CF-Connecting-IP") || request.headers.get("X-Forwarded-For") || "unknown";
  if (!checkDemoRate(ip)) {
    return jsonResponse({ error: "Rate limit exceeded. Try again in an hour." }, 429);
  }

  const formData = await request.formData();
  const audioFile = formData.get("file");
  if (!audioFile || !(audioFile instanceof File)) {
    return jsonResponse({ error: "No audio file" }, 400);
  }

  if (audioFile.size > DEMO_MAX_AUDIO_BYTES) {
    return jsonResponse({ error: "Audio too long (30s max)" }, 413);
  }

  // Step 1: Transcribe
  const groqForm = new FormData();
  groqForm.append("model", "whisper-large-v3");
  groqForm.append("response_format", "text");
  groqForm.append("file", audioFile, audioFile.name);

  const transcribeResp = await fetch("https://api.groq.com/openai/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${env.GROQ_API_KEY}` },
    body: groqForm,
  });

  if (!transcribeResp.ok) {
    const errBody = await transcribeResp.text();
    return jsonResponse({ error: `Transcription failed: ${errBody}` }, 502);
  }

  const transcript = (await transcribeResp.text()).trim();
  if (!transcript) {
    return jsonResponse({ error: "No speech detected" }, 400);
  }

  // Step 2: Polish with LLM
  const processResp = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.GROQ_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "llama-3.3-70b-versatile",
      temperature: 0.0,
      max_tokens: 1024,
      messages: [
        {
          role: "system",
          content:
            "You are an expert transcription copyeditor. Fix stutters, filler words (um, uh, like), and grammar. Add proper punctuation and capitalization. Keep the original meaning and tone exactly. Output ONLY the polished text, nothing else.",
        },
        { role: "user", content: transcript },
      ],
    }),
  });

  if (!processResp.ok) {
    // If LLM fails, still return the raw transcript
    return jsonResponse({ transcript, polished: transcript });
  }

  const processJson = (await processResp.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const polished = processJson.choices?.[0]?.message?.content?.trim() ?? transcript;

  return jsonResponse({ transcript, polished });
}

// ============================================================
// JWT VERIFICATION via JWKS (supports ECC P-256 + HS256)
// ============================================================

async function verifyJWT(
  token: string,
  supabaseURL: string
): Promise<Record<string, unknown> | null> {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;

    const headerStr = base64UrlDecodeStr(parts[0]);
    const header = JSON.parse(headerStr) as { alg: string; kid?: string };

    const payloadStr = base64UrlDecodeStr(parts[1]);
    const payload = JSON.parse(payloadStr) as Record<string, unknown>;

    // Check expiry first (cheap, no crypto)
    const exp = payload.exp as number;
    if (exp && Date.now() / 1000 > exp) return null;

    const signatureInput = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
    const signature = base64UrlDecode(parts[2]);

    if (header.alg === "ES256") {
      // ECC P-256 — verify via JWKS
      const key = await getJWKSKey(supabaseURL, header.kid);
      if (!key) return null;

      const valid = await crypto.subtle.verify(
        { name: "ECDSA", hash: "SHA-256" },
        key,
        signature.buffer as ArrayBuffer,
        signatureInput
      );
      return valid ? payload : null;
    }

    // Unsupported algorithm
    return null;
  } catch {
    return null;
  }
}

async function getJWKSKey(supabaseURL: string, kid?: string): Promise<CryptoKey | null> {
  // Cache JWKS for 5 minutes
  const now = Date.now();
  if (kid && cachedJWKS[kid] && now - jwksFetchedAt < 300_000) {
    return cachedJWKS[kid];
  }

  try {
    const resp = await fetch(`${supabaseURL}/auth/v1/.well-known/jwks.json`);
    if (!resp.ok) return null;

    const jwks = (await resp.json()) as { keys: JWK[] };

    cachedJWKS = {};
    for (const jwk of jwks.keys) {
      if (jwk.kty === "EC" && jwk.crv === "P-256" && jwk.use === "sig") {
        const key = await crypto.subtle.importKey(
          "jwk",
          jwk,
          { name: "ECDSA", namedCurve: "P-256" },
          false,
          ["verify"]
        );
        if (jwk.kid) cachedJWKS[jwk.kid] = key;
        // If no specific kid requested, use the first one
        if (!kid) return key;
      }
    }

    jwksFetchedAt = now;
    return kid ? cachedJWKS[kid] ?? null : null;
  } catch {
    return null;
  }
}

interface JWK {
  kty: string;
  crv?: string;
  use?: string;
  kid?: string;
  x?: string;
  y?: string;
  [key: string]: unknown;
}

function base64UrlDecode(str: string): Uint8Array {
  let base64 = str.replace(/-/g, "+").replace(/_/g, "/");
  while (base64.length % 4 !== 0) base64 += "=";
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function base64UrlDecodeStr(str: string): string {
  let base64 = str.replace(/-/g, "+").replace(/_/g, "/");
  while (base64.length % 4 !== 0) base64 += "=";
  return atob(base64);
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
