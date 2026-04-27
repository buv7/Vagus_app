# Handoff from VAULT to ALL agents

**Date:** 2026-04-27
**PR:** #6 (`agent/vault-init`)

## What's now available

Three things every agent in the swarm should know about, regardless of wave or specialization:

### 1. CI now enforces secrets / licenses / RLS

`.github/workflows/vault.yml` runs on every PR. Three required jobs:

| Job | What it blocks | How to pass |
|---|---|---|
| `gitleaks (no secrets in code)` | Any AWS / Supabase / API-key match in your diff or commit history | Use env vars (`String.fromEnvironment` in Dart, `secrets.*` in workflows). Never inline a key. |
| `license scan (no GPL/AGPL/SSPL/BUSL)` | A new `pubspec.yaml` dep whose pub.dev SPDX is GPL / LGPL-3 / AGPL / SSPL / BUSL / Commons-Clause / Elastic-2.0 / CC-BY-NC | Pick a permissive replacement (MIT / Apache-2.0 / BSD). If pub.dev's metadata is wrong, see ALLOWLIST in `vault.yml` and ping VAULT. |
| `RLS validation (every new table has RLS)` | A new `CREATE TABLE` in `supabase/migrations/*.sql` without `ALTER TABLE … ENABLE ROW LEVEL SECURITY` and `CREATE POLICY … ON …` in the same file | Add both in the same migration. For genuinely-global lookup tables, opt out: `-- vault-rls-exempt: <table_name> reason: <one-line>` |

The check that blocks you usually shows up in the PR's CI section labelled "VAULT — security, secrets, licenses, RLS".

### 2. PII sanitizer for any LLM call

`lib/services/ai/pii_sanitizer.dart` is the **required** wrapper for anything you send to Cerebras, Groq, Gemini, OpenRouter, or any other third-party LLM endpoint.

Use it like this:
```dart
import 'package:vagus_app/services/ai/pii_sanitizer.dart';

final sanitized = PiiSanitizer.sanitizeAndAssert(
  rawPrompt,
  knownNames: [user.fullName, coach?.fullName].whereType<String>().toList(),
  site: 'food_vision_service.classifyMeal',
);
final response = await aiClient.chat(
  model: 'cerebras-llama-3.3-70b',
  messages: [{'role': 'user', 'content': sanitized}],
);
```

What it does:
- Strips email, phone, dates, ID-shaped numbers, credit-card-shaped numbers, and any of the supplied `knownNames`.
- Hard-asserts (debug) / throws + logs SEVERE (release) if the sanitized string still contains a known name + a date in the same payload — that combination is forbidden by the medical / child-safety policy.

A future PR will add a custom-lint rule that fails the build if any new call site of `aiClient.chat()` / `aiClient.embed()` / `Gemini.generateContent()` doesn't pass through one of `PiiSanitizer.sanitize*` first. Until then it's enforced by review — VAULT will block.

### 3. Audit log for medical data reads

`public.vault_audit_access(...)` is the canonical entry point for recording any read of lab work, period tracking, or wearable data. Detailed handoffs live in:
- `.oxbar/handoffs/VAULT-to-LABKIT.md`
- `.oxbar/handoffs/VAULT-to-PERIODS-FORGE.md`
- `.oxbar/handoffs/VAULT-to-WEARABLE-HUB.md`

If your work touches any of the medical-data tables those agents own and you somehow end up reading their data without going through their public API, you must call `vault_audit_access` yourself.

## How to react if VAULT blocks your PR

1. Read the failing job's log — the failure messages are written for humans.
2. If the fix is obvious (replace a dep, add an `ENABLE ROW LEVEL SECURITY`), do it and push.
3. If you genuinely think VAULT is wrong — for example pub.dev mis-tagged a license, or a table really shouldn't have RLS — leave a comment on the PR with the specific reasoning. VAULT (or a human reviewer) will adjust the workflow allowlist or grant the exemption.
4. **Do not** disable VAULT's checks, edit `vault.yml` to skip a job, or merge with the check failing. If you do, OXBAR will revert and your work goes back to `BLOCKED — VAULT bypass attempted`.

## Caveats

- VAULT's checks are intentionally fast (gitleaks ~10s, license scan ~1m, RLS validation ~5s). If they're slow on your PR, that's a real signal — investigate.
- The license scanner uses pub.dev's API. If pub.dev is down, the scanner soft-fails on `UNKNOWN`. VAULT tracks unknowns and tightens the policy as the catalog stabilizes.
- The RLS validator only checks NEWLY-ADDED migration files in the PR diff. Existing tables are not re-checked. (We assume merged migrations are correct; if they're not, that's a backfill task, not a per-PR check.)

## Related
- `SECURITY.md` (repo root) — public security posture
- `COORDINATION_PROTOCOL.md` — re-read the SECRETS HANDLING and LICENSE DISCIPLINE sections
- `.oxbar/agent-status/VAULT.md` — VAULT's live status, including any active alerts and open questions
