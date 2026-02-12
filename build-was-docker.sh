#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-opentyrian-wasm-builder:latest}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-${ROOT_DIR}/Dockerfile.wasm}"
BUILD_DIR="${BUILD_DIR:-build/wasm}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
CLEAN="${CLEAN:-0}"

mkdir -p "${ROOT_DIR}/build"

docker build -f "${DOCKERFILE_PATH}" -t "${IMAGE_NAME}" "${ROOT_DIR}"

docker run --rm -t \
  -v "${ROOT_DIR}:/workspace" \
  -v "${ROOT_DIR}/build:/workspace/build" \
  -e BUILD_DIR="${BUILD_DIR}" \
  -e BUILD_TYPE="${BUILD_TYPE}" \
  -e JOBS="${JOBS}" \
  -e CLEAN="${CLEAN}" \
  "${IMAGE_NAME}" \
  bash -lc '
    set -euo pipefail
    source /opt/emsdk/emsdk_env.sh >/dev/null

    build_dir="${BUILD_DIR:-build/wasm}"
    build_type="${BUILD_TYPE:-Release}"
    jobs="${JOBS:-4}"

    if [[ "${CLEAN:-0}" == "1" ]]; then
      rm -rf "${build_dir}"
    fi

    mkdir -p "${build_dir}/bin"
    target="${build_dir}/bin/opentyrian.html"

    cflags="-O3"
    if [[ "${build_type}" == "Debug" ]]; then
      cflags="-O0 -gsource-map"
    fi

    emmake make \
      WITH_NETWORK=false \
      EMSCRIPTEN=true \
      CC=emcc \
      TARGET="${target}" \
      CFLAGS="${cflags}" \
      -j "${jobs}"

    if [[ ! -f "${target}" ]]; then
      echo "Expected output missing: ${target}" >&2
      exit 1
    fi

    echo
    echo "Build complete."
    echo "Output: ${build_dir}/bin"
  '
