-- MUSIC-PURGE: drop music feature tables
--
-- The in-app music integration (Spotify/SoundCloud deep links) was retired
-- pre-v1. This migration drops the four tables that backed that feature.
-- public.workout_plans is intentionally left alone — it is a real domain
-- table that happens to have been first introduced in 0019_music_v1.sql.
--
-- Idempotent: uses DROP TABLE IF EXISTS. Safe to re-run.
-- Coordinated with VAULT before merge (see .oxbar/agent-status/MUSIC-PURGE.md).

drop table if exists public.workout_music_refs cascade;
drop table if exists public.event_music_refs   cascade;
drop table if exists public.user_music_prefs   cascade;
drop table if exists public.music_links        cascade;

-- Rollback:
--   The original definitions live in supabase/migrations/_archive/0019_music_v1.sql.
--   To revert, copy the four CREATE TABLE blocks (music_links, workout_music_refs,
--   event_music_refs, user_music_prefs), their indexes, and their RLS policies into
--   a new forward migration. Do NOT recreate workout_plans (still in use).
