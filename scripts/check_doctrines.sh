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
  "KNOWLEDGE-MAP|knowledge-map/scripts/check_knowledge_map.sh|Knowledge Map cards, bounded root/shards, freshness, coverage, and query parity hold"
  "DOC-PATHS|scripts/check_docs_relative_paths.sh|Live docs and Knowledge Map avoid machine-local absolute paths"
  "LIVE-DOCUMENT-SIZE|scripts/check_live_document_size.sh|Every declared live-document surface stays local, covered, lifecycle-valid, and within owned pressure controls"
  "README-ENTRYPOINT|scripts/check_readme_entrypoint.sh|README routing and landing-page checks; require LIVE-DOCUMENT-SIZE success for destination pressure"
  "PROJECT-DATA-LOCALITY|scripts/check_project_data_locality.sh|Project-owned data stays on repository-derived same-volume roots"
  "TASK-TREE-INTEGRITY|scripts/check_task_tree_integrity.pl|Active task-tree roots, live and sealed nodes, compact terminals, bounded completed-index archives, child references, statuses, and evidence stay structurally complete and retrievable"
  "CLAIM-VERIFICATION|scripts/check_claim_verification.pl|Bounded claim records name exact source markers, three non-aliased evidence legs or owned gaps, and tracked local producers, oracles, and watchers"
  "CLAIM-INVENTORY|scripts/check_claim_verification_inventory.pl|Producer-derived current-surface claims and repository constants remain completely partitioned, independently censused, bounded, and task-owned"
  "CLAIM-DISPOSITIONS|scripts/check_claim_verification_dispositions.pl|Every reviewed candidate joins a current inventory identity and one bounded evidence-bearing outcome; required groups cannot retain open candidates"
  "TASK-ACCEPTANCE|scripts/check_task_acceptance.sh|Staged implementation changes carry fresh box-scoped task diagnosis and regression evidence"
)

usage() {
  cat <<'USAGE'
Usage:
  scripts/check_doctrines.sh [--timings] [--fail-fast]
  scripts/check_doctrines.sh --list|--help

Runs every registered FSMGEN doctrine check and exits nonzero if any doctrine
is breached. The registry lives in this script.
--timings emits wall/user/system seconds for each executed check.
--fail-fast stops on the first failed check; success still requires all checks.
Without flags, every check runs for complete CI diagnostics.
USAGE
}

list_doctrines() {
  local entry id path description
  for entry in "${DOCTRINES[@]}"; do
    IFS='|' read -r id path description <<< "${entry}"
    printf '%s\t%s\t%s\n' "${id}" "${path}" "${description}"
  done
}

doctrine_timings=0
doctrine_fail_fast=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --timings) doctrine_timings=1 ;;
    --fail-fast) doctrine_fail_fast=1 ;;
    --list)
      [[ "$#" -eq 1 ]] || { usage >&2; exit 2; }
      list_doctrines
      exit 0
      ;;
    --help|-h) usage; exit 0 ;;
    *)
      printf '[doctrine] FAIL: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

execute_registered_check() {
  local doctrine_id="$1" doctrine_path="$2"
  if [[ "${doctrine_id}" == README-ENTRYPOINT ]]; then
    # Retain routing diagnostics after a failed prerequisite in collect-all
    # mode, but never accept them as complete README/pressure validation.
    local readme_status=0
    "${ROOT_DIR}/${doctrine_path}" --routing-only || readme_status=$?
    if [[ "${live_document_validated}" -ne 1 ]]; then
      printf '[doctrine] README-ENTRYPOINT requires successful LIVE-DOCUMENT-SIZE in this invocation\n' >&2
      return 1
    fi
    return "${readme_status}"
  else
    "${ROOT_DIR}/${doctrine_path}"
  fi
}

run_registered_check() {
  local doctrine_id="$1" doctrine_path="$2"
  if [[ "${doctrine_timings}" -eq 1 ]]; then
    local TIMEFORMAT="[doctrine] TIME: ${doctrine_id} real_s=%3R user_s=%3U sys_s=%3S"
    time execute_registered_check "${doctrine_id}" "${doctrine_path}"
  else
    execute_registered_check "${doctrine_id}" "${doctrine_path}"
  fi
}

fail=0
meta_fail=0
live_document_validated=0

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
  if run_registered_check "${id}" "${path}"; then
    [[ "${id}" != LIVE-DOCUMENT-SIZE ]] || live_document_validated=1
    printf '[doctrine] PASS: %s\n' "${id}"
  else
    printf '[doctrine] FAIL: %s\n' "${id}" >&2
    fail=1
    if [[ "${doctrine_fail_fast}" -eq 1 ]]; then
      printf '[doctrine] fail-fast: remaining checks were not run\n' >&2
      break
    fi
  fi
done

if [[ "${fail}" -ne 0 ]]; then
  printf '[doctrine] one or more doctrine checks failed\n' >&2
  exit 1
fi

printf '[doctrine] all doctrine checks passed\n'
