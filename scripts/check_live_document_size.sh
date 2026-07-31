#!/usr/bin/env bash
# Local adapter for the neutral live-document size-containment checker.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [ "$#" -gt 0 ]; then
  if [ "$#" -ne 2 ] || [ "$1" != "--root" ] || [ ! -d "$2" ]; then
    printf 'Usage: %s [--root PROJECT_ROOT]\n' "$0" >&2
    exit 2
  fi
  PROJECT_ROOT="$(cd "$2" && pwd)"
fi

CORE="${SCRIPT_DIR}/../live-document-size/scripts/check_live_document_size.pl"
ARGS=(
  --root "${PROJECT_ROOT}"
  --registry doctrine/live_document_size/surfaces.jsonl
  --routes doctrine/readme_entrypoint/routed_destinations.jsonl
  --archives doctrine/live_document_size/archive_descriptors.jsonl
  --evidence-maps doctrine/live_document_size/evidence_maps.jsonl
)

ADAPTER_OUTPUT="$(perl "${SCRIPT_DIR}/run_live_document_adapter_verifiers.pl" \
  --root "${PROJECT_ROOT}" \
  --registry doctrine/live_document_size/surfaces.jsonl \
  --archives doctrine/live_document_size/archive_descriptors.jsonl)"
adapter_status=$?
PROOF_ARGS=()
while IFS= read -r proof; do
  [ -n "${proof}" ] && PROOF_ARGS+=(--adapter-proof "${proof}")
done <<< "${ADAPTER_OUTPUT}"

fail=0
[ "${adapter_status}" -eq 0 ] || fail=1
perl "${SCRIPT_DIR}/check_live_document_route_candidates.pl" \
  --root "${PROJECT_ROOT}" \
  --registry doctrine/readme_entrypoint/routed_destinations.jsonl \
  --source scripts/check_readme_entrypoint.sh || fail=1
perl "${SCRIPT_DIR}/check_live_document_resulting_tree.pl" \
  --root "${PROJECT_ROOT}" \
  --surfaces doctrine/live_document_size/surfaces.jsonl \
  --routes doctrine/readme_entrypoint/routed_destinations.jsonl \
  --evidence-maps doctrine/live_document_size/evidence_maps.jsonl || fail=1
GIT_TOP="$(git -C "${PROJECT_ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
if [ "${GIT_TOP}" = "${PROJECT_ROOT}" ]; then
  git -C "${PROJECT_ROOT}" ls-files -z -- '*.md' \
    | perl "${CORE}" "${ARGS[@]}" "${PROOF_ARGS[@]}" --coverage-stdin || fail=1
else
  perl "${CORE}" "${ARGS[@]}" "${PROOF_ARGS[@]}" || fail=1
fi

if [ "${GIT_TOP}" = "${PROJECT_ROOT}" ]; then
  perl "${SCRIPT_DIR}/check_live_document_ceiling_authority.pl" \
    --root "${PROJECT_ROOT}" || fail=1
fi

exit "${fail}"
