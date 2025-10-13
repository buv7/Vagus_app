#!/usr/bin/env python3
"""
Apply migration to Supabase database
"""
import psycopg2
import sys
from pathlib import Path

# Database connection string
DB_URL = "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

# Migration file path
MIGRATION_FILE = Path(__file__).parent / "supabase" / "migrations" / "20251002140000_add_missing_tables_and_columns.sql"

def apply_migration():
    """Apply the migration to the database"""
    try:
        print("Connecting to Supabase database...")
        conn = psycopg2.connect(DB_URL)
        conn.autocommit = False
        cursor = conn.cursor()

        print(f"Reading migration file: {MIGRATION_FILE}")
        with open(MIGRATION_FILE, 'r', encoding='utf-8') as f:
            migration_sql = f.read()

        print("Applying migration...")
        cursor.execute(migration_sql)

        print("Committing changes...")
        conn.commit()

        print("\n" + "="*80)
        print("SUCCESS! Migration applied successfully!")
        print("="*80)
        print("\nCreated/Modified:")
        print("  1. calendar_events.event_type column (with index)")
        print("  2. client_feedback table (with RLS policies)")
        print("  3. payments table (with RLS policies)")
        print("  4. coach_feedback_summary view")
        print("  5. coach_payment_summary view")
        print("="*80)

        cursor.close()
        conn.close()

    except psycopg2.Error as e:
        print(f"\nERROR: Database error occurred:")
        print(f"  {e}")
        if conn:
            conn.rollback()
        sys.exit(1)
    except FileNotFoundError:
        print(f"\nERROR: Migration file not found: {MIGRATION_FILE}")
        sys.exit(1)
    except Exception as e:
        print(f"\nERROR: Unexpected error occurred:")
        print(f"  {e}")
        if conn:
            conn.rollback()
        sys.exit(1)

if __name__ == "__main__":
    apply_migration()
