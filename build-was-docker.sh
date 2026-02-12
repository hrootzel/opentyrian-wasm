#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-opentyrian-wasm-builder:latest}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-${ROOT_DIR}/Dockerfile.wasm}"
BUILD_DIR="${BUILD_DIR:-build/wasm}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
CLEAN="${CLEAN:-0}"
CLEANUP_BUILD="${CLEANUP_BUILD:-0}"
CLEANUP_BUILD_ONLY="${CLEANUP_BUILD_ONLY:-0}"

cleanup_wasm_runtime() {
  local build_dir_full="$1"
  if [[ ! -d "${build_dir_full}" ]]; then
    echo "Build directory not found: ${build_dir_full}" >&2
    return 1
  fi
  if [[ ! -d "${build_dir_full}/bin" ]]; then
    echo "Build bin directory not found: ${build_dir_full}/bin" >&2
    return 1
  fi
  find "${build_dir_full}" -mindepth 1 -maxdepth 1 ! -name "bin" -exec rm -rf {} +
}

if [[ "${CLEANUP_BUILD_ONLY}" == "1" ]]; then
  cleanup_wasm_runtime "${ROOT_DIR}/${BUILD_DIR}"
  echo "CleanupBuild complete: kept runtime files in ${ROOT_DIR}/${BUILD_DIR}/bin"
  exit 0
fi

mkdir -p "${ROOT_DIR}/build"

docker build -f "${DOCKERFILE_PATH}" -t "${IMAGE_NAME}" "${ROOT_DIR}"

docker run --rm -t \
  -v "${ROOT_DIR}:/workspace" \
  -v "${ROOT_DIR}/build:/workspace/build" \
  -e BUILD_DIR="${BUILD_DIR}" \
  -e BUILD_TYPE="${BUILD_TYPE}" \
  -e JOBS="${JOBS}" \
  -e CLEAN="${CLEAN}" \
  -e CLEANUP_BUILD="${CLEANUP_BUILD}" \
  "${IMAGE_NAME}" \
  bash -lc '
    set -euo pipefail
    export EMSDK_QUIET=1
    source /opt/emsdk/emsdk_env.sh >/dev/null

    build_dir="${BUILD_DIR:-build/wasm}"
    build_type="${BUILD_TYPE:-Release}"
    jobs="${JOBS:-4}"
    container_build_dir="${CONTAINER_BUILD_DIR:-/tmp/opentyrian-wasm-build}"
    host_build_dir="/workspace/${build_dir}"
    cleanup_build="${CLEANUP_BUILD:-0}"

    if [[ "${CLEAN:-0}" == "1" ]]; then
      rm -rf "${host_build_dir}" "${container_build_dir}"
    fi
    mkdir -p "${host_build_dir}" "${container_build_dir}"

    emcmake cmake \
      -S /workspace \
      -B "${container_build_dir}" \
      -G Ninja \
      -DCMAKE_BUILD_TYPE="${build_type}" \
      -DWITH_NETWORK=OFF

    emmake cmake --build "${container_build_dir}" -j"${jobs}"

    out_html="${container_build_dir}/bin/opentyrian.html"
    if [[ ! -f "${out_html}" ]]; then
      echo "Expected output missing: ${out_html}" >&2
      exit 1
    fi

    # Copy runtime artifacts back to mounted host build dir.
    mkdir -p "${host_build_dir}/bin"
    cp -a "${container_build_dir}/bin/." "${host_build_dir}/bin/"

    if [[ "${cleanup_build}" == "1" ]]; then
      find "${host_build_dir}" -mindepth 1 -maxdepth 1 ! -name "bin" -exec rm -rf {} +
    fi

    echo
    echo "Build complete."
    echo "Output: ${host_build_dir}/bin"
  '
