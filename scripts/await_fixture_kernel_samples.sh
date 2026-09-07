#!/usr/bin/env bash
# User-launched authentication session for the selected Darwin startup diagnostic.
set -euo pipefail
FSMGEN_CAPTURE_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${FSMGEN_CAPTURE_SCRIPT_DIR}/project_data_locality_env.sh"
cd -- "${FSMGEN_REPO_ROOT}"
exec "${FSMGEN_REPO_ROOT}/scripts/run_with_ram_guard.sh" -- \
    python3 -B "${FSMGEN_CAPTURE_SCRIPT_DIR}/fixture_kernel_sampler.py" "$@"
