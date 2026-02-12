# OpenTyrian WASM

This repository is being ported to WebAssembly for browser play.

WASM builds now use CMake+Ninja. The legacy `Makefile` remains for native workflows.

## Current Status

Current state:

1. Build environment/pipeline: working
- Added `CMakeLists.txt` with wasm target settings.
- Added `build-wasm.ps1` (Windows, emsdk + `emcmake` + Ninja).
- Added `Dockerfile.wasm` and `build-was-docker.sh` for containerized Linux builds.
- Build scripts now use CMake+Ninja (`emcmake cmake` + `emmake cmake --build`) aligned with `hw-wasm`.
- Build reruns auto-clean stale/incompatible CMake cache metadata.

2. Graphics to web canvas/WebGL backend: working
- Added wasm shell template at `wasm/shell.html` with full-window canvas.
- Engine output targets browser html artifact (`opentyrian.html`) through Emscripten.
- Disabled hidden-window behavior for wasm.
- Enabled Asyncify to keep browser rendering responsive across blocking waits.

3. Sound to browser audio model: working
- Added first-gesture audio unlock hook in `wasm/shell.html`.
- Core in-engine SDL audio code remains unchanged for initial MVP.
- Confirmed audio and video output in browser.

4. Persistence (cfg/saves): working baseline
- Added IDBFS mount/sync in `wasm/shell.html` at `/persist`.
- WASM user directory now points to `/persist/opentyrian`.
- Startup warning noise for missing cfg/sav files is reduced for wasm first-run.

## Added Files

- `build-wasm.ps1`
- `build-was-docker.sh`
- `Dockerfile.wasm`
- `wasm/shell.html`
- `README-WASM.md` (this file)

## Build (Windows)

Prereqs:
- emsdk installed (default lookup: `$env:EMSDK` or `%USERPROFILE%\\emsdk`)
- CMake
- Ninja
- Optional local tool path overrides:
  - `-EmsdkRoot` (emsdk location)
  - `-LLVMBin` (default: `C:\Program Files\LLVM\bin`)

Command:

```powershell
.\build-wasm.ps1
```

Explicit path example:

```powershell
.\build-wasm.ps1 -EmsdkRoot C:\Users\andre\emsdk -LLVMBin "C:\Program Files\LLVM\bin"
```

Debug build:

```powershell
.\build-wasm.ps1 -Debug
```

Cleanup build directory (keep only `bin/` runtime files):

```powershell
.\build-wasm.ps1 -Build:$false -CleanupBuild
# or
.\cleanup-wasm-build.ps1
```

Output location:
- `build/wasm/bin/opentyrian.html`

## Build (Docker/Linux)

```bash
./build-was-docker.sh
```

Notes:
- Docker builds compile in a container-local temp build directory and then copy artifacts back to host `build/wasm/bin`.
- This avoids bind-mount filesystem issues (missing `.d` files / temp rename failures) seen on some host+Docker combinations.

Debug build:

```bash
BUILD_TYPE=Debug ./build-was-docker.sh
```

Clean rebuild in container:

```bash
CLEAN=1 ./build-was-docker.sh
```

Cleanup host build directory (keep only `bin/` runtime files):

```bash
CLEANUP_BUILD=1 ./build-was-docker.sh
# or cleanup only (no build)
CLEANUP_BUILD_ONLY=1 ./build-was-docker.sh
# or
./cleanup-wasm-build.sh
```

Output location:
- `build/wasm/bin/opentyrian.html`

## Run Locally

Serve `build/wasm/bin` with any static web server and open `opentyrian.html`.

Helper scripts:

```bat
serve.bat
serve.bat 8080 build\wasm\bin
```

```bash
./serve.sh
./serve.sh 8080 build/wasm/bin
```

Example:

```bash
cd build/wasm/bin
python3 -m http.server 8080
```

Then open `http://localhost:8080/opentyrian.html`.

## Known Gaps

- SDL still logs a non-fatal warning on startup:
  - `emscripten_set_main_loop_timing: ... main loop does not exist`
- Long-term main-loop refactor to `emscripten_set_main_loop` is still open.
- Keyboard/mouse browser-specific remap policy is not finished.
