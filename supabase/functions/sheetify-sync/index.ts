// SHEETIFY — Google Sheets sync edge function
//
// Authenticated: requires Supabase JWT in Authorization header.
// All operations use the caller's coach_id derived from the JWT sub.
//
// Actions (POST body { action, ...params }):
//   create_sheet     { client_id, client_name }    → { sheet_id, sheet_url }
//   push_data        { client_id, tab, rows }       → { updated }
//   flush_queue      { }                            → { flushed }
//   poll_changes     { client_id }                  → { changed, conflicts[] }
//   resolve_conflict { conflict_id, resolution }    → { ok }
//   revoke           { }                            → { ok }
//   status           { }                            → { connected, email, sheets[] }
//
// Required edge secrets (same as sheetify-oauth):
//   GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, SHEETIFY_ENCRYPT_KEY,
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (auto-injected)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GOOGLE_CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID") ?? "";
const GOOGLE_CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET") ?? "";
const SHEETIFY_ENCRYPT_KEY = Deno.env.get("SHEETIFY_ENCRYPT_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// ============================================================================
// Tab schemas
// ============================================================================

const TAB_HEADERS: Record<string, string[]> = {
  "Check-ins": ["_row_id", "Date", "Weight (kg)", "Body Fat %", "Mood", "Notes", "Photo URLs"],
  Workout: ["_row_id", "Date", "Exercise", "Sets", "Reps", "Weight (kg)", "RPE", "Notes"],
  Nutrition: ["_row_id", "Date", "Meal", "Food", "Calories", "Protein (g)", "Carbs (g)", "Fat (g)"],
};

const DB_TAB_TO_SHEET_TAB: Record<string, string> = {
  check_ins: "Check-ins",
  workout: "Workout",
  nutrition: "Nutrition",
};

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

async function decryptToken(encrypted: string): Promise<string> {
  const key = await getEncryptionKey();
  const combined = new Uint8Array(
    atob(encrypted).split("").map((c) => c.charCodeAt(0))
  );
  const iv = combined.slice(0, 12);
  const ciphertext = combined.slice(12);
  const plaintext = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, ciphertext);
  return new TextDecoder().decode(plaintext);
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
// Supabase clients
// ============================================================================

function adminClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
}

// ============================================================================
// Token management
// ============================================================================

interface TokenSet {
  accessToken: string;
  refreshToken: string;
}

async function getTokens(coachId: string): Promise<TokenSet> {
  const sb = adminClient();
  const { data, error } = await sb
    .from("coach_google_credentials")
    .select("refresh_token_enc, access_token_enc, token_expires_at, revoked_at")
    .eq("coach_id", coachId)
    .maybeSingle();

  if (error || !data) throw new Error("Google account not connected");
  if (data.revoked_at) throw new Error("Google account disconnected");

  const refreshToken = await decryptToken(data.refresh_token_enc);

  // Use cached access token if still valid (with 60s buffer)
  const expiresAt = data.token_expires_at ? new Date(data.token_expires_at).getTime() : 0;
  if (data.access_token_enc && expiresAt > Date.now() + 60_000) {
    const accessToken = await decryptToken(data.access_token_enc);
    return { accessToken, refreshToken };
  }

  // Refresh
  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      refresh_token: refreshToken,
      client_id: GOOGLE_CLIENT_ID,
      client_secret: GOOGLE_CLIENT_SECRET,
      grant_type: "refresh_token",
    }),
  });

  const tokens = await resp.json();
  if (tokens.error) throw new Error(`Token refresh failed: ${tokens.error}`);

  const newAccessEnc = await encryptToken(tokens.access_token);
  const newExpiresAt = new Date(Date.now() + tokens.expires_in * 1000).toISOString();

  await sb
    .from("coach_google_credentials")
    .update({ access_token_enc: newAccessEnc, token_expires_at: newExpiresAt })
    .eq("coach_id", coachId);

  return { accessToken: tokens.access_token, refreshToken };
}

// ============================================================================
// Sheets API helpers
// ============================================================================

async function sheetsRequest(
  method: string,
  path: string,
  accessToken: string,
  body?: unknown
): Promise<unknown> {
  const resp = await fetch(`https://sheets.googleapis.com/v4${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`Sheets API ${method} ${path} → ${resp.status}: ${text}`);
  }
  return resp.json();
}

async function driveRequest(
  method: string,
  path: string,
  accessToken: string,
  body?: unknown
): Promise<unknown> {
  const resp = await fetch(`https://www.googleapis.com/drive/v3${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`Drive API ${method} ${path} → ${resp.status}: ${text}`);
  }
  return resp.json();
}

// ============================================================================
// Action: create_sheet
// ============================================================================

async function createSheet(
  coachId: string,
  clientId: string,
  clientName: string
): Promise<{ sheet_id: string; sheet_url: string }> {
  const { accessToken } = await getTokens(coachId);

  // Create the spreadsheet
  const spreadsheet = await sheetsRequest(
    "POST",
    "/spreadsheets",
    accessToken,
    {
      properties: { title: `Vagus — ${clientName}` },
      sheets: [
        { properties: { title: "Check-ins", sheetId: 0 } },
        { properties: { title: "Workout", sheetId: 1 } },
        { properties: { title: "Nutrition", sheetId: 2 } },
      ],
    }
  ) as { spreadsheetId: string; spreadsheetUrl: string; sheets: Array<{ properties: { sheetId: number; title: string } }> };

  const spreadsheetId = spreadsheet.spreadsheetId;

  // Write headers for all 3 tabs in one batchUpdate
  const requests = Object.entries(TAB_HEADERS).map(([tabName, headers], idx) => ({
    updateCells: {
      range: {
        sheetId: idx,
        startRowIndex: 0,
        endRowIndex: 1,
        startColumnIndex: 0,
        endColumnIndex: headers.length,
      },
      rows: [
        {
          values: headers.map((h) => ({
            userEnteredValue: { stringValue: h },
            userEnteredFormat: { textFormat: { bold: true } },
          })),
        },
      ],
      fields: "userEnteredValue,userEnteredFormat",
    },
  }));

  await sheetsRequest("POST", `/spreadsheets/${spreadsheetId}:batchUpdate`, accessToken, {
    requests,
  });

  // Hide the _row_id column (column A, index 0) on all 3 tabs
  const hideRequests = [0, 1, 2].map((sheetId) => ({
    updateDimensionProperties: {
      range: { sheetId, dimension: "COLUMNS", startIndex: 0, endIndex: 1 },
      properties: { hiddenByUser: true },
      fields: "hiddenByUser",
    },
  }));
  await sheetsRequest("POST", `/spreadsheets/${spreadsheetId}:batchUpdate`, accessToken, {
    requests: hideRequests,
  });

  const sheetUrl = `https://docs.google.com/spreadsheets/d/${spreadsheetId}`;

  // Store in Supabase
  const sb = adminClient();
  await sb.from("client_sheets").upsert(
    {
      coach_id: coachId,
      client_id: clientId,
      sheet_id: spreadsheetId,
      sheet_url: sheetUrl,
      created_at: new Date().toISOString(),
    },
    { onConflict: "coach_id,client_id" }
  );

  return { sheet_id: spreadsheetId, sheet_url: sheetUrl };
}

// ============================================================================
// Action: push_data
// ============================================================================

async function pushData(
  coachId: string,
  clientId: string,
  tab: string,
  rows: Array<Record<string, unknown>>
): Promise<{ updated: number }> {
  const sb = adminClient();
  const { data: sheetRow } = await sb
    .from("client_sheets")
    .select("sheet_id")
    .eq("coach_id", coachId)
    .eq("client_id", clientId)
    .maybeSingle();

  if (!sheetRow) throw new Error(`No sheet found for client ${clientId}`);

  const { accessToken } = await getTokens(coachId);
  const sheetTabName = DB_TAB_TO_SHEET_TAB[tab];
  if (!sheetTabName) throw new Error(`Unknown tab: ${tab}`);

  // Read current sheet to find existing rows by _row_id
  const existing = await sheetsRequest(
    "GET",
    `/spreadsheets/${sheetRow.sheet_id}/values/${encodeURIComponent(sheetTabName)}!A:A`,
    accessToken
  ) as { values?: string[][] };

  const existingIds: string[] = (existing.values ?? []).slice(1).map((r) => r[0] ?? "");

  const appendRows: unknown[][] = [];
  const updateData: Array<{ range: string; values: unknown[][] }> = [];

  for (const row of rows) {
    const rowId = String(row["_row_id"] ?? "");
    const values = rowToValues(tab, row);
    const existingIndex = existingIds.indexOf(rowId);

    if (existingIndex === -1) {
      appendRows.push(values);
    } else {
      // Row 1 = headers, so existing data starts at row 2 (1-indexed)
      const sheetRowNum = existingIndex + 2;
      updateData.push({
        range: `${sheetTabName}!A${sheetRowNum}:${columnLetter(values.length - 1)}${sheetRowNum}`,
        values: [values],
      });
    }
  }

  let updated = 0;

  if (appendRows.length > 0) {
    await sheetsRequest(
      "POST",
      `/spreadsheets/${sheetRow.sheet_id}/values/${encodeURIComponent(sheetTabName)}!A:Z:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS`,
      accessToken,
      { values: appendRows }
    );
    updated += appendRows.length;
  }

  if (updateData.length > 0) {
    await sheetsRequest(
      "POST",
      `/spreadsheets/${sheetRow.sheet_id}/values:batchUpdate`,
      accessToken,
      { valueInputOption: "USER_ENTERED", data: updateData }
    );
    updated += updateData.length;
  }

  // Update last_synced_at
  await sb
    .from("client_sheets")
    .update({ last_synced_at: new Date().toISOString() })
    .eq("coach_id", coachId)
    .eq("client_id", clientId);

  return { updated };
}

function rowToValues(tab: string, row: Record<string, unknown>): unknown[] {
  switch (tab) {
    case "check_ins":
      return [
        row["_row_id"] ?? "",
        row["date"] ?? "",
        row["weight_kg"] ?? "",
        row["body_fat_percent"] ?? "",
        row["mood"] ?? "",
        row["notes"] ?? "",
        Array.isArray(row["photo_urls"]) ? (row["photo_urls"] as string[]).join(", ") : (row["photo_urls"] ?? ""),
      ];
    case "workout":
      return [
        row["_row_id"] ?? "",
        row["date"] ?? "",
        row["exercise"] ?? "",
        row["sets"] ?? "",
        row["reps"] ?? "",
        row["weight_kg"] ?? "",
        row["rpe"] ?? "",
        row["notes"] ?? "",
      ];
    case "nutrition":
      return [
        row["_row_id"] ?? "",
        row["date"] ?? "",
        row["meal"] ?? "",
        row["food"] ?? "",
        row["calories"] ?? "",
        row["protein_g"] ?? "",
        row["carbs_g"] ?? "",
        row["fat_g"] ?? "",
      ];
    default:
      return [];
  }
}

function columnLetter(index: number): string {
  return String.fromCharCode(65 + index); // A=0, B=1, ...
}

// ============================================================================
// Action: flush_queue
// ============================================================================

async function flushQueue(coachId: string): Promise<{ flushed: number }> {
  const sb = adminClient();
  const { data: items } = await sb
    .from("sheets_sync_queue")
    .select("*")
    .eq("coach_id", coachId)
    .eq("status", "queued")
    .lt("retry_count", 3)
    .order("created_at")
    .limit(50);

  if (!items || items.length === 0) return { flushed: 0 };

  let flushed = 0;
  for (const item of items) {
    try {
      await sb
        .from("sheets_sync_queue")
        .update({ status: "processing" })
        .eq("id", item.id);

      await pushData(coachId, item.client_id, item.tab, item.payload as Array<Record<string, unknown>>);

      await sb
        .from("sheets_sync_queue")
        .update({ status: "done", processed_at: new Date().toISOString() })
        .eq("id", item.id);

      flushed++;
    } catch (err) {
      await sb
        .from("sheets_sync_queue")
        .update({
          status: item.retry_count >= 2 ? "failed" : "queued",
          retry_count: item.retry_count + 1,
          error_msg: String(err),
        })
        .eq("id", item.id);
    }
  }

  return { flushed };
}

// ============================================================================
// Action: poll_changes
// ============================================================================

async function pollChanges(
  coachId: string,
  clientId: string
): Promise<{ changed: boolean; conflicts: unknown[] }> {
  const sb = adminClient();
  const { data: sheetRow } = await sb
    .from("client_sheets")
    .select("sheet_id, last_revision_id")
    .eq("coach_id", coachId)
    .eq("client_id", clientId)
    .maybeSingle();

  if (!sheetRow) return { changed: false, conflicts: [] };

  const { accessToken } = await getTokens(coachId);

  // Cheap change detection via Drive file version
  const fileMeta = await driveRequest(
    "GET",
    `/files/${sheetRow.sheet_id}?fields=version`,
    accessToken
  ) as { version: string };

  const newRevision = fileMeta.version;
  if (newRevision === sheetRow.last_revision_id) {
    return { changed: false, conflicts: [] };
  }

  // Version changed — read all 3 tabs and compare with app data
  const conflicts: unknown[] = [];
  for (const [dbTab, sheetTab] of Object.entries(DB_TAB_TO_SHEET_TAB)) {
    const tabConflicts = await detectTabConflicts(
      accessToken,
      coachId,
      clientId,
      sheetRow.sheet_id,
      sheetTab,
      dbTab
    );
    conflicts.push(...tabConflicts);
  }

  // Store new conflicts
  if (conflicts.length > 0) {
    await sb.from("sheets_sync_conflicts").insert(conflicts);
  }

  // Update revision ID
  await sb
    .from("client_sheets")
    .update({ last_revision_id: newRevision })
    .eq("coach_id", coachId)
    .eq("client_id", clientId);

  return { changed: true, conflicts };
}

async function detectTabConflicts(
  accessToken: string,
  coachId: string,
  clientId: string,
  spreadsheetId: string,
  sheetTab: string,
  dbTab: string
): Promise<unknown[]> {
  const sheet = await sheetsRequest(
    "GET",
    `/spreadsheets/${spreadsheetId}/values/${encodeURIComponent(sheetTab)}!A:Z`,
    accessToken
  ) as { values?: unknown[][] };

  const rows = (sheet.values ?? []).slice(1); // skip header row
  if (rows.length === 0) return [];

  const rowIds = rows.map((r) => String((r as unknown[])[0] ?? "")).filter((id) => id !== "");
  if (rowIds.length === 0) return [];

  // Fetch app rows for the same IDs
  const sb = adminClient();
  const appTable = dbTabToAppTable(dbTab);
  if (!appTable) return [];

  const { data: appRows } = await sb
    .from(appTable)
    .select("*")
    .in("id", rowIds)
    .eq("client_id", clientId);

  const appRowMap = new Map<string, Record<string, unknown>>(
    (appRows ?? []).map((r: Record<string, unknown>) => [String(r["id"]), r])
  );

  const conflicts: unknown[] = [];
  const now = new Date().toISOString();

  for (const sheetRow of rows) {
    const rowArr = sheetRow as unknown[];
    const rowId = String(rowArr[0] ?? "");
    if (!rowId) continue;

    const appRow = appRowMap.get(rowId);
    const sheetValues = sheetRowToJson(dbTab, rowArr);

    if (!appRow) {
      // Row in sheet but not in app — sheet-only row
      conflicts.push({
        coach_id: coachId,
        client_id: clientId,
        sheet_id: spreadsheetId,
        tab: dbTab,
        row_id: rowId,
        local_value: {},
        sheet_value: sheetValues,
        detected_at: now,
      });
      continue;
    }

    const localValues = appRowToJson(dbTab, appRow);
    if (!shallowEqual(localValues, sheetValues)) {
      conflicts.push({
        coach_id: coachId,
        client_id: clientId,
        sheet_id: spreadsheetId,
        tab: dbTab,
        row_id: rowId,
        local_value: localValues,
        sheet_value: sheetValues,
        detected_at: now,
      });
    }
  }

  return conflicts;
}

function dbTabToAppTable(dbTab: string): string | null {
  switch (dbTab) {
    case "check_ins":
      return "checkins";
    case "workout":
      return "workout_logs";
    case "nutrition":
      return "food_logs";
    default:
      return null;
  }
}

function sheetRowToJson(dbTab: string, row: unknown[]): Record<string, unknown> {
  switch (dbTab) {
    case "check_ins":
      return {
        date: row[1] ?? "",
        weight_kg: row[2] ?? "",
        body_fat_percent: row[3] ?? "",
        mood: row[4] ?? "",
        notes: row[5] ?? "",
        photo_urls: row[6] ?? "",
      };
    case "workout":
      return {
        date: row[1] ?? "",
        exercise: row[2] ?? "",
        sets: row[3] ?? "",
        reps: row[4] ?? "",
        weight_kg: row[5] ?? "",
        rpe: row[6] ?? "",
        notes: row[7] ?? "",
      };
    case "nutrition":
      return {
        date: row[1] ?? "",
        meal: row[2] ?? "",
        food: row[3] ?? "",
        calories: row[4] ?? "",
        protein_g: row[5] ?? "",
        carbs_g: row[6] ?? "",
        fat_g: row[7] ?? "",
      };
    default:
      return {};
  }
}

function appRowToJson(dbTab: string, row: Record<string, unknown>): Record<string, unknown> {
  switch (dbTab) {
    case "check_ins":
      return {
        date: String(row["checkin_date"] ?? row["date"] ?? ""),
        weight_kg: String(row["weight_kg"] ?? ""),
        body_fat_percent: String(row["body_fat_percent"] ?? ""),
        mood: String(row["mood"] ?? ""),
        notes: String(row["notes"] ?? ""),
        photo_urls: String(row["photo_urls"] ?? ""),
      };
    case "workout":
      return {
        date: String(row["workout_date"] ?? row["date"] ?? ""),
        exercise: String(row["exercise"] ?? ""),
        sets: String(row["sets"] ?? ""),
        reps: String(row["reps"] ?? ""),
        weight_kg: String(row["weight_kg"] ?? ""),
        rpe: String(row["rpe"] ?? ""),
        notes: String(row["notes"] ?? ""),
      };
    case "nutrition":
      return {
        date: String(row["logged_at"] ?? row["date"] ?? ""),
        meal: String(row["meal_name"] ?? row["meal"] ?? ""),
        food: String(row["food_name"] ?? row["food"] ?? ""),
        calories: String(row["calories"] ?? ""),
        protein_g: String(row["protein_g"] ?? ""),
        carbs_g: String(row["carbs_g"] ?? ""),
        fat_g: String(row["fat_g"] ?? ""),
      };
    default:
      return {};
  }
}

function shallowEqual(a: Record<string, unknown>, b: Record<string, unknown>): boolean {
  const keysA = Object.keys(a);
  if (keysA.length !== Object.keys(b).length) return false;
  return keysA.every((k) => String(a[k] ?? "") === String(b[k] ?? ""));
}

// ============================================================================
// Action: resolve_conflict
// ============================================================================

async function resolveConflict(
  coachId: string,
  conflictId: string,
  resolution: string
): Promise<{ ok: boolean }> {
  const sb = adminClient();
  const { error } = await sb
    .from("sheets_sync_conflicts")
    .update({
      resolved_at: new Date().toISOString(),
      resolution,
    })
    .eq("id", conflictId)
    .eq("coach_id", coachId);

  if (error) throw new Error(error.message);
  return { ok: true };
}

// ============================================================================
// Action: revoke
// ============================================================================

async function revokeAccess(coachId: string): Promise<{ ok: boolean }> {
  const sb = adminClient();
  const { data } = await sb
    .from("coach_google_credentials")
    .select("access_token_enc, refresh_token_enc")
    .eq("coach_id", coachId)
    .maybeSingle();

  if (data?.access_token_enc) {
    try {
      const accessToken = await decryptToken(data.access_token_enc);
      // Revoke with Google
      await fetch(`https://oauth2.googleapis.com/revoke?token=${encodeURIComponent(accessToken)}`, {
        method: "POST",
      });
    } catch {
      // Best-effort — mark revoked in DB regardless
    }
  }

  await sb
    .from("coach_google_credentials")
    .update({ revoked_at: new Date().toISOString() })
    .eq("coach_id", coachId);

  return { ok: true };
}

// ============================================================================
// Action: status
// ============================================================================

async function getStatus(coachId: string): Promise<{
  connected: boolean;
  email: string | null;
  sheets: unknown[];
}> {
  const sb = adminClient();
  const [credsRes, sheetsRes] = await Promise.all([
    sb
      .from("coach_google_credentials")
      .select("google_email, connected_at, revoked_at")
      .eq("coach_id", coachId)
      .maybeSingle(),
    sb
      .from("client_sheets")
      .select("id, client_id, sheet_id, sheet_url, last_synced_at, created_at")
      .eq("coach_id", coachId)
      .order("created_at", { ascending: false }),
  ]);

  const creds = credsRes.data;
  const connected = !!creds && !creds.revoked_at;

  return {
    connected,
    email: connected ? creds?.google_email ?? null : null,
    sheets: sheetsRes.data ?? [],
  };
}

// ============================================================================
// Auth helper
// ============================================================================

async function getCoachId(req: Request): Promise<string> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) throw new Error("Missing Authorization header");

  const jwt = authHeader.slice(7);
  // Decode JWT payload (no verify — Supabase's edge runtime already verifies)
  const [, payloadB64] = jwt.split(".");
  const payload = JSON.parse(atob(payloadB64.replace(/-/g, "+").replace(/_/g, "/")));
  const sub = payload.sub;
  if (!sub) throw new Error("Invalid JWT: missing sub");
  return sub;
}

// ============================================================================
// Entry point
// ============================================================================

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const coachId = await getCoachId(req);
    const body = await req.json() as Record<string, unknown>;
    const action = body["action"] as string;

    switch (action) {
      case "create_sheet":
        return json(
          await createSheet(
            coachId,
            body["client_id"] as string,
            body["client_name"] as string
          )
        );

      case "push_data":
        return json(
          await pushData(
            coachId,
            body["client_id"] as string,
            body["tab"] as string,
            body["rows"] as Array<Record<string, unknown>>
          )
        );

      case "flush_queue":
        return json(await flushQueue(coachId));

      case "poll_changes":
        return json(await pollChanges(coachId, body["client_id"] as string));

      case "resolve_conflict":
        return json(
          await resolveConflict(
            coachId,
            body["conflict_id"] as string,
            body["resolution"] as string
          )
        );

      case "revoke":
        return json(await revokeAccess(coachId));

      case "status":
        return json(await getStatus(coachId));

      default:
        return json({ error: `Unknown action: ${action}` }, 400);
    }
  } catch (err) {
    console.error("sheetify-sync error:", err);
    const message = err instanceof Error ? err.message : String(err);
    const status = message.includes("not connected") || message.includes("disconnected") ? 403 : 500;
    return json({ error: message }, status);
  }
});
