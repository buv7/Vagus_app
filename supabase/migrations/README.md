# Migrations

The Supabase CLI applies every `<timestamp>_name.sql` file in this directory in order.

## Baseline

On 2026-04-27 we baselined the migration history. All 164 prior migration files were moved to `_archive/` (the CLI ignores subfolders) because the production database had drifted ahead of the tracker — many migrations had been hand-applied through the Supabase dashboard and were never recorded in `supabase_migrations.schema_migrations`. Files that share filenames or timestamps had also accumulated, which caused `supabase db push` to fail with primary-key collisions on every CI run.

The current production schema is the source of truth. New migrations should be added at the top level of this folder with a fresh `<14-digit-timestamp>_descriptive_name.sql`.

## Adding a new migration

1. Create a file like `20260427120000_add_widget_table.sql` here.
2. Open a PR — `Flutter Analyze` runs as a quality gate.
3. Merge to `main` — `.github/workflows/deploy.yml` runs `supabase db push --include-all`, applies your migration, and deploys Edge Functions.

If you ever need to inspect the historical migrations, look in `_archive/`. Do not move them back without first verifying the tracker reflects all of them — otherwise CI will try to re-apply scripts that are already in production.
