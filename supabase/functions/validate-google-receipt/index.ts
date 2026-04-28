// Supabase Edge Function: validate-google-receipt
// Validates a Google Play subscription purchase token against the Google Play
// Developer API, then upserts the subscription state into `public.subscriptions`.
//
// Required secrets (set via `supabase secrets set`):
//   GOOGLE_SERVICE_ACCOUNT_JSON — full service account JSON with androidpublisher scope
//
// The service account must have the "Financial data viewer" role in Play Console.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const GOOGLE_SA_JSON = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON") ?? "";

const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

interface ValidateRequest {
  userId: string;
  purchaseToken: string;
  productId: string;
  packageName: string;
}

// Subset of the Google Play Developer API SubscriptionPurchase resource
interface GoogleSubscriptionPurchase {
  kind: string;
  startTimeMillis: string;
  expiryTimeMillis: string;
  autoRenewing: boolean;
  paymentState?: number; // 0=pending, 1=received, 2=free trial, 3=deferred
  cancelReason?: number; // 0=user, 1=system, 2=replaced, 3=developer
  acknowledgementState: number; // 0=not acknowledged, 1=acknowledged
}

// ── JWT / OAuth helpers ──────────────────────────────────────────────────────

function pemToBytes(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function strToBase64Url(str: string): string {
  const bytes = new TextEncoder().encode(str);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

function bufToBase64Url(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

async function getGoogleAccessToken(): Promise<string> {
  if (!GOOGLE_SA_JSON) throw new Error("GOOGLE_SERVICE_ACCOUNT_JSON not set");
  const sa = JSON.parse(GOOGLE_SA_JSON);

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const now = Math.floor(Date.now() / 1000);
  const headerB64 = strToBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payloadB64 = strToBase64Url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  }));

  const signingInput = `${headerB64}.${payloadB64}`;
  const sigBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const jwt = `${signingInput}.${bufToBase64Url(sigBytes)}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenRes.ok) {
    throw new Error(`OAuth token exchange failed: ${await tokenRes.text()}`);
  }
  const { access_token } = await tokenRes.json();
  return access_token as string;
}

// ── Google Play Developer API calls ─────────────────────────────────────────

async function fetchGoogleSubscription(
  token: string,
  packageName: string,
  productId: string,
  purchaseToken: string,
): Promise<GoogleSubscriptionPurchase> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications` +
    `/${packageName}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`;

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    throw new Error(`Play Developer API error ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

async function acknowledgeSubscription(
  token: string,
  packageName: string,
  productId: string,
  purchaseToken: string,
): Promise<void> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications` +
    `/${packageName}/purchases/subscriptions/${productId}/tokens/${purchaseToken}:acknowledge`;

  await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: "{}",
  });
}

// ── Mapping ──────────────────────────────────────────────────────────────────

function mapStatus(sub: GoogleSubscriptionPurchase): string {
  const nowMs = Date.now();
  const expiryMs = parseInt(sub.expiryTimeMillis, 10);

  if (expiryMs < nowMs) return "expired";
  if (sub.paymentState === 2) return "trialing";
  if (sub.paymentState === 0) return "past_due";
  if (!sub.autoRenewing) return "canceled"; // will expire but currently accessible
  return "active";
}

// ── CORS ─────────────────────────────────────────────────────────────────────

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

// ── Handler ──────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 200, headers: CORS });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    // 1. Authenticate caller via Supabase JWT
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);

    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authErr } = await userClient.auth.getUser();
    if (authErr || !user) return json({ error: "Unauthorized" }, 401);

    // 2. Parse and validate body
    const body: ValidateRequest = await req.json();

    // Prevent userId spoofing: body.userId must match the JWT subject
    if (body.userId !== user.id) return json({ error: "Forbidden" }, 403);

    if (!body.purchaseToken || !body.productId || !body.packageName) {
      return json({ error: "Missing required fields" }, 400);
    }

    // 3. Authenticate with Google
    const accessToken = await getGoogleAccessToken();

    // 4. Validate against Google Play Developer API
    const googleSub = await fetchGoogleSubscription(
      accessToken,
      body.packageName,
      body.productId,
      body.purchaseToken,
    );

    const status = mapStatus(googleSub);
    const periodStart = new Date(parseInt(googleSub.startTimeMillis, 10)).toISOString();
    const periodEnd = new Date(parseInt(googleSub.expiryTimeMillis, 10)).toISOString();

    // 5. Upsert subscription row (one row per user+store)
    const { data: existing } = await adminClient
      .from("subscriptions")
      .select("id")
      .eq("user_id", body.userId)
      .eq("store", "google")
      .order("updated_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const subscriptionPayload = {
      plan_code: body.productId, // product ID == plan code
      status,
      period_start: periodStart,
      period_end: periodEnd,
      cancel_at_period_end: !googleSub.autoRenewing,
      purchase_token: body.purchaseToken,
      updated_at: new Date().toISOString(),
    };

    const { error: dbErr } = existing
      ? await adminClient
          .from("subscriptions")
          .update(subscriptionPayload)
          .eq("id", existing.id)
      : await adminClient
          .from("subscriptions")
          .insert({ ...subscriptionPayload, user_id: body.userId, store: "google" });

    if (dbErr) {
      console.error("Supabase write error:", dbErr);
      return json({ error: "Failed to sync subscription" }, 500);
    }

    // 6. Acknowledge purchase to prevent automatic refund (3-day window)
    if (googleSub.acknowledgementState === 0) {
      await acknowledgeSubscription(
        accessToken,
        body.packageName,
        body.productId,
        body.purchaseToken,
      );
    }

    return json({ success: true, status, planCode: body.productId, periodEnd });
  } catch (err) {
    console.error("validate-google-receipt unhandled error:", err);
    return json({ error: "Internal server error" }, 500);
  }
});
