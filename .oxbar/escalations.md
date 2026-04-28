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
2026-04-28 — RESOLVED by Alhassan
E-001: APPROVED — pg_dump the 4 music tables to /backups/2026-04-28_music_purge/ BEFORE the DROP CASCADE runs against prod. PR #7 unblocked, but merge gate is now "backup verified", not "human approval".
E-002: PUNT — Sorani Kurdish deferred to v1.1. Launch scope = EN + AR only. POLYGLOT-KU stand down.

---
E-003 · 2026-04-28 · VAULT · Provision app_vault_data_key on PROD Supabase
  Status: PENDING ALHASSAN
  Why: PR #38 merged the GUC → vault.decrypted_secrets refactor.
       Helpers now look up the key by `name = 'app_vault_data_key'` in
       vault.decrypted_secrets. Staging has the secret (ID
       670d52fa-0023-4236-96bd-da9b55c64da5). Prod does NOT.
  Blocks: PR #36 (PERIODS-FORGE) and any future medical-data PR that
          encrypts columns. Without the secret on prod, every encrypted
          insert raises "app_vault_data_key secret not found".
  Action required from Alhassan:
    1. Open Supabase dashboard → Vagus prod project (kydrpnrmqbedjflklgue)
    2. Confirm supabase_vault extension is enabled
       (Database → Extensions → supabase_vault, toggle on if not).
    3. Run one SQL statement in the SQL editor:
         select vault.create_secret(
           '<256-bit hex key, generate with: openssl rand -hex 32>',
           'app_vault_data_key',
           'AES-256 key for column-level encryption of medical/PII data'
         );
    4. IMPORTANT: the same hex key must be used as the one on staging IF
       any encrypted data is ever migrated between environments. If the
       two environments will never share encrypted blobs (likely true —
       staging usually has fake data), generate a fresh key for prod.
    5. Reply in this file with: "E-003 RESOLVED <date>" once the secret
       is created. Do NOT paste the key value.
