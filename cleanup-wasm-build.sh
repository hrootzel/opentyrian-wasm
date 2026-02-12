#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build/wasm}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR_FULL="${ROOT_DIR}/${BUILD_DIR}"
BIN_DIR="${BUILD_DIR_FULL}/bin"

if [[ ! -d "${BIN_DIR}" ]]; then
  echo "Build bin directory not found: ${BIN_DIR}" >&2
  exit 1
fi

find "${BUILD_DIR_FULL}" -mindepth 1 -maxdepth 1 ! -name "bin" -exec rm -rf {} +

echo "Cleanup complete. Kept runtime files in ${BIN_DIR}"

