# PowerShell Script to Execute Full Name Migration
# This script runs the migration to add full_name column to profiles table

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "remote",  # "local" or "remote"

    [Parameter(Mandatory=$false)]
    [string]$Password = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FULL_NAME COLUMN MIGRATION SCRIPT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Migration file path
$migrationFile = "supabase\migrations\20251002150000_add_full_name_to_profiles.sql"

# Check if migration file exists
if (-not (Test-Path $migrationFile)) {
    Write-Host "ERROR: Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Migration file found: $migrationFile" -ForegroundColor Green
Write-Host ""

if ($Environment -eq "local") {
    Write-Host "Applying migration to LOCAL Supabase instance..." -ForegroundColor Yellow
    Write-Host ""

    # Check if Supabase is running locally
    $supabaseStatus = supabase status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Local Supabase not running. Starting..." -ForegroundColor Yellow
        supabase start
    }

    # Apply migration
    Write-Host "Running migration..." -ForegroundColor Cyan
    supabase migration up

} elseif ($Environment -eq "remote") {
    Write-Host "Applying migration to REMOTE Supabase instance..." -ForegroundColor Yellow
    Write-Host "Project: kydrpnrmqbedjflklgue" -ForegroundColor Yellow
    Write-Host ""

    # Option 1: Using Supabase CLI (recommended)
    Write-Host "Option 1: Using Supabase CLI" -ForegroundColor Cyan
    Write-Host "Run the following commands:" -ForegroundColor White
    Write-Host ""
    Write-Host "  supabase link --project-ref kydrpnrmqbedjflklgue" -ForegroundColor Green
    Write-Host "  supabase db push" -ForegroundColor Green
    Write-Host ""

    # Option 2: Using psql (if available)
    Write-Host "Option 2: Using psql (PostgreSQL CLI)" -ForegroundColor Cyan
    if ($Password -eq "") {
        Write-Host "Password not provided. You'll need to enter it when prompted." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Run this command:" -ForegroundColor White
        Write-Host ""
        Write-Host "  psql ""postgresql://postgres.kydrpnrmqbedjflklgue:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"" -f $migrationFile" -ForegroundColor Green
    } else {
        $connectionString = "postgresql://postgres.kydrpnrmqbedjflklgue:$Password@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

        # Check if psql is available
        $psqlAvailable = Get-Command psql -ErrorAction SilentlyContinue
        if ($psqlAvailable) {
            Write-Host "psql found. Executing migration..." -ForegroundColor Green
            Write-Host ""

            # Execute the migration
            $env:PGPASSWORD = $Password
            psql $connectionString -f $migrationFile
            Remove-Item Env:\PGPASSWORD

            Write-Host ""
            Write-Host "Migration execution completed!" -ForegroundColor Green
        } else {
            Write-Host "psql not found in PATH." -ForegroundColor Red
            Write-Host "Please install PostgreSQL client or use Supabase Dashboard." -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "Option 3: Using Supabase Dashboard" -ForegroundColor Cyan
    Write-Host "1. Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/sql" -ForegroundColor White
    Write-Host "2. Copy contents of: $migrationFile" -ForegroundColor White
    Write-Host "3. Paste into SQL Editor" -ForegroundColor White
    Write-Host "4. Click 'Run'" -ForegroundColor White

} else {
    Write-Host "ERROR: Invalid environment. Use 'local' or 'remote'" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION INFORMATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Migration: 20251002150000_add_full_name_to_profiles.sql" -ForegroundColor White
Write-Host "Purpose: Add full_name column to profiles table" -ForegroundColor White
Write-Host ""
Write-Host "Changes:" -ForegroundColor White
Write-Host "  - Adds full_name TEXT column (nullable)" -ForegroundColor Gray
Write-Host "  - Migrates data from 'name' to 'full_name'" -ForegroundColor Gray
Write-Host "  - Creates search index on full_name" -ForegroundColor Gray
Write-Host "  - Provides migration statistics" -ForegroundColor Gray
Write-Host ""
Write-Host "For detailed documentation, see:" -ForegroundColor White
Write-Host "  supabase\migrations\README_FULL_NAME_MIGRATION.md" -ForegroundColor Green
Write-Host ""
