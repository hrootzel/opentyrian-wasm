#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-opentyrian-wasm-builder:latest}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-${ROOT_DIR}/Dockerfile.wasm}"
BUILD_DIR="${BUILD_DIR:-build/wasm}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
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
    mkdir -p "${build_dir}"

    emcmake cmake \
      -S /workspace \
      -B "/workspace/${build_dir}" \
      -G Ninja \
      -DCMAKE_BUILD_TYPE="${build_type}" \
      -DWITH_NETWORK=OFF

    emmake cmake --build "/workspace/${build_dir}" -j"${jobs}"

    out_html="/workspace/${build_dir}/bin/opentyrian.html"
    if [[ ! -f "${out_html}" ]]; then
      echo "Expected output missing: ${out_html}" >&2
      exit 1
    fi

    echo
    echo "Build complete."
    echo "Output: /workspace/${build_dir}/bin"
  '

