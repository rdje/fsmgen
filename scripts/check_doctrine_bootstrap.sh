#!/usr/bin/env bash
#
# check_doctrine_bootstrap.sh - structural doctrine check for the doctrine
# enforcement adoption itself.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail=0
note() { printf '[doctrine-bootstrap] FAIL: %s\n' "$1" >&2; fail=1; }
ok() { printf '[doctrine-bootstrap] ok:   %s\n' "$1"; }

required_docs=(
  README.md
  MEMORY_ARCHITECTURE.md
  LIVE_DOCUMENT_SIZE_CONTAINMENT.md
  DOCTRINE_ENFORCEMENT.md
  TASK_ACCEPTANCE.md
  TOOLBOX.md
)

bootstrap_files=(
  AGENTS.md
  CLAUDE.md
  GEMINI.md
  .cursorrules
  .windsurfrules
  .github/copilot-instructions.md
  WARP.md
)

for doc in "${required_docs[@]}"; do
  if [[ -f "${doc}" ]]; then
    ok "${doc} present"
  else
    note "${doc} is missing"
  fi
done

for file in AGENTS.md COMMIT.md DOCTRINE_ENFORCEMENT.md TOOLBOX.md; do
  if grep -q 'TASK_ACCEPTANCE.md' "${file}"; then
    ok "${file} points at TASK_ACCEPTANCE.md"
  else
    note "${file} does not point at TASK_ACCEPTANCE.md"
  fi
done

if grep -q 'TASK-ACCEPTANCE|scripts/check_task_acceptance.sh' scripts/check_doctrines.sh; then
  ok "doctrine registry includes TASK-ACCEPTANCE"
else
  note "doctrine registry does not include TASK-ACCEPTANCE"
fi

if grep -q 'TASK-TREE-INTEGRITY|scripts/check_task_tree_integrity.pl' scripts/check_doctrines.sh; then
  ok "doctrine registry includes TASK-TREE-INTEGRITY"
else
  note "doctrine registry does not include TASK-TREE-INTEGRITY"
fi

if grep -q 'LIVE-DOCUMENT-SIZE|scripts/check_live_document_size.sh' scripts/check_doctrines.sh; then
  ok "doctrine registry includes LIVE-DOCUMENT-SIZE"
else
  note "doctrine registry does not include LIVE-DOCUMENT-SIZE"
fi

live_document_files=(
  live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md
  live-document-size/scripts/check_live_document_size.pl
  doctrine/live_document_size/surfaces.jsonl
  doctrine/live_document_size/ceiling_increase_authorities.jsonl
  doctrine/live_document_size/archive_descriptors.jsonl
  doctrine/live_document_size/evidence_maps.jsonl
  doctrine/live_document_size/version_retention_contracts.jsonl
  doctrine/readme_entrypoint/routed_destinations.jsonl
  doctrine/task_tree/index_archives.jsonl
  scripts/check_live_document_size.sh
  scripts/check_live_document_ceiling_authority.pl
  scripts/check_live_document_route_candidates.pl
  scripts/check_live_document_resulting_tree.pl
  scripts/run_live_document_adapter_verifiers.pl
)
for file in "${live_document_files[@]}"; do
  if [[ -f "${file}" ]]; then
    ok "${file} present"
  else
    note "${file} is missing"
  fi
done

if grep -q 'run_live_document_adapter_verifiers.pl' scripts/check_live_document_size.sh; then
  ok "live-document adapter invokes its verifier runner"
else
  note "live-document adapter does not invoke its verifier runner"
fi

if grep -q 'check_live_document_route_candidates.pl' scripts/check_live_document_size.sh; then
  ok "live-document adapter invokes its route-candidate scanner"
else
  note "live-document adapter does not invoke its route-candidate scanner"
fi

if grep -q 'check_live_document_resulting_tree.pl' scripts/check_live_document_size.sh; then
  ok "live-document adapter checks staged/resulting-tree agreement"
else
  note "live-document adapter does not check staged/resulting-tree agreement"
fi

if grep -q -- '--retention-contracts' scripts/check_live_document_size.sh \
    && grep -q -- '--retention-contracts' live-document-size/scripts/check_live_document_size.pl; then
  ok "live-document adapter and neutral core require retention contracts"
else
  note "live-document adapter/core retention-contract wiring is incomplete"
fi

if grep -q 'scripts/check_doctrines.sh' .github/workflows/regression.yml \
    && ! grep -q 'check_live_document_size.sh' .github/workflows/regression.yml; then
  ok "hosted CI invokes the doctrine driver without re-enumerating live-document checks"
else
  note "hosted CI must invoke only the doctrine driver for live-document enforcement"
fi

for file in "${bootstrap_files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    note "${file} bootstrap pointer is missing"
    continue
  fi
  for marker in README.md MEMORY_ARCHITECTURE.md DOCTRINE_ENFORCEMENT.md TOOLBOX.md; do
    if grep -q "${marker}" "${file}"; then
      ok "${file} points at ${marker}"
    else
      note "${file} does not point at ${marker}"
    fi
  done
done

if [[ -f .githooks/pre-commit ]] && grep -q 'scripts/check_doctrines.sh' .githooks/pre-commit; then
  ok ".githooks/pre-commit runs scripts/check_doctrines.sh"
else
  note ".githooks/pre-commit does not run scripts/check_doctrines.sh"
fi

if [[ -f .github/workflows/regression.yml ]] && grep -q 'scripts/check_doctrines.sh' .github/workflows/regression.yml; then
  ok ".github/workflows/regression.yml runs scripts/check_doctrines.sh"
else
  note ".github/workflows/regression.yml does not run scripts/check_doctrines.sh"
fi

if [[ "${fail}" -ne 0 ]]; then
  printf '[doctrine-bootstrap] doctrine bootstrap check FAILED\n' >&2
  exit 1
fi

printf '[doctrine-bootstrap] all doctrine bootstrap invariants hold\n'
