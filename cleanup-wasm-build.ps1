param(
  [string]$BuildDir = "build/wasm"
)

$ErrorActionPreference = "Stop"

$buildDirFull = (Resolve-Path $BuildDir).Path
$binDir = Join-Path $buildDirFull "bin"

if (-not (Test-Path $binDir)) {
  throw "Build bin directory not found: $binDir"
}

Get-ChildItem -Force -LiteralPath $buildDirFull | ForEach-Object {
  if ($_.Name -ieq "bin") { return }
  Remove-Item -Recurse -Force -LiteralPath $_.FullName
}

Write-Host "Cleanup complete. Kept runtime files in $binDir"

