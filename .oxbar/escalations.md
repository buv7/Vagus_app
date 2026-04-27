# OXBAR Escalations to Alhassan

> Items blocked on human owner. Alhassan checks once daily.
> Format: timestamp · agent · short title · question/decision needed.
> When resolved, mark `RESOLVED: <date>` and append Alhassan's call.

---

## 2026-04-27 22:35 UTC · MUSIC-PURGE PR #7 · prod data drop approval

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

(non-prod-data parts of PR #7 — code deletions, CHANGELOG — are independent and would be approved/merged in a normal flow.)

