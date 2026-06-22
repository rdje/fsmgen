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
  DOCTRINE_ENFORCEMENT.md
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
