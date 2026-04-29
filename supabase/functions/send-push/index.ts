/**
 * send-push — SIGNAL v2 Edge Function
 *
 * POST body:
 *   { user_id: string, template_key: string, params: Record<string,string> }
 *
 * Behaviour:
 *   1. Check user's notification preference for the template's category.
 *   2. Look up active FCM tokens for the user.
 *   3. Render title/body from notification_templates in user's preferred locale.
 *   4. POST to FCM v1 API for each token.
 *
 * Required Supabase secrets:
 *   FCM_PROJECT_ID          — Firebase project ID
 *   FCM_SERVICE_ACCOUNT_JSON — Full service account JSON (stringified)
 *
 * Set with:
 *   supabase secrets set FCM_PROJECT_ID=...
 *   supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "";
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// ─────────────────────────────────────────────
// FCM v1 API helpers
// ─────────────────────────────────────────────

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

  const signingInput = `${encode(header)}.${encode(payload)}`;

  // Import the RSA private key.
  const pemBody = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\n/g, "");
  const keyDer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${signingInput}.${sigB64}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  const tokenJson = await tokenRes.json();
  return tokenJson.access_token as string;
}

async function sendFcmMessage(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<boolean> {
  const url = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
        data,
        android: { priority: "high" },
        apns: {
          headers: { "apns-priority": "10" },
          payload: { aps: { sound: "default" } },
        },
      },
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    console.error(`[FCM] Send failed for token ${fcmToken.slice(0, 20)}...:`, err);
    return false;
  }
  return true;
}

// ─────────────────────────────────────────────
// Template rendering
// ─────────────────────────────────────────────

function renderTemplate(
  template: string,
  params: Record<string, string>,
): string {
  return template.replace(/\{(\w+)\}/g, (_, key) => params[key] ?? `{${key}}`);
}

// ─────────────────────────────────────────────
// Request handler
// ─────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json", ...CORS_HEADERS },
    });
  }

  try {
    const { user_id, template_key, params = {} } = await req.json() as {
      user_id: string;
      template_key: string;
      params?: Record<string, string>;
    };

    if (!user_id || !template_key) {
      return new Response(
        JSON.stringify({ error: "user_id and template_key are required" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json", ...CORS_HEADERS },
        },
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Get user's preferred locale.
    const { data: settings } = await supabase
      .from("user_settings")
      .select("language_code")
      .eq("user_id", user_id)
      .maybeSingle();
    const locale = (settings?.language_code as string) ?? "en";

    // 2. Resolve template (preferred locale → fall back to EN).
    const { data: templates } = await supabase
      .from("notification_templates")
      .select("title, body, category")
      .eq("template_key", template_key)
      .in("locale", [locale, "en"]);

    const templateRow =
      templates?.find((t) => t.locale === locale) ??
      templates?.find((t) => t.locale === "en");

    if (!templateRow) {
      return new Response(
        JSON.stringify({ error: `Template not found: ${template_key}` }),
        {
          status: 404,
          headers: { "Content-Type": "application/json", ...CORS_HEADERS },
        },
      );
    }

    const category: string = templateRow.category;

    // 3. Check user's notification preference for this category.
    const { data: prefCheck } = await supabase.rpc("is_notification_enabled", {
      p_user_id: user_id,
      p_category: category,
    });
    if (prefCheck === false) {
      return new Response(
        JSON.stringify({ skipped: true, reason: "user preference disabled" }),
        {
          status: 200,
          headers: { "Content-Type": "application/json", ...CORS_HEADERS },
        },
      );
    }

    // 4. Get active FCM tokens for the user.
    const { data: devices } = await supabase
      .from("user_devices")
      .select("fcm_token")
      .eq("user_id", user_id)
      .not("fcm_token", "is", null);

    const tokens = (devices ?? [])
      .map((d) => d.fcm_token as string)
      .filter(Boolean);

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ skipped: true, reason: "no FCM tokens registered" }),
        {
          status: 200,
          headers: { "Content-Type": "application/json", ...CORS_HEADERS },
        },
      );
    }

    // 5. Render template.
    const title = renderTemplate(templateRow.title, params);
    const body = renderTemplate(templateRow.body, params);

    const data: Record<string, string> = {
      template_key,
      category,
      ...(params.route ? { route: params.route } : {}),
    };

    // 6. Obtain FCM access token and send.
    if (!FCM_SERVICE_ACCOUNT_JSON || !FCM_PROJECT_ID) {
      return new Response(
        JSON.stringify({ error: "FCM not configured (missing secrets)" }),
        {
          status: 503,
          headers: { "Content-Type": "application/json", ...CORS_HEADERS },
        },
      );
    }

    const sa: ServiceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
    const accessToken = await getAccessToken(sa);

    const results = await Promise.all(
      tokens.map((token) =>
        sendFcmMessage(accessToken, token, title, body, data),
      ),
    );

    const sent = results.filter(Boolean).length;
    console.log(
      `[send-push] ${template_key} → user ${user_id}: ${sent}/${tokens.length} delivered`,
    );

    return new Response(
      JSON.stringify({ success: true, sent, total: tokens.length }),
      {
        status: 200,
        headers: { "Content-Type": "application/json", ...CORS_HEADERS },
      },
    );
  } catch (err) {
    console.error("[send-push] Unhandled error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...CORS_HEADERS },
      },
    );
  }
});
