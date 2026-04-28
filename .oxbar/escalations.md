# OXBAR Escalations to Alhassan

> Items blocked on human owner. Alhassan checks once daily.
> Format: `## E-NNN · YYYY-MM-DD · AGENT · short title`. Append-only; mark `RESOLVED: <date>` when Alhassan replies and append the call.

---

## E-001 · 2026-04-27 · MUSIC-PURGE · Prod data drop approval (PR #7)

**Trigger:** OXBAR pipeline-authority rule #1 — *"Apply a migration to **production** Supabase"* requires Alhassan's explicit approval.

PR #7 (`agent/music-purge` → `main`) adds `supabase/migrations/20260427192816_music_purge_drop_tables.sql`, which `DROP TABLE … CASCADE`s four tables:

- `public.music_links`
- `public.workout_music_refs`
- `public.event_music_refs`
- `public.user_music_prefs`

When this PR merges to `main`, `.github/workflows/deploy.yml` runs `supabase db push --include-all` against the PROD project (`kydrpnrmqbedjflklgue`) and drops the data unrecoverably. The migration's "rollback" comment recreates the schema only — **no row-level data backup is performed**.

**Question for Alhassan:**
1. Approve dropping these tables on production? (i.e., music feature data is retired with no preservation needed)
2. Or: do you want OXBAR to take a one-time `pg_dump` of these four tables on prod first (read-only via MCP), store the dump in a private bucket, and then merge?

**Status:** OXBAR is **HOLDING** the merge of PR #7 until Alhassan replies here. CI may go green; that doesn't unblock the merge.

(Non-prod-data parts of PR #7 — code deletions, CHANGELOG — are independent and would be approved/merged in a normal flow.)

---

## E-002 · 2026-04-27 · POLYGLOT-KU · Kurdish-Sorani translation pipeline needs human-in-the-loop arrangement

**Decision needed:** How should POLYGLOT-KU produce `lib/l10n/app_ku.arb` at the quality bar the mission demands?

**Why escalating (not just BLOCKED-on-TONGUE):** TONGUE blocking is expected (Wave B). The deeper question is independent of TONGUE: even once `app_en.arb` exists, POLYGLOT-KU's mission requires (a) Gemini Flash API access, neither of which is provisioned, and (b) a native-Sorani reviewer pass. Mission FORBIDS auto-accepting LLM output and explicitly notes Sorani LLM quality is "lower base" than Arabic. Without these, the agent will either ship low-quality strings (violates FORBIDDEN) or sit BLOCKED indefinitely.

**Options:**
- **(1)** Provision Gemini API key in agent env + arrange recurring Sorani reviewer (e.g. weekly review batches). Agent operates as designed.
- **(2)** Drop Sorani from launch scope; mark POLYGLOT-KU ABANDONED; ship app with EN/AR only and add KU post-launch via human translator.
- **(3)** Accept lower quality bar: let agent generate Gemini-only output, mark every string with a `// review-pending` marker in the .arb, push to a feature-flagged KU locale invisible to users until reviewed. Requires explicit waiver of the mission's FORBIDDEN clause.

**Recommendation:** (1) if Sorani at launch is a hard requirement; (2) if it's nice-to-have. (3) is workable but needs explicit waiver in writing — agent will not self-authorize this.

**Blocking:** POLYGLOT-KU progress past PENDING-glossary work. Not blocking other agents.

**OXBAR note:** This is correctly outside OXBAR authority (scope/quality call). Same question latently applies to POLYGLOT-AR — Arabic has higher LLM quality but a native reviewer is still mission-required for medical/cultural strings. If Alhassan picks (2), POLYGLOT-AR remains in scope; if (1), the same Gemini key + reviewer arrangement covers AR too.

---

## E-003 · 2026-04-28 · SHEETIFY · Google OAuth client ID + 3 edge secrets needed

**Trigger:** SHEETIFY cannot make OAuth work without a Google Cloud OAuth client configured. This requires a human with access to Google Cloud Console.

**What is needed — 3 steps, ~10 minutes total:**

### Step 1 — Create OAuth 2.0 client in Google Cloud Console
1. Go to [console.cloud.google.com](https://console.cloud.google.com) → select or create a project for Vagus
2. APIs & Services → Credentials → Create credentials → OAuth client ID
3. Application type: **Web application**
4. Name: `Vagus Sheetify`
5. Authorized redirect URIs — add the Supabase edge function URL:
   `https://<your-supabase-project-ref>.supabase.co/functions/v1/sheetify-oauth`
   (Replace `<your-supabase-project-ref>` with the prod project ref — visible in Supabase Dashboard URL)
6. Scopes to enable (OAuth consent screen): `spreadsheets`, `drive.file`, `email`, `profile`
   - `https://www.googleapis.com/auth/spreadsheets`
   - `https://www.googleapis.com/auth/drive.file`
7. Copy the **Client ID** and **Client Secret**

### Step 2 — Set edge function secrets in Supabase Dashboard
Go to Supabase Dashboard → Edge Functions → Secrets, add:
```
GOOGLE_CLIENT_ID=<paste client ID from step 1>
GOOGLE_CLIENT_SECRET=<paste client secret from step 1>
SHEETIFY_ENCRYPT_KEY=<generate with: openssl rand -hex 32>
```
`SHEETIFY_ENCRYPT_KEY` is a 64-character hex string (256-bit AES key). Generate it fresh — do NOT reuse any existing key. Store it in your password manager; it encrypts all coach Google refresh tokens.

### Step 3 — Configure app deep link
Confirm that `vagus://sheetify/connected` is registered in the Android/iOS app as a custom URI scheme so the OAuth callback can return to the app. The `app_links` package is already in `pubspec.yaml`. If the URI scheme `vagus://` is not yet configured in `AndroidManifest.xml` / `Info.plist`, add it.

**Impact:** SHEETIFY's OAuth flow will not work until these secrets are provisioned. The rest of the sync engine (sheet creation, push, poll) is code-complete and unblocked.

**Status:** BLOCKED on Alhassan. Does not block PR merge (CI does not test the live OAuth flow).
