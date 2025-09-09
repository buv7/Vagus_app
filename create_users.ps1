# PowerShell script to create all test users via Supabase Auth API
$supabaseUrl = "https://kydrpnrmqbedjflklgue.supabase.co"
$serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDIyNTE4MCwiZXhwIjoyMDY5ODAxMTgwfQ.YourServiceKeyHere"

# Test accounts to create
$accounts = @(
    @{email="admin@vagus.com"; password="admin12"; role="admin"},
    @{email="client@vagus.com"; password="client12"; role="client"},
    @{email="client2@vagus.com"; password="client12"; role="client"},
    @{email="coach@vagus.com"; password="coach12"; role="coach"}
)

Write-Host "Creating test accounts for Vagus App..." -ForegroundColor Green

foreach ($account in $accounts) {
    Write-Host "Creating account: $($account.email)" -ForegroundColor Yellow
    
    try {
        # Create user via Supabase Auth API
        $body = @{
            email = $account.email
            password = $account.password
            email_confirm = $true
        } | ConvertTo-Json
        
        $headers = @{
            "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "$supabaseUrl/auth/v1/admin/users" -Method POST -Body $body -Headers $headers
        
        Write-Host "✅ Successfully created: $($account.email)" -ForegroundColor Green
        Write-Host "   User ID: $($response.id)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "❌ Failed to create $($account.email): $($_.Exception.Message)" -ForegroundColor Red
        
        # If user already exists, that's okay
        if ($_.Exception.Message -like "*already registered*" -or $_.Exception.Message -like "*already exists*") {
            Write-Host "   User already exists, continuing..." -ForegroundColor Yellow
        }
    }
}

Write-Host "`nAll accounts created! Now run the SQL script to set up profiles." -ForegroundColor Green
Write-Host "Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/sql" -ForegroundColor Cyan
Write-Host "Copy and run the contents of 'create_all_test_accounts.sql'" -ForegroundColor Cyan
