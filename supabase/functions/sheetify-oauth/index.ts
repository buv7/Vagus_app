// SHEETIFY — Google OAuth edge function
//
// Handles two roles:
//   POST { action: 'get_auth_url', coach_id } → { url }
//     Returns the Google OAuth consent URL. Called by the app before launching the browser.
//
//   GET ?code=...&state=<coachId>:<nonce>
//     OAuth callback from Google. Exchanges code for tokens, encrypts and stores them,
//     then redirects the user back to the app via deep link vagus://sheetify/connected.
//
// Required edge secrets:
//   GOOGLE_CLIENT_ID        — from Google Cloud Console (see escalations.md E-003)
//   GOOGLE_CLIENT_SECRET    — from Google Cloud Console
//   SHEETIFY_ENCRYPT_KEY    — 64-char hex string (256-bit AES key), generate with openssl rand -hex 32
//   SUPABASE_URL            — auto-injected by Supabase
//   SUPABASE_SERVICE_ROLE_KEY — auto-injected by Supabase

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GOOGLE_CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID") ?? "";
const GOOGLE_CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET") ?? "";
const SHEETIFY_ENCRYPT_KEY = Deno.env.get("SHEETIFY_ENCRYPT_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const GOOGLE_SCOPES = [
  "https://www.googleapis.com/auth/spreadsheets",
  "https://www.googleapis.com/auth/drive.file",
  "email",
  "profile",
].join(" ");

// Redirect URI registered in Google Console = this function's URL
const REDIRECT_URI = `${SUPABASE_URL}/functions/v1/sheetify-oauth`;

// ============================================================================
// Crypto helpers — AES-256-GCM
// ============================================================================

async function getEncryptionKey(): Promise<CryptoKey> {
  const keyBytes = new Uint8Array(
    (SHEETIFY_ENCRYPT_KEY.match(/.{2}/g) ?? []).map((b) => parseInt(b, 16))
  );
  return crypto.subtle.importKey("raw", keyBytes, { name: "AES-GCM", length: 256 }, false, [
    "encrypt",
    "decrypt",
  ]);
}

async function encryptToken(plaintext: string): Promise<string> {
  const key = await getEncryptionKey();
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encoded = new TextEncoder().encode(plaintext);
  const ciphertext = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, encoded);
  const combined = new Uint8Array(iv.length + ciphertext.byteLength);
  combined.set(iv);
  combined.set(new Uint8Array(ciphertext), iv.length);
  return btoa(String.fromCharCode(...combined));
}

// ============================================================================
// OAuth helpers
// ============================================================================

function buildAuthUrl(coachId: string): string {
  const nonce = crypto.randomUUID();
  const state = `${coachId}:${nonce}`;
  const params = new URLSearchParams({
    client_id: GOOGLE_CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    response_type: "code",
    scope: GOOGLE_SCOPES,
    access_type: "offline",
    prompt: "consent",
    state,
  });
  return `https://accounts.google.com/o/oauth2/v2/auth?${params}`;
}

async function exchangeCode(code: string): Promise<{
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
  error?: string;
}> {
  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      code,
      client_id: GOOGLE_CLIENT_ID,
      client_secret: GOOGLE_CLIENT_SECRET,
      redirect_uri: REDIRECT_URI,
      grant_type: "authorization_code",
    }),
  });
  return resp.json();
}

async function getGoogleEmail(accessToken: string): Promise<string> {
  const resp = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  const info = await resp.json();
  return info.email ?? "";
}

// ============================================================================
// Supabase admin client
// ============================================================================

function adminClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
}

// ============================================================================
// Handlers
// ============================================================================

async function handleGetAuthUrl(req: Request): Promise<Response> {
  const body = await req.json() as { action: string; coach_id: string };
  if (!body.coach_id) {
    return jsonError("coach_id is required", 400);
  }
  const url = buildAuthUrl(body.coach_id);
  return json({ url });
}

async function handleOAuthCallback(url: URL): Promise<Response> {
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state") ?? "";
  const errorParam = url.searchParams.get("error");

  if (errorParam) {
    return htmlRedirect(`vagus://sheetify/connected?status=error&reason=${encodeURIComponent(errorParam)}`);
  }

  if (!code) {
    return htmlRedirect("vagus://sheetify/connected?status=error&reason=no_code");
  }

  // state = <coachId>:<nonce>
  const [coachId] = state.split(":");
  if (!coachId) {
    return htmlRedirect("vagus://sheetify/connected?status=error&reason=bad_state");
  }

  const tokens = await exchangeCode(code);
  if (tokens.error) {
    return htmlRedirect(
      `vagus://sheetify/connected?status=error&reason=${encodeURIComponent(tokens.error)}`
    );
  }

  const [googleEmail, refreshEnc, accessEnc] = await Promise.all([
    getGoogleEmail(tokens.access_token),
    encryptToken(tokens.refresh_token),
    encryptToken(tokens.access_token),
  ]);

  const expiresAt = new Date(Date.now() + tokens.expires_in * 1000).toISOString();

  const sb = adminClient();
  const { error: upsertError } = await sb.from("coach_google_credentials").upsert(
    {
      coach_id: coachId,
      google_email: googleEmail,
      refresh_token_enc: refreshEnc,
      access_token_enc: accessEnc,
      token_expires_at: expiresAt,
      revoked_at: null,
      connected_at: new Date().toISOString(),
    },
    { onConflict: "coach_id" }
  );

  if (upsertError) {
    console.error("sheetify-oauth: upsert error", upsertError);
    return htmlRedirect(
      `vagus://sheetify/connected?status=error&reason=${encodeURIComponent(upsertError.message)}`
    );
  }

  return htmlRedirect("vagus://sheetify/connected?status=ok");
}

// ============================================================================
// Response helpers
// ============================================================================

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function jsonError(message: string, status = 400): Response {
  return json({ error: message }, status);
}

function htmlRedirect(deepLink: string): Response {
  const html = `<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="refresh" content="0; url=${deepLink}" />
  <title>Connecting…</title>
</head>
<body>
  <p>Redirecting back to Vagus…</p>
  <script>window.location.href="${deepLink}";</script>
</body>
</html>`;
  return new Response(html, {
    status: 200,
    headers: { "Content-Type": "text/html; charset=utf-8" },
  });
}

// ============================================================================
// Entry point
// ============================================================================

serve(async (req: Request) => {
  const url = new URL(req.url);

  try {
    if (req.method === "GET" && url.searchParams.has("code")) {
      return await handleOAuthCallback(url);
    }
    if (req.method === "POST") {
      return await handleGetAuthUrl(req);
    }
    return jsonError("Not found", 404);
  } catch (err) {
    console.error("sheetify-oauth error:", err);
    return jsonError("Internal server error", 500);
  }
});
