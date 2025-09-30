# PowerShell script to set up Supabase MCP for Claude Code
Write-Host "Setting up Supabase MCP for Claude Code..." -ForegroundColor Cyan

# Define the Claude config directory
$claudeConfigDir = "$env:APPDATA\Claude"
$claudeConfigFile = "$claudeConfigDir\claude_desktop_config.json"

# Create the directory if it doesn't exist
if (!(Test-Path $claudeConfigDir)) {
    Write-Host "Creating Claude config directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $claudeConfigDir -Force
}

# Read the MCP config from the current directory
$mcpConfigPath = ".\claude-mcp-config.json"
if (Test-Path $mcpConfigPath) {
    Write-Host "Reading MCP configuration..." -ForegroundColor Green
    $mcpConfig = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json

    # Check if Claude config already exists
    if (Test-Path $claudeConfigFile) {
        Write-Host "Updating existing Claude config..." -ForegroundColor Yellow
        $existingConfig = Get-Content $claudeConfigFile -Raw | ConvertFrom-Json
        $existingConfig.mcpServers = $mcpConfig.mcpServers
        $finalConfig = $existingConfig
    } else {
        Write-Host "Creating new Claude config..." -ForegroundColor Green
        $finalConfig = $mcpConfig
    }

    # Write the configuration
    $finalConfig | ConvertTo-Json -Depth 10 | Set-Content $claudeConfigFile -Encoding UTF8

    Write-Host "MCP configuration installed successfully!" -ForegroundColor Green
    Write-Host "Config location: $claudeConfigFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please restart Claude Code to activate the MCP connection." -ForegroundColor Yellow
    Write-Host "After restart, test with: @supabase list projects" -ForegroundColor Magenta

} else {
    Write-Host "Could not find claude-mcp-config.json in current directory" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps after restart:" -ForegroundColor Cyan
Write-Host "1. Test connection: @supabase list projects" -ForegroundColor White
Write-Host "2. View tables: @supabase list tables" -ForegroundColor White
Write-Host "3. Fix database schema automatically" -ForegroundColor White