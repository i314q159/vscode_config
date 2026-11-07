param(
    [string] $Code = 'code',
    [string] $UserDir = "$env:APPDATA\Code\User",
    [switch] $WithVersion
)

$cliArgs = @('--list-extensions')
if ($WithVersion) { $cliArgs += '--show-versions' }
$list = & $Code @cliArgs
if ($LASTEXITCODE -ne 0) { throw 'Failed to list extensions. Make sure the code CLI is available.' }
$items = @($list | Where-Object { $_.Trim() } | Sort-Object -Unique)
[IO.File]::WriteAllLines("$PSScriptRoot\extensions.txt", [string[]]$items)
Write-Host "Exported $($items.Count) extensions -> extensions.txt"

if (-not (Test-Path $UserDir)) { throw "User settings directory not found: $UserDir" }
$dest = "$PSScriptRoot\vscode-user"
$skip = @('chatLanguageModels.json', 'tasks.json')
$files = @(
    Get-ChildItem $UserDir -File | Where-Object { $_.Extension -in '.json', '.code-snippets' -and $_.Name -notin $skip }
    foreach ($d in @('snippets', 'profiles')) {
        $p = Join-Path $UserDir $d
        if (Test-Path $p) { Get-ChildItem $p -Recurse -File -Include *.json, *.code-snippets }
    }
) | Where-Object { $_ -and $_.FullName -notmatch '\\globalStorage\\' }

foreach ($f in $files) {
    $rel = $f.FullName.Substring($UserDir.TrimEnd('\').Length).TrimStart('\')
    $target = Join-Path $dest $rel
    New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
    Copy-Item $f.FullName $target -Force
}
Write-Host "Copied $(@($files).Count) config files -> vscode-user\"
Write-Host 'Note: settings.json may contain secrets or local paths; review before committing.'
