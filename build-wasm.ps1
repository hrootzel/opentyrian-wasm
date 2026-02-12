param(
  [string]$BuildDir = "build/wasm",
  [string]$EmsdkRoot = "",
  [string]$LLVMBin = "C:\\Program Files\\LLVM\\bin",
  [string]$EmsdkVersion = "5.0.0",
  [ValidateSet("Debug","Release","RelWithDebInfo")]
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

function Normalize-CMakePath([string]$Path) {
  if (-not $Path) { return "" }
  return ($Path.Trim() -replace "\\", "/").ToLowerInvariant()
}

function Resolve-EmsdkRoot {
  if ($EmsdkRoot -and (Test-Path $EmsdkRoot)) { return $EmsdkRoot }
  if ($env:EMSDK -and (Test-Path $env:EMSDK)) { return $env:EMSDK }
  $candidate = Join-Path $env:USERPROFILE "emsdk"
  if (Test-Path $candidate) { return $candidate }
  throw "EMSDK not found. Set -EmsdkRoot or EMSDK env var."
}

function Resolve-Ninja {
  $localAppData = $env:LOCALAPPDATA
  $candidates = @()
  if ($localAppData) {
    $candidates += "$localAppData\\Microsoft\\WinGet\\Links\\ninja.exe"
  }
  $candidates += "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\Common7\\IDE\\CommonExtensions\\Microsoft\\CMake\\Ninja\\ninja.exe"
  foreach ($c in $candidates) {
    if (Test-Path $c) { return $c }
  }
  $cmd = Get-Command ninja -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  throw "ninja.exe not found. Install Ninja (winget install Ninja-build.Ninja)."
}

function Prepend-Path([string]$PathPart) {
  if (-not $PathPart) { return }
  if (-not (Test-Path $PathPart)) { return }
  $resolved = (Resolve-Path $PathPart).Path
  $parts = @($env:PATH -split ';' | Where-Object { $_ -and ($_ -ne $resolved) })
  $env:PATH = $resolved + ";" + ($parts -join ';')
}

$emsdk = Resolve-EmsdkRoot
$ninja = Resolve-Ninja
$env:EMSDK = $emsdk

Prepend-Path (Split-Path $ninja)
Prepend-Path $LLVMBin

Push-Location $emsdk
& ".\\emsdk" install $EmsdkVersion | Out-Null
& ".\\emsdk" activate $EmsdkVersion | Out-Null
Pop-Location

& "$emsdk\\emsdk_env.ps1" | Out-Null

if ($Clean -and (Test-Path $BuildDir)) {
  Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$repoRoot = (Resolve-Path ".").Path
$buildDirFull = (Resolve-Path $BuildDir).Path
$cacheFile = Join-Path $buildDirFull "CMakeCache.txt"
if (Test-Path $cacheFile) {
  $cacheText = Get-Content -Raw $cacheFile
  $cacheSourceMatch = [regex]::Match($cacheText, "(?m)^CMAKE_HOME_DIRECTORY:INTERNAL=(.+)$")
  $cacheBuildMatch = [regex]::Match($cacheText, "(?m)^CMAKE_CACHEFILE_DIR:INTERNAL=(.+)$")
  $cacheSource = if ($cacheSourceMatch.Success) { $cacheSourceMatch.Groups[1].Value } else { "" }
  $cacheBuild = if ($cacheBuildMatch.Success) { $cacheBuildMatch.Groups[1].Value } else { "" }

  $isSourceMismatch = (Normalize-CMakePath $cacheSource) -ne (Normalize-CMakePath $repoRoot)
  $isBuildMismatch = (Normalize-CMakePath $cacheBuild) -ne (Normalize-CMakePath $buildDirFull)

  if ($isSourceMismatch -or $isBuildMismatch) {
    Write-Host "Detected stale/incompatible CMake cache in $BuildDir; cleaning CMake metadata."
    Remove-Item -Force $cacheFile
    $cmakeFilesDir = Join-Path $buildDirFull "CMakeFiles"
    if (Test-Path $cmakeFilesDir) {
      Remove-Item -Recurse -Force $cmakeFilesDir
    }
  }
}

$cmakeArgs = @(
  "-S", $repoRoot,
  "-B", $buildDirFull,
  "-G", "Ninja",
  "-DCMAKE_MAKE_PROGRAM=$ninja",
  "-DCMAKE_BUILD_TYPE=$Config",
  "-DWITH_NETWORK=OFF"
)

emcmake cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) {
  throw "Configure failed."
}

if ($Build) {
  Write-Host "Building OpenTyrian WASM ($Config) in $BuildDir..."
  emmake cmake --build $BuildDir -j
  if ($LASTEXITCODE -ne 0) {
    throw "WASM build failed."
  }

  $binDir = Join-Path $buildDirFull "bin"
  $htmlPath = Join-Path $binDir "opentyrian.html"
  if (-not (Test-Path $htmlPath)) {
    throw "Expected output missing: $htmlPath"
  }

  Write-Host "Build complete."
  Write-Host "Output: $binDir"
  Write-Host "Run a static server from $binDir and open opentyrian.html"
} else {
  Write-Host "Configured in $BuildDir. Next: emmake cmake --build $BuildDir -j"
}
