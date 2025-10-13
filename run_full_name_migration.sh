#!/bin/bash

# Bash Script to Execute Full Name Migration
# This script runs the migration to add full_name column to profiles table

set -e  # Exit on error

ENVIRONMENT="${1:-remote}"  # Default to remote
PASSWORD="${2:-}"

echo "========================================"
echo "FULL_NAME COLUMN MIGRATION SCRIPT"
echo "========================================"
echo ""

# Migration file path
MIGRATION_FILE="supabase/migrations/20251002150000_add_full_name_to_profiles.sql"

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "ERROR: Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "✓ Migration file found: $MIGRATION_FILE"
echo ""

if [ "$ENVIRONMENT" == "local" ]; then
    echo "Applying migration to LOCAL Supabase instance..."
    echo ""

    # Check if Supabase is running locally
    if ! supabase status &> /dev/null; then
        echo "Local Supabase not running. Starting..."
        supabase start
    fi

    # Apply migration
    echo "Running migration..."
    supabase migration up

elif [ "$ENVIRONMENT" == "remote" ]; then
    echo "Applying migration to REMOTE Supabase instance..."
    echo "Project: kydrpnrmqbedjflklgue"
    echo ""

    # Option 1: Using Supabase CLI (recommended)
    echo "Option 1: Using Supabase CLI"
    echo "Run the following commands:"
    echo ""
    echo "  supabase link --project-ref kydrpnrmqbedjflklgue"
    echo "  supabase db push"
    echo ""

    # Option 2: Using psql (if available)
    echo "Option 2: Using psql (PostgreSQL CLI)"
    if [ -z "$PASSWORD" ]; then
        echo "Password not provided. You'll need to enter it when prompted."
        echo ""
        echo "Run this command:"
        echo ""
        echo "  psql \"postgresql://postgres.kydrpnrmqbedjflklgue:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:5432/postgres\" -f $MIGRATION_FILE"
    else
        CONNECTION_STRING="postgresql://postgres.kydrpnrmqbedjflklgue:$PASSWORD@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

        # Check if psql is available
        if command -v psql &> /dev/null; then
            echo "psql found. Executing migration..."
            echo ""

            # Execute the migration
            PGPASSWORD="$PASSWORD" psql "$CONNECTION_STRING" -f "$MIGRATION_FILE"

            echo ""
            echo "✓ Migration execution completed!"
        else
            echo "psql not found in PATH."
            echo "Please install PostgreSQL client or use Supabase Dashboard."
        fi
    fi

    echo ""
    echo "Option 3: Using Supabase Dashboard"
    echo "1. Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/sql"
    echo "2. Copy contents of: $MIGRATION_FILE"
    echo "3. Paste into SQL Editor"
    echo "4. Click 'Run'"

else
    echo "ERROR: Invalid environment. Use 'local' or 'remote'"
    exit 1
fi

echo ""
echo "========================================"
echo "MIGRATION INFORMATION"
echo "========================================"
echo "Migration: 20251002150000_add_full_name_to_profiles.sql"
echo "Purpose: Add full_name column to profiles table"
echo ""
echo "Changes:"
echo "  - Adds full_name TEXT column (nullable)"
echo "  - Migrates data from 'name' to 'full_name'"
echo "  - Creates search index on full_name"
echo "  - Provides migration statistics"
echo ""
echo "For detailed documentation, see:"
echo "  supabase/migrations/README_FULL_NAME_MIGRATION.md"
echo ""
