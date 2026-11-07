param(
    [string] $Code = 'code',
    [string] $UserDir = "$env:APPDATA\Code\User",
    [ValidateSet('All', 'Extensions', 'Settings')]
    [string] $Only = 'All'
)

if ($Only -in @('All', 'Extensions')) {
    $extFile = "$PSScriptRoot\extensions.txt"
    if (Test-Path $extFile) {
        $exts = @(Get-Content $extFile | Where-Object { $_.Trim() })
        $failed = @()
        $i = 0
        foreach ($e in $exts) {
            $i++
            Write-Host "[$i/$($exts.Count)] $e"
            & $Code --install-extension $e.Trim() | Out-Null
            if ($LASTEXITCODE -ne 0) { $failed += $e.Trim() }
        }
        Write-Host "Extensions: $($exts.Count) processed, $($failed.Count) failed"
        if ($failed.Count) { $failed | ForEach-Object { Write-Warning "Failed: $_" } }
    }
    else { Write-Warning 'extensions.txt not found, skipping extensions.' }
}

if ($Only -in @('All', 'Settings')) {
    $src = "$PSScriptRoot\vscode-user"
    if (Test-Path $src) {
        $existing = Join-Path $UserDir 'settings.json'
        if (Test-Path $existing) { Copy-Item $existing "$existing.bak" -Force }
        $files = @(Get-ChildItem $src -Recurse -File -Include *.json, *.code-snippets)
        foreach ($f in $files) {
            $rel = $f.FullName.Substring($src.TrimEnd('\').Length).TrimStart('\')
            $target = Join-Path $UserDir $rel
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item $f.FullName $target -Force
        }
        Write-Host "Copied $($files.Count) config files -> $UserDir"
    }
    else { Write-Warning 'vscode-user directory not found, skipping settings.' }
}
