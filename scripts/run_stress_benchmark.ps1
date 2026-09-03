param(
    [string]$LoveDir = "C:\Program Files\LOVE",
    [int]$Seconds = 20
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$love = Join-Path $LoveDir "love.exe"
if (-not (Test-Path -LiteralPath $love)) { throw "LÖVE runtime not found: $love" }
$save = Join-Path $env:APPDATA "LOVE\last-haul"
$report = Join-Path $save "stress_benchmark.txt"
$errorReport = Join-Path $save "stress_benchmark_error.txt"
foreach ($path in @($report, $errorReport)) {
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}

$oldBenchmark, $oldSeconds = $env:LAST_HAUL_STRESS_BENCHMARK, $env:LAST_HAUL_STRESS_SECONDS
try {
    $env:LAST_HAUL_STRESS_BENCHMARK = "1"
    $env:LAST_HAUL_STRESS_SECONDS = [string][Math]::Max(10, $Seconds)
    $process = Start-Process -FilePath $love -ArgumentList @($repo) -WindowStyle Hidden -Wait -PassThru
    $exit = $process.ExitCode
} finally {
    $env:LAST_HAUL_STRESS_BENCHMARK, $env:LAST_HAUL_STRESS_SECONDS = $oldBenchmark, $oldSeconds
}

if (-not (Test-Path -LiteralPath $report)) {
    if (Test-Path -LiteralPath $errorReport) { Get-Content -LiteralPath $errorReport }
    throw "Benchmark report not found: $report"
}
Get-Content -LiteralPath $report
if ($exit) { throw "Stress benchmark failed its performance threshold" }
