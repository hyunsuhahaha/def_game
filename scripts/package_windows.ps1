param(
    [string]$LoveDir = "C:\Program Files\LOVE",
    [string]$Version = "0.1.0"
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$dist = Join-Path $repo "dist"
$stage = Join-Path $dist "LAST_HAUL-$Version-windows-x64"
$game = Join-Path $dist ".game-$Version"
$loveArchive = Join-Path $dist "LAST_HAUL-$Version.love"
$archiveZip = "$loveArchive.zip"
$zip = Join-Path $dist "LAST_HAUL-$Version-windows-x64.zip"

if (-not (Test-Path -LiteralPath (Join-Path $LoveDir "love.exe"))) {
    throw "LÖVE 11.5 runtime not found: $LoveDir"
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
foreach ($path in @($stage, $game)) {
    $full = [IO.Path]::GetFullPath($path)
    if (-not $full.StartsWith([IO.Path]::GetFullPath($dist) + [IO.Path]::DirectorySeparatorChar)) {
        throw "Refusing to clean path outside dist: $full"
    }
    if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
    New-Item -ItemType Directory -Path $full | Out-Null
}
foreach ($path in @($loveArchive, $archiveZip, $zip)) {
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}

Copy-Item -LiteralPath (Join-Path $repo "main.lua"), (Join-Path $repo "conf.lua") -Destination $game
Copy-Item -LiteralPath (Join-Path $repo "src"), (Join-Path $repo "assets") -Destination $game -Recurse
Set-Content -LiteralPath (Join-Path $game "release.flag") -Value $Version -NoNewline -Encoding ascii

Push-Location $game
try { & tar.exe -a -c -f $archiveZip *; if ($LASTEXITCODE) { throw "Failed to create .love archive" } }
finally { Pop-Location }
Move-Item -LiteralPath $archiveZip -Destination $loveArchive

$runtimeFiles = @("love.dll", "lua51.dll", "mpg123.dll", "msvcp120.dll", "msvcr120.dll", "OpenAL32.dll", "SDL2.dll")
foreach ($name in $runtimeFiles) {
    $source = Join-Path $LoveDir $name
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing LÖVE runtime file: $source" }
    Copy-Item -LiteralPath $source -Destination $stage
}
Copy-Item -LiteralPath (Join-Path $LoveDir "license.txt") -Destination (Join-Path $stage "LOVE-LICENSE.txt")
Copy-Item -LiteralPath (Join-Path $LoveDir "love.exe") -Destination $stage
Copy-Item -LiteralPath $loveArchive -Destination (Join-Path $stage "game.love")

Push-Location $dist
try { & tar.exe -a -c -f $zip (Split-Path $stage -Leaf); if ($LASTEXITCODE) { throw "Failed to create portable zip" } }
finally { Pop-Location }
Remove-Item -LiteralPath $game -Recurse -Force
Write-Host "RELEASE_PACKAGE_OK version=$Version"
Write-Host "Steam content: $stage"
Write-Host 'Steam launch: love.exe game.love'
Write-Host "Archive zip: $zip"
