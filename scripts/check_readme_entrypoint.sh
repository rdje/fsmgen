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
#                  README and maps to the common live-document surface graph.
#                  The common checker owns lifecycle and pressure semantics so
#                  thresholds have one authority rather than two copies.
#
# Knob (env): README_MAX_LEAF_REFS_PER_LINE.
#
# The doctrine driver invokes this check unconditionally. Do not scope the
# landing-page tree invariant to staged or changed paths.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [ "$#" -gt 0 ]; then
  if [ "$#" -ne 2 ] || [ "$1" != "--root" ] || [ ! -d "$2" ]; then
    printf 'Usage: %s [--root REPOSITORY_ROOT]\n' "$0" >&2
    exit 2
  fi
  ROOT_DIR="$(cd "$2" && pwd)"
fi
cd "${ROOT_DIR}"

MAX_REFS="${README_MAX_LEAF_REFS_PER_LINE:-1}"
ROUTE_REGISTRY="doctrine/readme_entrypoint/routed_destinations.jsonl"
SURFACE_REGISTRY="doctrine/live_document_size/surfaces.jsonl"
LIVE_DOCUMENT_CHECKER="${SCRIPT_DIR}/check_live_document_size.sh"
fail=0

note() { printf 'readme-entrypoint: %s\n' "$1" >&2; fail=1; }
ok()   { printf 'readme-entrypoint: ok:   %s\n' "$1"; }
route_hint() {
  local route_kind="$1" target_surface_id="$2" marker="$3" message="$4"
  note "  ${message}"
}

if [ ! -f README.md ]; then
  note "README.md is missing (it is the declared single entry point)"
  exit 1
fi

if [ ! -f "${SURFACE_REGISTRY}" ]; then
  note "live-document surface registry is missing: ${SURFACE_REGISTRY}"
  LINE_CAP=0
  BYTE_CAP=0
else
  read -r LINE_CAP BYTE_CAP < <(
    perl -MJSON::PP -e '
      while (<>) {
        my $record = eval { decode_json($_) } or next;
        next if ($record->{surface_id} // q{}) ne q{readme_entrypoint};
        print(($record->{enforcement_ceilings}{lines_each} // q{0}), q{ },
              ($record->{enforcement_ceilings}{bytes_each} // q{0}), qq{\n});
        exit 0;
      }
      exit 1;
    ' "${SURFACE_REGISTRY}"
  ) || { LINE_CAP=0; BYTE_CAP=0; }
  if [[ ! "${LINE_CAP}" =~ ^[1-9][0-9]*$ ]] || [[ ! "${BYTE_CAP}" =~ ^[1-9][0-9]*$ ]]; then
    note "readme_entrypoint has invalid line/byte limits in ${SURFACE_REGISTRY}"
    LINE_CAP=0
    BYTE_CAP=0
  fi
fi

# 1. Size cap.
lines=$(wc -l < README.md | tr -d ' ')
if [ "${lines}" -le "${LINE_CAP}" ]; then
  ok "README.md is ${lines} lines (<= cap ${LINE_CAP})"
else
  note "README.md is ${lines} lines (> cap ${LINE_CAP})"
  note "  README.md is a nearly static landing page (docs/decisions/0024)."
  route_hint author_overflow task_evidence 'docs/tasks/' 'Move per-leaf detail to its owning task-tree under docs/tasks/.'
  route_hint author_overflow rationale 'docs/decisions/' 'Move durable cross-cutting facts to docs/decisions/.'
  route_hint author_overflow shipped_behavior 'docs/book/' 'Move user-facing behavior to docs/book/.'
  route_hint author_overflow exact_history 'git log --grep=<UNIT-ID>' 'Leave exact chronology to git log --grep=<UNIT-ID>.'
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

# 3. README marker-to-surface routing plus common pressure closure.
required_routes=(
  shipped_behavior reported_capabilities high_level_direction active_resume
  active_index task_evidence rationale engineering_rationale fact_index
  exact_history diagnostics enforced_rules
)
declare -A required_route_ids=()
for required_route_id in "${required_routes[@]}"; do
  required_route_ids["${required_route_id}"]=1
done

route_note() {
  note "  route ${route_id}: $1"
  route_failed=1
}

if [ ! -f "${ROUTE_REGISTRY}" ]; then
  note "routed-destination registry is missing: ${ROUTE_REGISTRY}"
else
  route_records=$(perl -MJSON::PP -e '
    my @keys = qw(route_id route_kind source_path source_surface_id marker target_surface_id);
    while (<>) {
      my $line = $.;
      my $record = eval { decode_json($_) };
      die "line $line is invalid JSON: $@" if $@;
      die "line $line must be an object\n" if ref($record) ne q{HASH};
      next if ($record->{record_type} // q{}) eq q{registry};
      for my $key (@keys) {
        die "line $line is missing $key\n" if !exists($record->{$key});
        die "line $line has invalid $key\n"
          if ref($record->{$key}) || $record->{$key} eq q{}
            || $record->{$key} =~ /[\t\r\n]/;
      }
      my %allowed = map { $_ => 1 } @keys;
      for my $key (keys %{$record}) {
        die "line $line has unknown key $key\n" if !$allowed{$key};
      }
      print join(qq{\t}, @{$record}{@keys}), qq{\n};
    }
  ' "${ROUTE_REGISTRY}" 2>&1)
  route_status=$?
  surface_ids=$(perl -MJSON::PP -e '
    while (<>) {
      my $record = eval { decode_json($_) } or next;
      print $record->{surface_id}, qq{\n}
        if !ref($record->{surface_id}) && defined($record->{surface_id});
    }
  ' "${SURFACE_REGISTRY}" 2>/dev/null)
  if [ "${route_status}" -ne 0 ]; then
    note "${ROUTE_REGISTRY} is invalid JSONL: ${route_records}"
  else
    declare -A seen_routes=()
    while IFS=$'\t' read -r route_id route_kind source_path source_surface_id route_marker target_surface_id; do
      [ -z "${route_id}" ] && continue
      route_failed=0

      if [ "${source_surface_id}" != "readme_entrypoint" ]; then
        if [ -n "${required_route_ids[${route_id}]+x}" ]; then
          route_note "must originate at readme_entrypoint: ${source_surface_id}"
        fi
        continue
      fi

      case "${route_id}" in
        *[!a-z0-9_]*) route_note "has an invalid route_id" ;;
      esac
      case "${route_kind}" in
        author_overflow|reader_navigation) ;;
        *) route_note "has an invalid route_kind: ${route_kind}" ;;
      esac
      if [ -n "${seen_routes[${route_id}]+x}" ]; then
        route_note "is declared more than once"
      else
        seen_routes["${route_id}"]=1
      fi
      if [ ! -f "${source_path}" ]; then
        route_note "source path is absent: ${source_path}"
      elif [ -z "${route_marker}" ] || ! grep -Fq -- "${route_marker}" "${source_path}"; then
        route_note "${source_path} marker is absent: ${route_marker}"
      fi
      if [ -z "${target_surface_id}" ] || ! grep -Fxq -- "${target_surface_id}" <<< "${surface_ids}"; then
        route_note "targets an undeclared live-document surface: ${target_surface_id}"
      fi
      if [ "${route_failed}" -eq 0 ]; then
        ok "route ${route_id}: ${route_kind} ${source_path} marker -> ${target_surface_id}"
      fi
    done <<< "${route_records}"

    for route_id in "${required_routes[@]}"; do
      if [ -z "${seen_routes[${route_id}]+x}" ]; then
        note "required routed destination is undeclared: ${route_id}"
      fi
    done
  fi
fi

if [ ! -x "${LIVE_DOCUMENT_CHECKER}" ]; then
  note "common live-document checker is missing or not executable: scripts/check_live_document_size.sh"
elif ! "${LIVE_DOCUMENT_CHECKER}" --root "${ROOT_DIR}"; then
  note "common live-document size-containment check failed"
fi

if [ "${fail}" -eq 0 ]; then
  printf 'readme-entrypoint: all README entry-point invariants hold\n'
  printf 'readme-entrypoint: all routed-destination pressure invariants hold\n'
fi
exit "${fail}"
