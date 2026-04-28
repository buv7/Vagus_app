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

## E-003 · 2026-04-28 · IAP-APPLE · App Store Connect configuration required

**Trigger:** IAP-APPLE cannot create App Store Connect products — this requires human access to the Apple Developer portal and App Store Connect. IAP-APPLE has no API credentials to do this programmatically.

**Actions required from Alhassan** in App Store Connect (appstoreconnect.apple.com) for the Vagus app:

1. **Create a Subscription Group** named `"Coach Tiers"` under the app's In-App Purchases section.

2. **Create two Auto-Renewable Subscriptions** inside that group:
   | Product ID | Display Name | Price | Tier |
   |---|---|---|---|
   | `vagus_pro_monthly` | Vagus Pro | $9.99/mo | 2 |
   | `vagus_ultimate_monthly` | Vagus Ultimate | $19.99/mo | 4 |

3. **Add an Introductory Offer** to both products:
   - Type: Free
   - Duration: 30 days
   - Eligibility: New subscribers only

4. **Add a Sandbox Tester** account (or confirm one already exists) for TestFlight validation. The email can be any Apple ID not associated with a real purchase. Note the credentials here so IAP-APPLE can complete sandbox testing.

5. **Confirm the bundle ID** used in App Store Connect (e.g. `com.vagusapp.vagus` or similar) so IAP-APPLE can verify the product IDs resolve correctly in StoreKit.

**Status:** IAP-APPLE is PENDING on TIER's models (dependency), and PENDING on this App Store Connect setup (human task). Both must be complete before the full integration can be tested. The Dart code and Edge Function can be written without App Store Connect access, but sandbox testing cannot proceed without it.

**No merge blocker:** This escalation does not block the PR being opened — the implementation can be reviewed without sandbox test results. It blocks the VALIDATION section of IAP-APPLE's mission.
