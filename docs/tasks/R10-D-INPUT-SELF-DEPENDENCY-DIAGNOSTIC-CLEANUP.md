# R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP: D-Input Self-Dependency Diagnostic Cleanup

## Metadata

- Tree ID: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`
- Status: `done`
- Roadmap lane: `R10`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Clean D-input-named sequential self-dependency diagnostics so users see
targeted source-local messages without parser implementation names or Perl
stack-frame leakage.

## Non-Goals

- Do not change D-input self-dependency legality.
- Do not broaden `<=`, `<=-`, or legacy `<=+` behavior.
- Do not alter generated HDL, scheduler behavior, or public JSON schema shape.
- Do not rewrite unrelated parser diagnostics.

## Acceptance Criteria

- Illegal D-input self-dependency diagnostics remain targeted and actionable
  for RHS and guard-expression failures.
- CLI, check-JSON, and normalized semantic JSON failure output no longer leaks
  `Parser.pm`, `validate_no_register_input_self_dependency`, `Parser.pm line
  ...`, or `called at` stack frames for the selected D-input self-dependency
  family.
- Existing self-dependency tests and regression-corpus accounting continue to
  pass.
- mdBook/live docs are synchronized if user-facing diagnostic behavior changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`
  Status: `done`
  Goal: `Remove parser implementation leakage from selected D-input self-dependency diagnostics.`
  Children: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1`,
    `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2`

- ID: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1`
  Status: `done`
  Goal: `Activate the R10 D-input self-dependency diagnostic cleanup task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to the selected D-input self-dependency diagnostic cleanup.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1: select D-input diagnostic cleanup`

- ID: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2`
  Status: `done`
  Goal: `Clean parser implementation leakage from illegal D-input self-dependency diagnostics.`
  Acceptance: `The selected D-input self-dependency failures still reject before HDL emission with actionable guidance, but CLI/check-JSON/semantic-JSON output contains no parser implementation names, raw parser implementation frames, or Perl call stack; focused tests and live docs pass.`
  Verification: `passed: syntax checks, focused D-input/self-dependency/check-JSON/semantic-JSON diagnostics tests, regression-corpus accounting, feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2: clean D-input diagnostics`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` | `done` | The selected D-input self-dependency diagnostics are now source-facing and stack-free through quiet CLI, check JSON, and normalized semantic JSON. |

## Decisions

- `2026-05-24`: Select the D-input self-dependency diagnostic as the next
  bounded `R10` cleanup after closing the combinational self-dependency
  cleanup. The parser already rejects the construct before HDL emission and
  the mdBook already describes the legality rule; the remaining gap is public
  diagnostic presentation.
- `2026-05-24`: Close the tree after `.2`. The selected diagnostic now raises
  a plain source-facing error instead of a Perl `confess` exception, preserving
  the D-input rejection, offending expression role, self-dependent signal, and
  remediation while removing parser filenames, parser routine names, and Perl
  stack frames from the covered public surfaces.

## Open Questions

- None. The tree is closed.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c t/1349-d-input-self-dependency-diagnostic-cleanup.t`; `prove -Iperl t/1349-d-input-self-dependency-diagnostic-cleanup.t t/1348-self-dependency-diagnostic-cleanup.t t/02-combinational-self-dependency.t t/299-check-json-diagnostics.t t/634-normalized-semantic-snapshot-failure-boundary.t t/636-normalized-semantic-diagnostic-summary.t t/637-check-json-diagnostic-summary.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused diagnostics tests Files=7, Tests=32; regression-corpus accounting Files=1, Tests=3149; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1` | `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1: select D-input diagnostic cleanup` | `selection slice` |
| `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` | `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2: clean D-input diagnostics` | `implementation close-out slice` |

## Changelog

- `2026-05-24`: Created active `R10` D-input self-dependency diagnostic
  cleanup tree and selected `.2` as the implementation frontier.
- `2026-05-24`: Completed `.2` and closed the tree. Illegal D-input
  self-dependency diagnostics now remain targeted while avoiding parser
  implementation leakage across quiet CLI, check JSON, and normalized semantic
  JSON.
