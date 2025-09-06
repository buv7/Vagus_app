# PowerShell script to diagnose the GitHub Actions issue
Write-Host "DIAGNOSING GITHUB ACTIONS ISSUE..." -ForegroundColor Yellow
Write-Host ""

# Check if we have the required files
Write-Host "Checking required files:" -ForegroundColor Cyan
if (Test-Path "complete_production_fix.sql") {
    Write-Host "complete_production_fix.sql exists" -ForegroundColor Green
} else {
    Write-Host "complete_production_fix.sql missing" -ForegroundColor Red
}

if (Test-Path ".github/workflows/supabase-deploy.yml") {
    Write-Host "GitHub workflow exists" -ForegroundColor Green
} else {
    Write-Host "GitHub workflow missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "IMMEDIATE FIX OPTIONS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Manual Database Fix (RECOMMENDED)" -ForegroundColor Green
Write-Host "1. Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue" -ForegroundColor White
Write-Host "2. Click SQL Editor" -ForegroundColor White
Write-Host "3. Copy ALL contents of complete_production_fix.sql" -ForegroundColor White
Write-Host "4. Paste and run it" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: Disable Auto-Deploy Temporarily" -ForegroundColor Yellow
Write-Host "1. Rename .github/workflows/supabase-deploy.yml to .github/workflows/supabase-deploy.yml.disabled" -ForegroundColor White
Write-Host "2. This will stop the failing workflows" -ForegroundColor White
Write-Host ""
Write-Host "Option 3: Use Direct Supabase CLI" -ForegroundColor Cyan
Write-Host "1. We can push directly using the CLI we set up earlier" -ForegroundColor White
Write-Host "2. Bypass GitHub Actions completely" -ForegroundColor White