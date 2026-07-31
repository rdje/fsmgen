#!/usr/bin/env bash
#
# check_readme_entrypoint.sh - doctrine check for decisions 0021, 0024, 0038,
# and 0040 plus the project-owned README_POLICY.md:
# README.md is a bounded, nearly static landing page, not an append log, and
# its routed destinations cannot become uninstrumented neighboring sinks.
#
# README.md is the file every harness's bootstrap chain routes a fresh agent to
# first, so its size is paid on every ramp-up in every session. MEMORY.md is
# capped for the same reason; before this check existed the growth simply moved
# here (9,911 lines / 928 KiB, 73% of it per-leaf chronology).
#
# Three structural invariants, all re-derived from tracked files:
#
#   1. SIZE     - README.md stays under both line and byte caps.
#   2. NARRATION - no single line enumerates two or more work-unit leaves with
#                  narration verbs. That pattern (".2.1 captured ..., .2.2
#                  completed ..., .2.3 selected ...") is the append-log
#                  signature. A single leaf pointer ("selector for TREE.3",
#                  "documents the .794 shipped aggregate") is legitimate index
#                  content and is deliberately allowed.
#   3. ROUTING   - every project-declared destination is still named by the
#                  README and has its declared size, partition, query/archive,
#                  freshness, or frozen-content pressure control.
#
# Knobs (env): README_LINE_CAP, README_BYTE_CAP,
#              README_MAX_LEAF_REFS_PER_LINE.
#
# The doctrine driver invokes this check unconditionally. Do not scope the
# landing-page tree invariant to staged or changed paths.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ "$#" -gt 0 ]; then
  if [ "$#" -ne 2 ] || [ "$1" != "--root" ] || [ ! -d "$2" ]; then
    printf 'Usage: %s [--root REPOSITORY_ROOT]\n' "$0" >&2
    exit 2
  fi
  ROOT_DIR="$(cd "$2" && pwd)"
fi
cd "${ROOT_DIR}"

LINE_CAP="${README_LINE_CAP:-275}"
BYTE_CAP="${README_BYTE_CAP:-12288}"
MAX_REFS="${README_MAX_LEAF_REFS_PER_LINE:-1}"
ROUTE_REGISTRY="doctrine/readme_entrypoint/routed_destinations.tsv"
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

# 3. Routed-destination pressure closure.
expected_header=$'route_id\tkind\treadme_marker\ttarget\tmax_files\tmax_lines_each\tmax_bytes_each\tmax_lines_total\tmax_bytes_total\tcontrol'
required_routes=(
  shipped_behavior reported_capabilities high_level_direction active_resume
  active_index task_evidence rationale engineering_rationale fact_index
  change_history exact_history diagnostics enforced_rules
  frozen_roadmap_status frozen_achievement_status
)

is_positive_integer() {
  case "$1" in
    ''|*[!0-9]*|0) return 1 ;;
    *) return 0 ;;
  esac
}

route_note() {
  note "  route ${route_id}: $1"
  route_failed=1
}

if [ ! -f "${ROUTE_REGISTRY}" ]; then
  note "routed-destination registry is missing: ${ROUTE_REGISTRY}"
else
  registry_header=$(head -n 1 "${ROUTE_REGISTRY}")
  if [ "${registry_header}" != "${expected_header}" ]; then
    note "${ROUTE_REGISTRY} has an invalid header"
  else
    declare -A seen_routes=()
    while IFS=$'\t' read -r route_id kind readme_marker target max_files \
        max_lines_each max_bytes_each max_lines_total max_bytes_total control extra; do
      [ -z "${route_id}" ] && continue
      route_failed=0

      case "${route_id}" in
        *[!a-z0-9_]*) route_note "has an invalid route_id" ;;
      esac
      if [ -n "${seen_routes[${route_id}]+x}" ]; then
        route_note "is declared more than once"
      else
        seen_routes["${route_id}"]=1
      fi
      if [ -n "${extra}" ]; then
        route_note "has more fields than the registry schema"
      fi
      if [ -z "${readme_marker}" ] || ! grep -Fq -- "${readme_marker}" README.md; then
        route_note "README marker is absent: ${readme_marker}"
      fi
      case "${target}" in
        /*|../*|*/../*|*/..) route_note "target must stay repository-relative: ${target}" ;;
      esac
      if [ -z "${control}" ] || [ "${control}" = "-" ]; then
        route_note "must declare a pressure or lifecycle control"
      fi

      case "${kind}" in
        file|generated_file|collection)
          for value in "${max_files}" "${max_lines_each}" "${max_bytes_each}" \
              "${max_lines_total}" "${max_bytes_total}"; do
            if ! is_positive_integer "${value}"; then
              route_note "has a missing or invalid positive budget: ${value}"
            fi
          done

          route_files=()
          if [ "${kind}" = "collection" ]; then
            mapfile -t route_files < <(compgen -G "${target}" | LC_ALL=C sort || true)
          elif [ -f "${target}" ]; then
            route_files=("${target}")
          fi
          if [ "${#route_files[@]}" -eq 0 ]; then
            route_note "target matched no regular files: ${target}"
          elif [ "${route_failed}" -eq 0 ]; then
            route_lines_total=0
            route_bytes_total=0
            if [ "${#route_files[@]}" -gt "${max_files}" ]; then
              route_note "has ${#route_files[@]} files (> cap ${max_files})"
            fi
            for route_file in "${route_files[@]}"; do
              if [ ! -f "${route_file}" ]; then
                route_note "matched a non-file target: ${route_file}"
                continue
              fi
              route_lines=$(wc -l < "${route_file}" | tr -d ' ')
              route_bytes=$(wc -c < "${route_file}" | tr -d ' ')
              route_lines_total=$((route_lines_total + route_lines))
              route_bytes_total=$((route_bytes_total + route_bytes))
              if [ "${route_lines}" -gt "${max_lines_each}" ]; then
                route_note "${route_file} is ${route_lines} lines (> per-file cap ${max_lines_each})"
              fi
              if [ "${route_bytes}" -gt "${max_bytes_each}" ]; then
                route_note "${route_file} is ${route_bytes} bytes (> per-file cap ${max_bytes_each})"
              fi
            done
            if [ "${route_lines_total}" -gt "${max_lines_total}" ]; then
              route_note "is ${route_lines_total} lines total (> cap ${max_lines_total})"
            fi
            if [ "${route_bytes_total}" -gt "${max_bytes_total}" ]; then
              route_note "is ${route_bytes_total} bytes total (> cap ${max_bytes_total})"
            fi
            if [ "${route_failed}" -eq 0 ]; then
              ok "route ${route_id}: ${#route_files[@]} file(s), ${route_lines_total} lines, ${route_bytes_total} bytes (${control})"
            fi
          fi
          ;;
        query)
          if [ "${max_files}${max_lines_each}${max_bytes_each}${max_lines_total}${max_bytes_total}" != "-----" ]; then
            route_note "query routes use lifecycle controls, not file budgets"
          elif [ ! -x "${target}" ]; then
            route_note "query target is absent or not executable: ${target}"
          elif [ "${route_failed}" -eq 0 ]; then
            ok "route ${route_id}: query terminal ${target} (${control})"
          fi
          ;;
        archive)
          if [ "${max_files}${max_lines_each}${max_bytes_each}${max_lines_total}${max_bytes_total}" != "-----" ]; then
            route_note "archive routes use lifecycle controls, not file budgets"
          elif [ ! -d "${target}" ]; then
            route_note "archive target is absent: ${target}"
          elif [ "${route_failed}" -eq 0 ]; then
            ok "route ${route_id}: archive terminal ${target} (${control})"
          fi
          ;;
        frozen)
          if [ "${max_files}${max_lines_each}${max_bytes_each}${max_lines_total}${max_bytes_total}" != "-----" ]; then
            route_note "frozen routes use a content identity, not growth budgets"
          elif [ ! -f "${target}" ]; then
            route_note "frozen target is absent: ${target}"
          elif [[ ! "${control}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
            route_note "frozen control must be sha256:<64 lowercase hex digits>"
          else
            expected_sha256="${control#sha256:}"
            actual_sha256=$(sha256sum "${target}" | awk '{print $1}')
            if [ "${actual_sha256}" != "${expected_sha256}" ]; then
              route_note "frozen target changed (${actual_sha256} != ${expected_sha256})"
            elif [ "${route_failed}" -eq 0 ]; then
              ok "route ${route_id}: frozen identity ${expected_sha256}"
            fi
          fi
          ;;
        *)
          route_note "has unknown kind: ${kind}"
          ;;
      esac
    done < <(tail -n +2 "${ROUTE_REGISTRY}")

    for route_id in "${required_routes[@]}"; do
      if [ -z "${seen_routes[${route_id}]+x}" ]; then
        note "required routed destination is undeclared: ${route_id}"
      fi
    done
  fi
fi

if [ "${fail}" -eq 0 ]; then
  printf 'readme-entrypoint: all README entry-point invariants hold\n'
  printf 'readme-entrypoint: all routed-destination pressure invariants hold\n'
fi
exit "${fail}"
