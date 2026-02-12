# OpenTyrian WASM Port Plan

This document tracks feasibility, implementation steps, risks, and progress for porting OpenTyrian to WebAssembly for browser runtime.

## Feasibility Summary

Overall feasibility is high for a playable browser build.

Why:
- Rendering already goes through SDL2 software surfaces and SDL renderer output (`src/video.c`).
- Audio already uses SDL audio callback + internal mixer (`src/loudness.c`, `src/nortsong.c`).
- Input is centralized in SDL event handling (`src/keyboard.c`, `src/mouse.c`, `src/joystick.c`).

Main risks:
- Blocking loops and `SDL_Delay` usage are widespread and can conflict with browser main-loop requirements.
- Save/config paths currently use desktop-style directories and need browser persistence mapping.
- Network multiplayer should be excluded for the initial web target.

## Port Strategy

### Step 1: WASM build environment and pipeline

Goal:
- Produce `opentyrian.html/js/wasm/data` from this repo using Emscripten.

Approach:
- Add a wasm build script for Windows (`build-wasm.ps1`).
- Add Linux/container reproducibility (`Dockerfile.wasm`, `build-was-docker.sh`).
- Compile with `WITH_NETWORK=false` for first target.
- Use Emscripten shell template and preload `data/`.

Status:
- In progress.
- Initial scripts and shell are now added.

### Step 2: Graphics path to WebGL-backed canvas

Goal:
- Keep current engine rendering path, display in browser canvas via SDL2/Emscripten.

Approach:
- Keep existing `src/video.c` renderer logic for MVP.
- Let Emscripten SDL backend provide WebGL canvas output.
- Use shell page with full-window canvas and status text.

Status:
- In progress.
- Shell scaffold added in `wasm/shell.html`.

### Step 3: Sound path to browser audio

Goal:
- Keep SDL audio callback engine behavior while satisfying browser audio gesture requirements.

Approach:
- Keep existing audio callback/mixing code unchanged for MVP.
- Add first-user-gesture audio unlock hook in shell (`Module.SDL2.audioContext.resume()`).
- Validate music + SFX after interaction.

Status:
- In progress.
- Audio unlock hook added in `wasm/shell.html`.

## Next Phases (Not started)

### Step 4: Input remap and browser-safe defaults
- Review browser-reserved keys.
- Provide web-safe default bindings while preserving in-game remap support.

### Step 5: Save/config persistence
- Map config/save files to IDBFS-backed writable path.
- Ensure `opentyrian.cfg` and `tyrian.sav` survive reload.

### Step 6: Main loop hardening
- Evaluate Asyncify MVP for blocking waits.
- Long-term: move to explicit frame-driven loop where needed.

### Step 7: Packaging and hosting
- Create static-host layout and simple serve scripts.
- Optional pack splitting if needed.

### Step 8: Validation matrix
- Boot, title, gameplay, audio, input, save/load, fullscreen, resize.

## Decision Log

1. Initial web target excludes networking.
Reason: fastest path to functional single-player web build.

2. Initial graphics/audio approach keeps SDL path intact.
Reason: avoids unnecessary rewrite to raw WebGL/WebAudio APIs.

3. Build scaffold copied from `hw-wasm` and adapted.
Reason: known-good baseline in this environment.
