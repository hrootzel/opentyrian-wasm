# OpenTyrian WASM (Work In Progress)

This repository is being ported to WebAssembly for browser play.

WASM builds now use CMake+Ninja. The legacy `Makefile` remains for native workflows.

## Current Status

Progress against the first three implementation steps:

1. Build environment/pipeline: started
- Added `CMakeLists.txt` with wasm target settings.
- Added `build-wasm.ps1` (Windows, emsdk + `emcmake` + Ninja).
- Added `Dockerfile.wasm` and `build-was-docker.sh` for containerized Linux builds.
- Build scripts now use CMake+Ninja (`emcmake cmake` + `emmake cmake --build`) aligned with `hw-wasm`.

2. Graphics to web canvas/WebGL backend: started
- Added wasm shell template at `wasm/shell.html` with full-window canvas.
- Engine output targets browser html artifact (`opentyrian.html`) through Emscripten.

3. Sound to browser audio model: started
- Added first-gesture audio unlock hook in `wasm/shell.html`.
- Core in-engine SDL audio code remains unchanged for initial MVP.

## Added Files

- `build-wasm.ps1`
- `build-was-docker.sh`
- `Dockerfile.wasm`
- `wasm/shell.html`
- `wasm-port-plan.md`
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

Output location:
- `build/wasm/bin/opentyrian.html`

## Build (Docker/Linux)

```bash
./build-was-docker.sh
```

Debug build:

```bash
BUILD_TYPE=Debug ./build-was-docker.sh
```

Clean rebuild in container:

```bash
CLEAN=1 ./build-was-docker.sh
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

- Build scripts are initial scaffolding and not yet verified end-to-end in this repo.
- Main-loop/browser-yield behavior still needs hardening.
- Save/config persistence is not yet mapped to IDBFS.
- Keyboard/mouse browser-specific remap policy is not finished.

## Tracking

Detailed plan and progress live in `wasm-port-plan.md`.
