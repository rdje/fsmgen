#!/usr/bin/env bash
# check_project_data_locality.sh - enforce repository-volume project data storage.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail=0
note() {
  printf '[project-data-locality] FAIL: %s\n' "$1" >&2
  fail=1
}

runtime_matches() {
  git grep -hE 'File::Temp|temp(dir|file)|mktemp|(/private)?/tmp/' -- \
    bin/fsmgen perl/FSM/Pipeline/HDLGenerator.pm knowledge-map/scripts \
    2>/dev/null || true
}

public_matches() {
  git grep -hE '(/private)?/tmp/' -- \
    README.md TOOLBOX.md KNOWLEDGE_MAP.md docs/book/src docs/knowledge \
    2>/dev/null || true
}

test_explicit_matches() {
  git grep -hE '(/private)?/tmp/' -- 't/*.t' 2>/dev/null || true
}

test_file_temp_files() {
  git grep -l 'use File::Temp' -- 't/*.t' 2>/dev/null \
    | sed 's#^[^/]*/##' || true
}

legacy_config_matches() {
  git grep -hE '(^|[[:space:]"`(])(/Users/|/home/|/private/tmp|/tmp/)' -- \
    perl/env.conf 2>/dev/null || true
}

# Exact pre-adoption signatures. They are temporary monotonic-debt pins owned
# by PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.2/.3. Any new, removed, or
# modified match requires the owning leaf to update or retire the corresponding
# signature, so unowned locality drift fails immediately.
expect_signature() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [[ "${actual}" != "${expected}" ]]; then
    note "${label} signature changed (expected ${expected}, found ${actual}); classify it in the active locality task-tree"
  fi
}

expect_signature "runtime temporary-path debt" "2129192340:452" "$(runtime_matches | LC_ALL=C sort | cksum | awk '{ print $1 ":" $2 }')"
expect_signature "public off-volume command debt" "1873392830:253463" "$(public_matches | LC_ALL=C sort | cksum | awk '{ print $1 ":" $2 }')"
expect_signature "explicit test off-volume path debt" "1570842766:1619" "$(test_explicit_matches | LC_ALL=C sort | cksum | awk '{ print $1 ":" $2 }')"
expect_signature "uncontrolled File::Temp test set" "4078265247:28340" "$(test_file_temp_files | LC_ALL=C sort | cksum | awk '{ print $1 ":" $2 }')"
expect_signature "legacy machine-local config debt" "2365314575:150" "$(legacy_config_matches | LC_ALL=C sort | cksum | awk '{ print $1 ":" $2 }')"

if [[ ! -f PROJECT_DATA_LOCALITY.md ]]; then
  note "PROJECT_DATA_LOCALITY.md is missing"
fi
if [[ ! -f docs/decisions/0022-project-data-locality-and-same-volume-storage.md ]]; then
  note "decision 0022 is missing"
fi
if [[ ! -f docs/tasks/PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.md ]]; then
  note "owning adoption task-tree is missing"
fi
if ! grep -qxF '.artifacts/' .gitignore; then
  note ".gitignore must ignore the repository-local .artifacts/ root"
fi

if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi

printf '[project-data-locality] OK: policy present; pre-adoption debt signatures unchanged and cannot grow silently\n'
