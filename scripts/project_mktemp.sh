#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=project_data_locality_env.sh
source "${SCRIPT_DIR}/project_data_locality_env.sh"

mode="file"
case "${1:-}" in
  "") ;;
  -d|--directory)
    mode="directory"
    shift
    ;;
  *)
    printf 'Usage: scripts/project_mktemp.sh [-d|--directory]\n' >&2
    exit 2
    ;;
esac

if (($#)); then
  printf 'Usage: scripts/project_mktemp.sh [-d|--directory]\n' >&2
  exit 2
fi

tool_tmp="${FSMGEN_TMP_ROOT}/tools"
mkdir -p -- "${tool_tmp}"
template="${tool_tmp}/fsmgen.XXXXXXXX"

if [[ "${mode}" == "directory" ]]; then
  command mktemp -d "${template}"
else
  command mktemp "${template}"
fi
