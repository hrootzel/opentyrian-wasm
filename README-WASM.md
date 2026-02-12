# OpenTyrian WASM (Work In Progress)

This repository is being ported to WebAssembly for browser play.

## Current Status

Progress against the first three implementation steps:

1. Build environment/pipeline: started
- Added `build-wasm.ps1` (Windows, emsdk + Emscripten Make build).
- Added `Dockerfile.wasm` and `build-was-docker.sh` for containerized Linux builds.
- Added initial Emscripten mode in `Makefile` (`EMSCRIPTEN=true`, preload `data/`).

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
- `make` in PATH

Command:

```powershell
.\build-wasm.ps1
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
