#!/usr/bin/env bash
#
# check_readme_entrypoint.sh - doctrine check for decisions 0021, 0024, and
# 0038 plus the project-owned README_POLICY.md:
# README.md is a bounded, nearly static landing page, not an append log.
#
# README.md is the file every harness's bootstrap chain routes a fresh agent to
# first, so its size is paid on every ramp-up in every session. MEMORY.md is
# capped for the same reason; before this check existed the growth simply moved
# here (9,911 lines / 928 KiB, 73% of it per-leaf chronology).
#
# Two structural invariants, both re-derived from the tracked file:
#
#   1. SIZE     - README.md stays under both line and byte caps.
#   2. NARRATION - no single line enumerates two or more work-unit leaves with
#                  narration verbs. That pattern (".2.1 captured ..., .2.2
#                  completed ..., .2.3 selected ...") is the append-log
#                  signature. A single leaf pointer ("selector for TREE.3",
#                  "documents the .794 shipped aggregate") is legitimate index
#                  content and is deliberately allowed.
#
# Knobs (env): README_LINE_CAP, README_BYTE_CAP,
#              README_MAX_LEAF_REFS_PER_LINE.
#
# The doctrine driver invokes this check unconditionally. Do not scope the
# landing-page tree invariant to staged or changed paths.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

LINE_CAP="${README_LINE_CAP:-275}"
BYTE_CAP="${README_BYTE_CAP:-12288}"
MAX_REFS="${README_MAX_LEAF_REFS_PER_LINE:-1}"
fail=0

note() { printf 'readme-entrypoint: %s\n' "$1" >&2; fail=1; }
ok()   { printf 'readme-entrypoint: ok:   %s\n' "$1"; }

if [ ! -f README.md ]; then
  note "README.md is missing (it is the declared single entry point)"
  exit 1
fi

# 1. Size cap.
lines=$(wc -l < README.md | tr -d ' ')
if [ "${lines}" -le "${LINE_CAP}" ]; then
  ok "README.md is ${lines} lines (<= cap ${LINE_CAP})"
else
  note "README.md is ${lines} lines (> cap ${LINE_CAP})"
  note "  README.md is a nearly static landing page (docs/decisions/0024)."
  note "  Move per-leaf detail to its owning task-tree under docs/tasks/, durable"
  note "  cross-cutting facts to docs/decisions/, user-facing behavior to docs/book/,"
  note "  and leave history to git (git log --grep=<UNIT-ID>)."
fi

bytes=$(wc -c < README.md | tr -d ' ')
if [ "${bytes}" -le "${BYTE_CAP}" ]; then
  ok "README.md is ${bytes} bytes (<= cap ${BYTE_CAP})"
else
  note "README.md is ${bytes} bytes (> cap ${BYTE_CAP})"
  note "  README.md is a nearly static landing page (docs/decisions/0024)."
  note "  Move dynamic or detailed content to its canonical maintained surface;"
  note "  README_POLICY.md defines the project- and harness-neutral routing and exception rule."
fi

# 2. Per-leaf chronology enumeration.
VERBS='shipped|selected|completed|captured|added|promoted|deferred|closed|audited|chose|repaired|aligned|proved|scaffolded|extended|made|ships|selects|now'
offenders=$(
  awk -v verbs="${VERBS}" -v maxrefs="${MAX_REFS}" '
    {
      n = 0; s = $0
      while (match(s, "`\\.[0-9][A-Za-z0-9.-]*`[[:space:]]+(" verbs ")")) {
        n++
        s = substr(s, RSTART + RLENGTH)
      }
      if (n > maxrefs) printf "%d:%d:%s\n", FNR, n, substr($0, 1, 120)
    }
  ' README.md
)

if [ -z "${offenders}" ]; then
  ok "no line enumerates more than ${MAX_REFS} narrated work-unit leaf reference(s)"
else
  note "README.md re-narrates per-leaf history (docs/decisions/0021 forbids it):"
  while IFS= read -r line; do
    note "  README.md:${line}"
  done <<< "${offenders}"
  note "  Chronology belongs to git (git log --grep=<UNIT-ID>) and the owning"
  note "  task-tree, not to the entry point. State what the file IS, not what"
  note "  each leaf did to it."
fi

if [ "${fail}" -eq 0 ]; then
  printf 'readme-entrypoint: all README entry-point invariants hold\n'
fi
exit "${fail}"
