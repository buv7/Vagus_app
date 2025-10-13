$files = Get-ChildItem -Path "C:\Users\alhas\StudioProjects\vagus_app\lib" -Recurse -Filter "*.dart" | Where-Object { $_.FullName -notlike '*\generated\*' }
$count = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $newContent = $content -replace '\.withOpacity\(', '.withValues(alpha: '

    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        $count++
        Write-Host "Fixed: $($file.Name)"
    }
}

Write-Host "Total files fixed: $count"
