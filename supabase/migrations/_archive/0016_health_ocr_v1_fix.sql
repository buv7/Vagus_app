-- Fix column name conflicts from previous health migration
-- Migration: 0016_health_ocr_v1_fix.sql

-- Drop the old views that reference incorrect column names
DROP VIEW IF EXISTS health_daily_v;
DROP VIEW IF EXISTS sleep_quality_v;

-- Drop the old tables if they exist with the wrong structure
DROP TABLE IF EXISTS health_merges CASCADE;
DROP TABLE IF EXISTS ocr_cardio_logs CASCADE;
DROP TABLE IF EXISTS sleep_segments CASCADE;
DROP TABLE IF EXISTS health_workouts CASCADE;
DROP TABLE IF EXISTS health_samples CASCADE;
DROP TABLE IF EXISTS health_sources CASCADE;

-- The main migration 0017_health_ocr_v1.sql will recreate these tables with the correct structure
