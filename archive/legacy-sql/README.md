# archive/legacy-sql/

Frozen snapshot of 43 ad-hoc SQL fix / diagnostic scripts that used to live at the
repo root (`fix_*.sql`, `check_*.sql`, `debug_*.sql`, `diagnose_*.sql`,
`emergency_fix.sql`, `master_database_fix.sql`, etc.).

These were never part of the migration sequence in `supabase/migrations/` and
predate the current OXBAR-managed schema flow. They are kept here for forensic
reference only — they may reference dropped tables, obsolete column names, or
hand-written DDL that contradicts the current schema.

## Archive policy

- **Authoritative source of truth** for the database schema is
  `supabase/migrations/` (and what the live Supabase project reflects).
- **Do not run** anything in this directory against production or staging.
- **Do not add** new files here. New schema work goes through a proper migration
  in `supabase/migrations/YYYYMMDDHHMMSS_<author>_<short>.sql` (idempotent + with
  a rollback comment block) and a PR review per `COORDINATION_PROTOCOL.md`.
- If you need a query for ad-hoc inspection, use `supabase/queries/` or run it
  directly via the Supabase MCP / dashboard — don't commit one-off fix scripts
  to the repo.

## Why not just delete

We keep the history because a few of these scripts encode constraints, RLS
policies, and view definitions that may not yet exist in the migration sequence.
If you find a missing piece in production while building a feature, search this
directory for prior attempts before re-deriving from scratch — but always port
the fix forward as a proper migration, never re-run from here.

Archived: 2026-04-27 by KEEL (agent/keel-cleanup).
