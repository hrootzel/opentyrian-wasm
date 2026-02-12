#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8080}"
DIR="${2:-}"

resolve_serve_dir() {
  local candidates=(
    "build/wasm/bin"
    "build/wasm"
  )
  local d
  for d in "${candidates[@]}"; do
    if [[ -f "${d}/opentyrian.html" ]]; then
      printf '%s\n' "${d}"
      return 0
    fi
  done
  printf '.\n'
}

if [[ -z "${DIR}" ]]; then
  DIR="$(resolve_serve_dir)"
fi

if [[ ! -d "${DIR}" ]]; then
  echo "Directory not found: ${DIR}" >&2
  exit 1
fi

FULLDIR="$(cd "${DIR}" && pwd)"
IS_BUILD=1
if [[ "${DIR}" == "." ]]; then
  IS_BUILD=0
fi

echo "OpenTyrian WASM"
echo "=============="
if [[ "${IS_BUILD}" == "1" ]]; then
  echo "Serving build output: ${FULLDIR}"
  echo "Game:     http://localhost:${PORT}/opentyrian.html"
else
  echo "Dev mode (no build output found)"
  echo "Note: Build first with ./build-wasm.ps1"
fi
echo
echo "Press Ctrl+C to stop"

if command -v python3 >/dev/null 2>&1; then
  python3 -m http.server "${PORT}" -d "${FULLDIR}"
else
  python -m http.server "${PORT}" -d "${FULLDIR}"
fi
