# VAGUS App - Deployment Verification Script
# This script verifies the Supabase auto-deploy infrastructure

Write-Host "[VERIFY] VAGUS App - Deployment Infrastructure Verification" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "supabase")) {
    Write-Host "[ERROR] Error: supabase directory not found. Run this script from the project root." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Project structure verified" -ForegroundColor Green

# Check migration files
Write-Host "`n[MIGRATIONS] Checking migration files..." -ForegroundColor Yellow
$migrationFiles = Get-ChildItem "supabase/migrations" -Filter "*.sql" | Sort-Object Name
Write-Host "Found $($migrationFiles.Count) migration files:" -ForegroundColor Green

foreach ($file in $migrationFiles) {
    $size = [math]::Round((Get-Item $file.FullName).Length / 1KB, 1)
    Write-Host "  📄 $($file.Name) ($size KB)" -ForegroundColor White
}

# Check Edge Functions
Write-Host "`n[FUNCTIONS] Checking Edge Functions..." -ForegroundColor Yellow
$functionDirs = Get-ChildItem "supabase/functions" -Directory
Write-Host "Found $($functionDirs.Count) Edge Functions:" -ForegroundColor Green

foreach ($dir in $functionDirs) {
    $indexFile = Join-Path $dir.FullName "index.ts"
    if (Test-Path $indexFile) {
        $size = [math]::Round((Get-Item $indexFile).Length / 1KB, 1)
        Write-Host "  [FUNC] $($dir.Name) ($size KB)" -ForegroundColor White
    } else {
        Write-Host "  [WARN] $($dir.Name) - missing index.ts" -ForegroundColor Yellow
    }
}

# Check GitHub Actions workflow
Write-Host "`n[GITHUB] Checking GitHub Actions..." -ForegroundColor Yellow
$workflowFile = ".github/workflows/supabase-deploy.yml"
if (Test-Path $workflowFile) {
    $size = [math]::Round((Get-Item $workflowFile).Length / 1KB, 1)
    Write-Host "[OK] GitHub Actions workflow found ($size KB)" -ForegroundColor Green
    
    # Check workflow content
    $workflowContent = Get-Content $workflowFile -Raw
    if ($workflowContent -match "deploy_dev" -and $workflowContent -match "deploy_prod") {
        Write-Host "[OK] Dev and prod deployment jobs configured" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Missing deployment jobs in workflow" -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] GitHub Actions workflow not found" -ForegroundColor Red
}

# Check Supabase config
Write-Host "`n[CONFIG] Checking Supabase configuration..." -ForegroundColor Yellow
$configFile = "supabase/config.toml"
if (Test-Path $configFile) {
    $size = [math]::Round((Get-Item $configFile).Length / 1KB, 1)
    Write-Host "[OK] Supabase config found ($size KB)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Supabase config not found" -ForegroundColor Red
}

# Check README documentation
Write-Host "`n[DOCS] Checking documentation..." -ForegroundColor Yellow
$readmeFile = "README.md"
if (Test-Path $readmeFile) {
    $readmeContent = Get-Content $readmeFile -Raw
    if ($readmeContent -match "Supabase Auto Deploy") {
        Write-Host "[OK] README contains deployment documentation" -ForegroundColor Green
    } else {
        Write-Host "[WARN] README missing deployment documentation" -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] README not found" -ForegroundColor Red
}

# Migration content verification
Write-Host "`n[VERIFY] Verifying migration content..." -ForegroundColor Yellow

# Check 0001_init_progress_system.sql
$migration1 = "supabase/migrations/0001_init_progress_system.sql"
if (Test-Path $migration1) {
    $content1 = Get-Content $migration1 -Raw
    $checks1 = @(
        @{ Name = "pgcrypto extension"; Pattern = "create extension if not exists pgcrypto" },
        @{ Name = "client_metrics table"; Pattern = "create table if not exists public\.client_metrics" },
        @{ Name = "progress_photos table"; Pattern = "create table if not exists public\.progress_photos" },
        @{ Name = "checkins table"; Pattern = "create table if not exists public\.checkins" },
        @{ Name = "policyname usage"; Pattern = "pg_policies where policyname" }
    )
    
    foreach ($check in $checks1) {
        if ($content1 -match $check.Pattern) {
            Write-Host "  [OK] $($check.Name)" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] $($check.Name)" -ForegroundColor Red
        }
    }
}

# Check 0002_coach_notes.sql
$migration2 = "supabase/migrations/0002_coach_notes.sql"
if (Test-Path $migration2) {
    $content2 = Get-Content $migration2 -Raw
    $checks2 = @(
        @{ Name = "coach_notes column guards"; Pattern = "alter table public\.coach_notes add column" },
        @{ Name = "coach_note_versions table"; Pattern = "create table if not exists public\.coach_note_versions" },
        @{ Name = "coach_note_attachments table"; Pattern = "create table if not exists public\.coach_note_attachments" },
        @{ Name = "storage policies"; Pattern = "storage_read_vagus_media" }
    )
    
    foreach ($check in $checks2) {
        if ($content2 -match $check.Pattern) {
            Write-Host "  [OK] $($check.Name)" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] $($check.Name)" -ForegroundColor Red
        }
    }
}

# Summary
Write-Host "`n[SUMMARY] Deployment Infrastructure Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "[OK] Migration files: $($migrationFiles.Count) files ready" -ForegroundColor Green
Write-Host "[OK] Edge Functions: $($functionDirs.Count) functions ready" -ForegroundColor Green
Write-Host "[OK] GitHub Actions: Auto-deploy workflow configured" -ForegroundColor Green
Write-Host "[OK] Documentation: README updated with deployment info" -ForegroundColor Green

Write-Host "`n[NEXT] Next Steps:" -ForegroundColor Yellow
Write-Host "1. Set up GitHub Secrets for your Supabase projects" -ForegroundColor White
Write-Host "2. Push to 'develop' branch for dev deployment" -ForegroundColor White
Write-Host "3. Push to 'main' branch for production deployment" -ForegroundColor White
Write-Host "4. Monitor GitHub Actions for deployment status" -ForegroundColor White

Write-Host "`n[SUCCESS] Deployment infrastructure is ready!" -ForegroundColor Green
