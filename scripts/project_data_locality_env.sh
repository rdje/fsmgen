#!/usr/bin/env bash
# Source this file to route project-owned temporary data and tool caches into
# repository-derived roots. It intentionally overwrites inherited cache/temp
# variables so standard FSMGen launchers cannot fall back off-volume.

FSMGEN_LOCALITY_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
FSMGEN_REPO_ROOT="$(cd -- "${FSMGEN_LOCALITY_SCRIPT_DIR}/.." && pwd -P)"

fsmgen_locality_device_id() {
  if stat -f '%d' "$1" >/dev/null 2>&1; then
    stat -f '%d' "$1"
  else
    stat -c '%d' "$1"
  fi
}

fsmgen_locality_ensure_directory() {
  local requested="$1"
  local resolved
  local root_device
  local path_device

  mkdir -p -- "${requested}"
  resolved="$(cd -- "${requested}" && pwd -P)"
  case "${resolved}" in
    "${FSMGEN_REPO_ROOT}"|"${FSMGEN_REPO_ROOT}"/*) ;;
    *)
      printf 'project-data-locality: %s resolves outside repository root: %s\n' "${requested}" "${resolved}" >&2
      return 1
      ;;
  esac

  root_device="$(fsmgen_locality_device_id "${FSMGEN_REPO_ROOT}")"
  path_device="$(fsmgen_locality_device_id "${resolved}")"
  if [[ "${root_device}" != "${path_device}" ]]; then
    printf 'project-data-locality: %s is not on the repository filesystem volume\n' "${resolved}" >&2
    return 1
  fi

  printf '%s\n' "${resolved}"
}

# Validate an existing .artifacts link before creating any descendant through
# it. A missing directory is safe to create directly below the repository.
if [[ -e "${FSMGEN_REPO_ROOT}/.artifacts" || -L "${FSMGEN_REPO_ROOT}/.artifacts" ]]; then
  FSMGEN_ARTIFACT_ROOT="$(fsmgen_locality_ensure_directory "${FSMGEN_REPO_ROOT}/.artifacts")" || return 1 2>/dev/null || exit 1
else
  mkdir -- "${FSMGEN_REPO_ROOT}/.artifacts"
  FSMGEN_ARTIFACT_ROOT="$(fsmgen_locality_ensure_directory "${FSMGEN_REPO_ROOT}/.artifacts")" || return 1 2>/dev/null || exit 1
fi

FSMGEN_TMP_ROOT="$(fsmgen_locality_ensure_directory "${FSMGEN_ARTIFACT_ROOT}/tmp")" || return 1 2>/dev/null || exit 1
FSMGEN_CACHE_ROOT="$(fsmgen_locality_ensure_directory "${FSMGEN_ARTIFACT_ROOT}/cache")" || return 1 2>/dev/null || exit 1
FSMGEN_LOG_ROOT="$(fsmgen_locality_ensure_directory "${FSMGEN_ARTIFACT_ROOT}/logs")" || return 1 2>/dev/null || exit 1
FSMGEN_BUILD_ROOT="$(fsmgen_locality_ensure_directory "${FSMGEN_ARTIFACT_ROOT}/build")" || return 1 2>/dev/null || exit 1

export FSMGEN_REPO_ROOT FSMGEN_ARTIFACT_ROOT FSMGEN_TMP_ROOT FSMGEN_CACHE_ROOT FSMGEN_LOG_ROOT FSMGEN_BUILD_ROOT
export TMPDIR="${FSMGEN_TMP_ROOT}"
export TMP="${FSMGEN_TMP_ROOT}"
export TEMP="${FSMGEN_TMP_ROOT}"
export XDG_CACHE_HOME="${FSMGEN_CACHE_ROOT}/xdg"
export CARGO_HOME="${FSMGEN_CACHE_ROOT}/cargo"
export CARGO_TARGET_DIR="${FSMGEN_REPO_ROOT}/rust/target"
export PIP_CACHE_DIR="${FSMGEN_CACHE_ROOT}/pip"
export NPM_CONFIG_CACHE="${FSMGEN_CACHE_ROOT}/npm"
export PUB_CACHE="${FSMGEN_CACHE_ROOT}/dart-pub"
export JULIA_DEPOT_PATH="${FSMGEN_CACHE_ROOT}/julia"
export PERL_CPANM_HOME="${FSMGEN_CACHE_ROOT}/cpanm"

unset FSMGEN_LOCALITY_SCRIPT_DIR
unset -f fsmgen_locality_device_id fsmgen_locality_ensure_directory
