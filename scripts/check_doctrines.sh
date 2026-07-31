#!/usr/bin/env bash
#
# check_doctrines.sh - FSMGEN doctrine-enforcement driver.
#
# A doctrine check is an executable script that returns 0 when its rule holds
# and nonzero when the repository violates the rule. This driver is the registry:
# add a row here when a new deterministic doctrine check is introduced.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

DOCTRINES=(
  "DOCTRINE-BOOTSTRAP|scripts/check_doctrine_bootstrap.sh|Doctrine and toolbox docs, bootstrap pointers, hook, and CI driver wiring exist"
  "MEMORY-ARCH|scripts/check_memory_architecture.sh|Durable memory architecture, bounded MEMORY.md, bootstrap pointers, task-tree and decision stores"
  "KNOWLEDGE-MAP|knowledge-map/scripts/check_knowledge_map.sh|Knowledge Map fact cards are valid and KNOWLEDGE_MAP.md is in sync"
  "DOC-PATHS|scripts/check_docs_relative_paths.sh|Live docs and Knowledge Map avoid machine-local absolute paths"
  "LIVE-DOCUMENT-SIZE|scripts/check_live_document_size.sh|Every declared live-document surface stays local, covered, lifecycle-valid, and within owned pressure controls"
  "README-ENTRYPOINT|scripts/check_readme_entrypoint.sh|README.md and every routed destination stay pressure-controlled discovery surfaces"
  "PROJECT-DATA-LOCALITY|scripts/check_project_data_locality.sh|Project-owned data stays on repository-derived same-volume roots"
  "TASK-TREE-INTEGRITY|scripts/check_task_tree_integrity.pl|Active task-tree roots, nodes, child references, statuses, and leaf evidence fields stay structurally complete"
  "TASK-ACCEPTANCE|scripts/check_task_acceptance.sh|Staged implementation changes carry fresh box-scoped task diagnosis and regression evidence"
)

usage() {
  cat <<'USAGE'
Usage:
  scripts/check_doctrines.sh [--list|--help]

Runs every registered FSMGEN doctrine check and exits nonzero if any doctrine
is breached. The registry lives in this script.
USAGE
}

list_doctrines() {
  local entry id path description
  for entry in "${DOCTRINES[@]}"; do
    IFS='|' read -r id path description <<< "${entry}"
    printf '%s\t%s\t%s\n' "${id}" "${path}" "${description}"
  done
}

case "${1:-}" in
  "")
    ;;
  --list)
    list_doctrines
    exit 0
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    printf '[doctrine] FAIL: unknown argument: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
esac

fail=0
meta_fail=0

printf '[doctrine] registered checks: %d\n' "${#DOCTRINES[@]}"

for entry in "${DOCTRINES[@]}"; do
  IFS='|' read -r id path description <<< "${entry}"
  if [[ ! -f "${path}" ]]; then
    printf '[doctrine] FAIL: %s registry path missing: %s\n' "${id}" "${path}" >&2
    meta_fail=1
    continue
  fi
  if [[ ! -x "${path}" ]]; then
    printf '[doctrine] FAIL: %s registry path is not executable: %s\n' "${id}" "${path}" >&2
    meta_fail=1
  fi
done

if [[ "${meta_fail}" -ne 0 ]]; then
  printf '[doctrine] registry meta-check failed\n' >&2
  exit 1
fi

for entry in "${DOCTRINES[@]}"; do
  IFS='|' read -r id path description <<< "${entry}"
  printf '[doctrine] RUN:  %s - %s\n' "${id}" "${description}"
  if "${ROOT_DIR}/${path}"; then
    printf '[doctrine] PASS: %s\n' "${id}"
  else
    printf '[doctrine] FAIL: %s\n' "${id}" >&2
    fail=1
  fi
done

if [[ "${fail}" -ne 0 ]]; then
  printf '[doctrine] one or more doctrine checks failed\n' >&2
  exit 1
fi

printf '[doctrine] all doctrine checks passed\n'
