#!/usr/bin/env bash
# check_task_acceptance.sh - neutral staged task-evidence gate.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGE_REGISTRY_PATH="doctrine/task_acceptance/change_paths.tsv"
SIGNATURE_REGISTRY_PATH="doctrine/task_acceptance/evidence_signatures.tsv"

fail() {
  printf '[task-acceptance] FAIL: %s\n' "$1" >&2
  exit 1
}

git_root="$(git -C "${ROOT_DIR}" rev-parse --show-toplevel 2>/dev/null)" \
  || fail "repository root is not a Git worktree"
[[ "${git_root}" == "${ROOT_DIR}" ]] \
  || fail "script-derived root does not equal the Git repository root"

scratch_base="${ROOT_DIR}/.artifacts/task_acceptance"
mkdir -p "${scratch_base}" \
  || fail "cannot create repository-local scratch root: .artifacts/task_acceptance"
WORK_DIR="$(mktemp -d "${scratch_base}/check.XXXXXX" 2>/dev/null)" \
  || fail "cannot create repository-local checker scratch directory"
cleanup() {
  rm -rf "${WORK_DIR}"
  rmdir "${scratch_base}" 2>/dev/null || true
  rmdir "${ROOT_DIR}/.artifacts" 2>/dev/null || true
}
trap cleanup EXIT

index_file() {
  local repo_path="$1" destination="$2"
  git -C "${ROOT_DIR}" cat-file -e ":${repo_path}" 2>/dev/null \
    || fail "required staged/index file is missing: ${repo_path}"
  git -C "${ROOT_DIR}" show ":${repo_path}" >"${destination}" 2>/dev/null \
    || fail "cannot read staged/index file: ${repo_path}"
}

index_file "${CHANGE_REGISTRY_PATH}" "${WORK_DIR}/change_paths.tsv"
index_file "${SIGNATURE_REGISTRY_PATH}" "${WORK_DIR}/evidence_signatures.tsv"

valid_ere() {
  local expression="$1" rc
  grep -Eq -- "${expression}" /dev/null 2>/dev/null
  rc=$?
  [[ "${rc}" -eq 0 || "${rc}" -eq 1 ]]
}

declare -a CHANGE_PATTERNS=()
declare -a CHANGE_DESCRIPTIONS=()

load_change_registry() {
  local file="$1" line line_no=0 fields pattern description extra
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_no=$((line_no + 1))
    if [[ "${line_no}" -eq 1 ]]; then
      [[ "${line}" == $'path_ere\tdescription' ]] \
        || fail "${CHANGE_REGISTRY_PATH}:1 must be the exact TSV header path_ere<TAB>description"
      continue
    fi
    [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    fields="$(awk -F '\t' '{ print NF }' <<<"${line}")"
    [[ "${fields}" -eq 2 ]] \
      || fail "${CHANGE_REGISTRY_PATH}:${line_no} must contain exactly 2 tab-separated fields"
    IFS=$'\t' read -r pattern description extra <<<"${line}"
    [[ -n "${pattern}" && -n "${description}" ]] \
      || fail "${CHANGE_REGISTRY_PATH}:${line_no} contains an empty required field"
    valid_ere "${pattern}" \
      || fail "${CHANGE_REGISTRY_PATH}:${line_no} contains an invalid POSIX ERE"
    local prior
    for prior in "${CHANGE_PATTERNS[@]}"; do
      [[ "${prior}" != "${pattern}" ]] \
        || fail "${CHANGE_REGISTRY_PATH}:${line_no} duplicates a path expression"
    done
    CHANGE_PATTERNS+=("${pattern}")
    CHANGE_DESCRIPTIONS+=("${description}")
  done <"${file}"
  [[ "${line_no}" -gt 0 ]] || fail "${CHANGE_REGISTRY_PATH} is empty"
  [[ "${#CHANGE_PATTERNS[@]}" -gt 0 ]] \
    || fail "${CHANGE_REGISTRY_PATH} declares no implementation paths"
}

declare -a SIG_SCOPES=()
declare -a SIG_FAMILIES=()
declare -a SIG_MATCHES=()
declare -a SIG_CASES=()
declare -a SIG_PATTERNS=()
declare -a SIG_DESCRIPTIONS=()

load_signature_registry() {
  local file="$1" line line_no=0 fields scope family match_mode case_mode pattern description extra
  local root_count=0 no_regression_count=0 i
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_no=$((line_no + 1))
    if [[ "${line_no}" -eq 1 ]]; then
      [[ "${line}" == $'scope\tfamily\tmatch\tcase\tpattern\tdescription' ]] \
        || fail "${SIGNATURE_REGISTRY_PATH}:1 must be the exact six-column TSV header"
      continue
    fi
    [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    fields="$(awk -F '\t' '{ print NF }' <<<"${line}")"
    [[ "${fields}" -eq 6 ]] \
      || fail "${SIGNATURE_REGISTRY_PATH}:${line_no} must contain exactly 6 tab-separated fields"
    IFS=$'\t' read -r scope family match_mode case_mode pattern description extra <<<"${line}"
    [[ -n "${scope}" && -n "${family}" && -n "${match_mode}" \
       && -n "${case_mode}" && -n "${pattern}" && -n "${description}" ]] \
      || fail "${SIGNATURE_REGISTRY_PATH}:${line_no} contains an empty required field"
    [[ "${scope}" == "root_cause" || "${scope}" == "no_regression" ]] \
      || fail "${SIGNATURE_REGISTRY_PATH}:${line_no} has unknown scope: ${scope}"
    [[ "${family}" =~ ^[a-z][a-z0-9_-]*$ ]] \
      || fail "${SIGNATURE_REGISTRY_PATH}:${line_no} has invalid family id: ${family}"
    [[ "${match_mode}" == "literal" || "${match_mode}" == "ere" ]] \
      || fail "${SIGNATURE_REGISTRY_PATH}:${line_no} has unknown match mode: ${match_mode}"
    [[ "${case_mode}" == "sensitive" || "${case_mode}" == "insensitive" ]] \
      || fail "${SIGNATURE_REGISTRY_PATH}:${line_no} has unknown case mode: ${case_mode}"
    if [[ "${match_mode}" == "ere" ]]; then
      valid_ere "${pattern}" \
        || fail "${SIGNATURE_REGISTRY_PATH}:${line_no} contains an invalid POSIX ERE"
    fi
    for ((i = 0; i < ${#SIG_SCOPES[@]}; i++)); do
      if [[ "${SIG_SCOPES[$i]}" == "${scope}" \
         && "${SIG_FAMILIES[$i]}" == "${family}" \
         && "${SIG_MATCHES[$i]}" == "${match_mode}" \
         && "${SIG_CASES[$i]}" == "${case_mode}" \
         && "${SIG_PATTERNS[$i]}" == "${pattern}" ]]; then
        fail "${SIGNATURE_REGISTRY_PATH}:${line_no} duplicates an evidence-signature row"
      fi
    done
    SIG_SCOPES+=("${scope}")
    SIG_FAMILIES+=("${family}")
    SIG_MATCHES+=("${match_mode}")
    SIG_CASES+=("${case_mode}")
    SIG_PATTERNS+=("${pattern}")
    SIG_DESCRIPTIONS+=("${description}")
    if [[ "${scope}" == "root_cause" ]]; then
      root_count=$((root_count + 1))
    else
      no_regression_count=$((no_regression_count + 1))
    fi
  done <"${file}"
  [[ "${line_no}" -gt 0 ]] || fail "${SIGNATURE_REGISTRY_PATH} is empty"
  [[ "${root_count}" -gt 0 ]] \
    || fail "${SIGNATURE_REGISTRY_PATH} declares no root_cause signatures"
  [[ "${no_regression_count}" -gt 0 ]] \
    || fail "${SIGNATURE_REGISTRY_PATH} declares no no_regression signatures"
}

load_change_registry "${WORK_DIR}/change_paths.tsv"
load_signature_registry "${WORK_DIR}/evidence_signatures.tsv"

git -C "${ROOT_DIR}" diff --cached --name-only -z --diff-filter=ACMRTD \
  >"${WORK_DIR}/staged_paths.z" \
  || fail "cannot enumerate staged paths"

declare -a STAGED_PATHS=()
while IFS= read -r -d '' staged_path; do
  STAGED_PATHS+=("${staged_path}")
done <"${WORK_DIR}/staged_paths.z"

requires_acceptance=0
declare -a MATCHED_CHANGE_PATHS=()
for staged_path in "${STAGED_PATHS[@]}"; do
  for pattern in "${CHANGE_PATTERNS[@]}"; do
    if grep -Eq -- "${pattern}" <<<"${staged_path}"; then
      requires_acceptance=1
      MATCHED_CHANGE_PATHS+=("${staged_path}")
      break
    fi
  done
done

if [[ "${requires_acceptance}" -eq 0 ]]; then
  printf '[task-acceptance] OK: no configured implementation change staged; checklist not required\n'
  exit 0
fi

declare -a TASK_PATHS=()
for staged_path in "${STAGED_PATHS[@]}"; do
  if [[ "${staged_path}" =~ ^docs/tasks/[^/]+\.md$ ]] \
    && git -C "${ROOT_DIR}" cat-file -e ":${staged_path}" 2>/dev/null; then
    TASK_PATHS+=("${staged_path}")
  fi
done

[[ "${#TASK_PATHS[@]}" -gt 0 ]] \
  || fail "configured implementation paths are staged, but no owning docs/tasks/*.md file is staged"

fresh_line_numbers() {
  local repo_path="$1" output="$2"
  git -C "${ROOT_DIR}" diff --cached --unified=0 --no-ext-diff -- "${repo_path}" \
    | awk '
        /^@@ / {
          in_hunk = 0
          if (match($0, /\+[0-9]+(,[0-9]+)?/)) {
            token = substr($0, RSTART, RLENGTH)
            sub(/^\+/, "", token)
            split(token, parts, ",")
            next_new = parts[1] + 0
            in_hunk = 1
          }
          next
        }
        in_hunk && /^\+/ { print next_new; next_new++; next }
        in_hunk && /^-/   { next }
        in_hunk && /^ /   { next_new++; next }
      ' >"${output}"
  local pipe_status=("${PIPESTATUS[@]}")
  [[ "${pipe_status[0]}" -eq 0 && "${pipe_status[1]}" -eq 0 ]] \
    || fail "cannot derive fresh staged lines for ${repo_path}"
}

box_body() {
  local start_line="$1" file="$2"
  awk -v start="${start_line}" '
    function isbox(line) { return match(line, /^[ \t]*[-*][ \t]*\[[ xX]\][ \t]/) }
    function indent(line, first) {
      first = match(line, /[^ \t]/)
      return first == 0 ? 0 : first - 1
    }
    NR < start { next }
    NR == start { box_indent = indent($0); print; next }
    {
      if (isbox($0) && indent($0) <= box_indent) exit
      if ($0 ~ /^#/) exit
      print
    }
  ' "${file}"
}

MATCHED_SIGNATURE_FAMILY=""
body_has_signature() {
  local scope="$1" body_file="$2" i
  for ((i = 0; i < ${#SIG_SCOPES[@]}; i++)); do
    [[ "${SIG_SCOPES[$i]}" == "${scope}" ]] || continue
    local -a grep_args=()
    if [[ "${SIG_MATCHES[$i]}" == "literal" ]]; then
      grep_args+=("-F")
    else
      grep_args+=("-E")
    fi
    [[ "${SIG_CASES[$i]}" == "insensitive" ]] && grep_args+=("-i")
    if grep "${grep_args[@]}" -q -- "${SIG_PATTERNS[$i]}" "${body_file}"; then
      MATCHED_SIGNATURE_FAMILY="${SIG_FAMILIES[$i]}"
      return 0
    fi
  done
  return 1
}

FOUND_BOX_FAMILY=""
find_fresh_checked_box() {
  local task_file="$1" fresh_set="$2" keyword_ere="$3" scope="${4:-}"
  local header_file="${WORK_DIR}/headers.txt" body_file="${WORK_DIR}/body.txt"
  local line_no header
  grep -nEi -- "^[[:space:]]*[-*][[:space:]]*\[[xX]\][[:space:]].*(${keyword_ere})" \
    "${task_file}" >"${header_file}" 2>/dev/null || true
  while IFS=: read -r line_no header; do
    [[ -n "${line_no}" ]] || continue
    [[ "${fresh_set}" == *"|${line_no}|"* ]] || continue
    if [[ -z "${scope}" ]]; then
      FOUND_BOX_FAMILY=""
      return 0
    fi
    box_body "${line_no}" "${task_file}" >"${body_file}" \
      || fail "cannot extract checklist box body"
    if body_has_signature "${scope}" "${body_file}"; then
      FOUND_BOX_FAMILY="${MATCHED_SIGNATURE_FAMILY}"
      return 0
    fi
  done <"${header_file}"
  return 1
}

declare -a TASK_FAILURES=()
task_index=0
for task_path in "${TASK_PATHS[@]}"; do
  task_index=$((task_index + 1))
  task_file="${WORK_DIR}/task_${task_index}.md"
  fresh_file="${WORK_DIR}/task_${task_index}.fresh"
  index_file "${task_path}" "${task_file}"
  fresh_line_numbers "${task_path}" "${fresh_file}"
  fresh_set='|'
  while IFS= read -r line_no; do
    [[ -n "${line_no}" ]] && fresh_set="${fresh_set}${line_no}|"
  done <"${fresh_file}"

  missing=()
  root_family=""
  no_regression_family=""
  if find_fresh_checked_box "${task_file}" "${fresh_set}" \
      'ROOT[[:space:]_-]*CAUSE|WHY[[:space:]]*\+[[:space:]]*WHERE' root_cause; then
    root_family="${FOUND_BOX_FAMILY}"
  else
    missing+=("fresh checked ROOT CAUSE box with box-scoped root_cause signature")
  fi
  if ! find_fresh_checked_box "${task_file}" "${fresh_set}" \
      'ADDRESSED|VERIFIED|RESOLVED|BEFORE.{0,8}AFTER|REJECT.{0,8}PASS'; then
    missing+=("fresh checked ADDRESSED box")
  fi
  if find_fresh_checked_box "${task_file}" "${fresh_set}" \
      'NO[[:space:]_-]*REGRESSION|NO[[:space:]_-]*REGRESS|REGRESSION' no_regression; then
    no_regression_family="${FOUND_BOX_FAMILY}"
  else
    missing+=("fresh checked NO REGRESSION box with box-scoped no_regression signature")
  fi

  if [[ "${#missing[@]}" -eq 0 ]]; then
    printf '[task-acceptance] OK: %s carries fresh evidence-backed acceptance (root=%s, no-regression=%s)\n' \
      "${task_path}" "${root_family}" "${no_regression_family}"
    exit 0
  fi
  TASK_FAILURES+=("${task_path}: $(IFS='; '; printf '%s' "${missing[*]}")")
done

printf '[task-acceptance] FAIL: no staged task file independently satisfies the current-slice checklist\n' >&2
printf '  configured implementation paths:\n' >&2
for staged_path in "${MATCHED_CHANGE_PATHS[@]}"; do
  printf '    - %s\n' "${staged_path}" >&2
done
printf '  candidate task files:\n' >&2
for reason in "${TASK_FAILURES[@]}"; do
  printf '    - %s\n' "${reason}" >&2
done
exit 1
