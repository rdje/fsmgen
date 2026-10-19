#!/usr/bin/env bash
set -euo pipefail
source_card_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd -- "$source_card_root"
source scripts/project_data_locality_env.sh
exec python3 -B docs/audits/original-join-parent-acceptance-20261018/rollover_source_card.py --current
