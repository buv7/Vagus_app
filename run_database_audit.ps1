# VAGUS App - Database Audit Runner (PowerShell)
# This script runs the database audit against the live Supabase database

Write-Host "================================" -ForegroundColor Yellow
Write-Host "VAGUS Database Audit Runner" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow
Write-Host ""

# Database connection string
$DbUrl = "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

Write-Host "Checking for database tools..." -ForegroundColor Yellow

# Check for psql
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue

if ($psqlPath) {
    Write-Host "✅ psql found - Using PostgreSQL client" -ForegroundColor Green

    Write-Host "`nRunning database audit..." -ForegroundColor Yellow

    try {
        psql $DbUrl -f database_audit.sql -o database_audit_results.txt

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Audit completed successfully!" -ForegroundColor Green
            Write-Host "Results saved to: database_audit_results.txt"
        } else {
            Write-Host "❌ Audit failed - check connection and credentials" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "❌ Error running psql: $_" -ForegroundColor Red
        exit 1
    }
}
# Check for docker
elseif (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "⚠️  psql not found, trying Docker..." -ForegroundColor Yellow

    try {
        Get-Content database_audit.sql | docker run --rm -i postgres:15 psql $DbUrl > database_audit_results.txt

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Audit completed via Docker!" -ForegroundColor Green
            Write-Host "Results saved to: database_audit_results.txt"
        } else {
            Write-Host "❌ Docker method failed" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "❌ Error running Docker: $_" -ForegroundColor Red
        exit 1
    }
}
# Fallback: Use Supabase Dashboard
else {
    Write-Host "❌ No database client found (psql or Docker)" -ForegroundColor Red
    Write-Host ""
    Write-Host "MANUAL AUDIT INSTRUCTIONS:" -ForegroundColor Yellow
    Write-Host "1. Open Supabase Dashboard: https://kydrpnrmqbedjflklgue.supabase.co"
    Write-Host "2. Navigate to: SQL Editor"
    Write-Host "3. Copy contents of database_audit.sql"
    Write-Host "4. Paste and run in SQL Editor"
    Write-Host "5. Save results to database_audit_results.txt"
    Write-Host ""

    # Still extract code tables for comparison
    Write-Host "Extracting tables from Dart code..." -ForegroundColor Yellow

    Get-ChildItem -Path lib -Recurse -Filter *.dart |
        Select-String -Pattern "\.from\('([^']+)'\)" |
        ForEach-Object { $_.Matches.Groups[1].Value } |
        Sort-Object -Unique |
        Out-File -FilePath code_tables.txt -Encoding UTF8

    $codeTableCount = (Get-Content code_tables.txt).Count
    Write-Host "✅ Found $codeTableCount tables referenced in code" -ForegroundColor Green
    Write-Host "Saved to: code_tables.txt"

    exit 1
}

Write-Host ""
Write-Host "================================" -ForegroundColor Yellow
Write-Host "Generating comparison report..." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow

# Extract table list from code
Write-Host "`nExtracting tables from Dart code..." -ForegroundColor Yellow

Get-ChildItem -Path lib -Recurse -Filter *.dart |
    Select-String -Pattern "\.from\('([^']+)'\)" |
    ForEach-Object { $_.Matches.Groups[1].Value } |
    Sort-Object -Unique |
    Out-File -FilePath code_tables.txt -Encoding UTF8

$codeTableCount = (Get-Content code_tables.txt).Count
Write-Host "✅ Found $codeTableCount tables referenced in code" -ForegroundColor Green

# Parse database tables from audit results
if (Test-Path database_audit_results.txt) {
    Write-Host "`nParsing database results..." -ForegroundColor Yellow

    # Extract table names from the audit results
    # This will need adjustment based on actual output format
    $content = Get-Content database_audit_results.txt -Raw

    # Try to extract table list (adjust pattern as needed)
    $tableSection = $content -split "List all tables"
    if ($tableSection.Count -gt 1) {
        $tableLines = $tableSection[1] -split "`n" |
            Select-Object -Skip 3 |
            Where-Object { $_ -match '\S' -and $_ -notmatch '---' -and $_ -notmatch 'rows?\)' } |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }

        $tableLines | Out-File -FilePath db_tables.txt -Encoding UTF8

        $dbTableCount = (Get-Content db_tables.txt).Count
        Write-Host "✅ Found $dbTableCount tables in database" -ForegroundColor Green

        # Compare
        Write-Host "`nComparing code vs database..." -ForegroundColor Yellow

        $codeTables = Get-Content code_tables.txt
        $dbTables = Get-Content db_tables.txt

        $missingTables = Compare-Object $codeTables $dbTables |
            Where-Object { $_.SideIndicator -eq '<=' } |
            Select-Object -ExpandProperty InputObject

        $unusedTables = Compare-Object $codeTables $dbTables |
            Where-Object { $_.SideIndicator -eq '=>' } |
            Select-Object -ExpandProperty InputObject

        $missingTables | Out-File -FilePath missing_tables.txt -Encoding UTF8
        $unusedTables | Out-File -FilePath unused_tables.txt -Encoding UTF8

        Write-Host ""
        Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
        Write-Host "Tables in code:     $codeTableCount"
        Write-Host "Tables in database: $dbTableCount"
        Write-Host "Missing tables:     $($missingTables.Count)" -ForegroundColor $(if ($missingTables.Count -gt 0) { 'Red' } else { 'Green' })
        Write-Host "Unused tables:      $($unusedTables.Count)" -ForegroundColor Yellow

        if ($missingTables.Count -gt 0) {
            Write-Host "`n❌ Missing Tables (Code expects but DB lacks):" -ForegroundColor Red
            $missingTables | Select-Object -First 20 | ForEach-Object { Write-Host "   - $_" }
            if ($missingTables.Count -gt 20) {
                Write-Host "   ... and $($missingTables.Count - 20) more"
            }
        }

        if ($unusedTables.Count -gt 0) {
            Write-Host "`nUnused Tables (DB has but code doesn't reference):" -ForegroundColor Yellow
            $unusedTables | Select-Object -First 10 | ForEach-Object { Write-Host "   - $_" }
            if ($unusedTables.Count -gt 10) {
                Write-Host "   ... and $($unusedTables.Count - 10) more"
            }
        }
    }
}

Write-Host ""
Write-Host "✅ Audit complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Generated files:"
Write-Host "  - database_audit.sql           (Audit queries)"
Write-Host "  - database_audit_results.txt   (Full results)"
Write-Host "  - code_tables.txt              (Tables from Dart code)"
Write-Host "  - db_tables.txt                (Tables from database)"
Write-Host "  - missing_tables.txt           (Tables missing in DB)"
Write-Host "  - unused_tables.txt            (Tables not used in code)"
Write-Host ""
Write-Host "Next: Review database_audit_results.txt for detailed findings" -ForegroundColor Yellow
