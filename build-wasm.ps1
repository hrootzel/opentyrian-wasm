param(
  [string]$BuildDir = "build/wasm",
  [string]$EmsdkRoot = "",
  [string]$EmsdkVersion = "5.0.0",
  [ValidateSet("Debug","Release")]
  [string]$Config = "Release",
  [switch]$Debug,
  [switch]$Release,
  [switch]$Clean,
  [switch]$Build = $true,
  [switch]$Rebuild
)

$ErrorActionPreference = "Stop"

if ($Debug -and $Release) {
  throw "Use only one of -Debug or -Release."
}
if ($Debug) { $Config = "Debug" }
if ($Release) { $Config = "Release" }
if ($Rebuild) { $Clean = $true; $Build = $true }

function Resolve-EmsdkRoot {
  if ($EmsdkRoot -and (Test-Path $EmsdkRoot)) { return $EmsdkRoot }
  if ($env:EMSDK -and (Test-Path $env:EMSDK)) { return $env:EMSDK }
  $candidate = Join-Path $env:USERPROFILE "emsdk"
  if (Test-Path $candidate) { return $candidate }
  throw "EMSDK not found. Set -EmsdkRoot or EMSDK env var."
}

$emsdk = Resolve-EmsdkRoot
Push-Location $emsdk
& ".\\emsdk" install $EmsdkVersion | Out-Null
& ".\\emsdk" activate $EmsdkVersion | Out-Null
Pop-Location

& "$emsdk\\emsdk_env.ps1" | Out-Null

if ($Clean -and (Test-Path $BuildDir)) {
  Remove-Item -Recurse -Force $BuildDir
}

$buildDirFull = Join-Path (Resolve-Path ".").Path $BuildDir
$binDir = Join-Path $buildDirFull "bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

$target = Join-Path $binDir "opentyrian.html"
$jobs = [Math]::Max(1, [Environment]::ProcessorCount)

$extraCFlags = if ($Config -eq "Debug") {
  "-O0 -gsource-map"
} else {
  "-O3"
}

$makeArgs = @(
  "WITH_NETWORK=false",
  "EMSCRIPTEN=true",
  "CC=emcc",
  "TARGET=$target",
  "CFLAGS=$extraCFlags"
)

if ($Build) {
  Write-Host "Building OpenTyrian WASM ($Config) into $target"
  emmake make @makeArgs -j $jobs
  if ($LASTEXITCODE -ne 0) {
    throw "WASM build failed."
  }

  Write-Host "Build complete."
  Write-Host "Output: $binDir"
  Write-Host "Run a static server from $binDir and open opentyrian.html"
} else {
  Write-Host "No build requested. Use -Build to compile."
}
