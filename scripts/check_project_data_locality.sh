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

public_matches() {
  git grep -hE '(^|[^[:alnum:]_.-])(/private)?/tmp/' -- \
    README.md TOOLBOX.md KNOWLEDGE_MAP.md docs/book/src docs/knowledge \
    2>/dev/null || true
}

test_explicit_matches() {
  git grep -hE '(^|[^[:alnum:]_.-])(/private)?/tmp/' -- 't/*.t' 2>/dev/null || true
}

legacy_config_matches() {
  git grep -hE '(^|[[:space:]"`(])(/Users/|/home/|/private/tmp|/tmp/)' -- \
    perl/env.conf 2>/dev/null || true
}

if [[ -n "$(public_matches)" ]]; then
  note "active public instructions retain operating-system temporary paths"
fi

if [[ -n "$(test_explicit_matches)" ]]; then
  note "tests retain explicit operating-system temporary paths"
fi
if [[ -n "$(legacy_config_matches)" ]]; then
  note "perl/env.conf retains machine-local home or operating-system temporary paths"
fi

if git grep -qE 'File::Temp|(^|[^[:alnum:]_])temp(dir|file)\(' -- \
  bin/fsmgen perl/FSM/Pipeline/HDLGenerator.pm 2>/dev/null; then
  note "CLI/facade lowering must use FSM::ProjectDataLocality instead of ambient File::Temp defaults"
fi
if ! grep -qF 'create_project_tempfile' bin/fsmgen; then
  note "bin/fsmgen does not use the repository-local tempfile helper"
fi
if ! grep -qF 'create_project_tempdir' perl/FSM/Pipeline/HDLGenerator.pm; then
  note "in-process lowering does not use the repository-local tempdir helper"
fi
if ! grep -qF 'project_output_path' bin/fsmgen; then
  note "bin/fsmgen does not enforce repository-contained output paths"
fi

if [[ ! -f .proverc ]] || ! grep -qxF -- '-MFSM::Test::ProjectDataLocality' .proverc; then
  note "standard prove runs must preload FSM::Test::ProjectDataLocality"
fi
if [[ ! -f t/lib/FSM/Test/ProjectDataLocality.pm ]] \
  || ! grep -qF 'configure_project_temp_environment' t/lib/FSM/Test/ProjectDataLocality.pm; then
  note "test harness locality module is missing or does not establish repository-local temp storage"
fi
for launcher in bin/ci-regression scripts/run_with_ram_guard.sh; do
  if ! grep -qF 'project_data_locality_env.sh' "${launcher}"; then
    note "${launcher} does not establish the project-local tool environment"
  fi
done

if ! grep -qF 'project_data_locality_env.sh' knowledge-map/scripts/check_knowledge_map.sh; then
  note "Knowledge Map validation does not establish the project-local tool environment"
fi
if grep -qE '="\$\(mktemp\)"' knowledge-map/scripts/check_knowledge_map.sh; then
  note "Knowledge Map validation still uses an unqualified operating-system temporary path"
fi
if ! grep -qF 'command mktemp "$scratch_dir/' knowledge-map/scripts/check_knowledge_map.sh; then
  note "Knowledge Map validation does not bind scratch files to its repository-local directory"
fi

if [[ ! -f perl/FSM/ProjectDataLocality.pm ]]; then
  note "FSM::ProjectDataLocality is missing"
else
  tempfile_dir_count="$(grep -cF 'DIR => $dir' perl/FSM/ProjectDataLocality.pm || true)"
  if [[ "${tempfile_dir_count}" -lt 2 ]]; then
    note "FSM::ProjectDataLocality temp file/directory constructors must pass explicit repository-local DIR values"
  fi
fi
if [[ ! -x scripts/project_data_locality_env.sh ]]; then
  note "scripts/project_data_locality_env.sh is missing or not executable"
fi
if [[ ! -x scripts/project_mktemp.sh ]]; then
  note "scripts/project_mktemp.sh is missing or not executable"
fi

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

printf '[project-data-locality] OK: runtime, test, config, and active public paths are repository-local\n'
