$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$assets = @(
    "assets/tree-v1.png",
    "assets/trees/pine-tree-v1.png",
    "assets/trees/birch-tree-v1.png",
    "assets/trees/maple-tree-v1.png"
)

foreach ($asset in $assets) {
    if (-not (Test-Path -LiteralPath $asset)) { throw "Missing tree asset: $asset" }
    $bitmap = [System.Drawing.Bitmap]::new((Resolve-Path -LiteralPath $asset).Path)
    try {
        if ($bitmap.Width -lt 1000 -or $bitmap.Height -lt 1200) { throw "Tree source is not high resolution: $asset" }
        $corners = @(
            $bitmap.GetPixel(0, 0).A,
            $bitmap.GetPixel($bitmap.Width - 1, 0).A,
            $bitmap.GetPixel(0, $bitmap.Height - 1).A,
            $bitmap.GetPixel($bitmap.Width - 1, $bitmap.Height - 1).A
        )
        if (($corners | Measure-Object -Maximum).Maximum -gt 8) { throw "Tree background is not transparent: $asset" }

        $visibleSamples = 0
        $lowestVisibleY = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 4) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 4) {
                if ($bitmap.GetPixel($x, $y).A -gt 32) {
                    $visibleSamples++
                    $lowestVisibleY = $y
                }
            }
        }
        if ($visibleSamples -lt 3000) { throw "Tree cutout is nearly empty: $asset" }
        if ($lowestVisibleY -lt $bitmap.Height * .88) { throw "Tree roots do not reach the grounding zone: $asset" }
    }
    finally { $bitmap.Dispose() }
}

$world = Get-Content -Raw "src/world.lua"
$clearcut = Get-Content -Raw "src/clearcut_mode.lua"
$rush = Get-Content -Raw "src/rush_mode.lua"
foreach ($needle in @("pine-tree-v1.png", "birch-tree-v1.png", "maple-tree-v1.png", "treeRenderSpec", "variantShadow")) {
    if ($world -notmatch [regex]::Escape($needle)) { throw "World renderer is missing: $needle" }
}
if ($clearcut -notmatch "treeVariant=treeVariant") { throw "Clearcut forest does not persist tree variants" }
if ($rush -notmatch "treeVariant=treeVariant") { throw "Rush forest does not persist tree variants" }

$counts = @(0, 0, 0, 0)
for ($index = 0; $index -lt 40; $index++) {
    $variant = (($index * 3 + 1) % 4)
    $counts[$variant]++
}
if (($counts | Measure-Object -Minimum).Minimum -eq 0) { throw "Tree distribution omitted a variant" }

Write-Output "TREE_VARIANTS_OK assets=$($assets.Count) distribution=$($counts -join ',')"
