# R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP: Self-Dependency Diagnostic Cleanup

## Metadata

- Tree ID: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`
- Status: `done`
- Roadmap lane: `R10`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Clean direct assignment self-dependency diagnostics so users see targeted
source-local messages without Perl parser stack frames.

## Non-Goals

- Do not change self-dependency semantics or HDL generation.
- Do not broaden assignment legality.
- Do not rewrite unrelated parser diagnostics.
- Do not alter machine JSON schema shape.

## Acceptance Criteria

- Illegal combinational self-dependency diagnostics remain targeted and
  actionable.
- CLI, check-JSON, and normalized semantic JSON failure output no longer leaks
  `Parser.pm line ...` implementation locations or `called at` stack frames
  for the selected self-dependency family.
- Existing self-dependency tests and regression-corpus accounting continue to
  pass.
- mdBook/live docs are synchronized if user-facing diagnostic behavior changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`
  Status: `done`
  Goal: `Remove stack-frame leakage from selected direct self-dependency diagnostics.`
  Children: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1`,
    `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2`

- ID: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1`
  Status: `done`
  Goal: `Activate the R10 self-dependency diagnostic cleanup task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to the selected self-dependency diagnostic cleanup.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1: select self-dependency diagnostic cleanup`

- ID: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2`
  Status: `done`
  Goal: `Clean stack-frame leakage from illegal combinational self-dependency diagnostics.`
  Acceptance: `The selected combinational self-dependency failure still rejects before HDL emission with the existing actionable message, but CLI/check-JSON/semantic-JSON output contains no raw parser implementation frame or Perl call stack; focused tests and live docs pass.`
  Verification: `passed: syntax checks, focused self-dependency/check-JSON/semantic-JSON diagnostics tests, regression-corpus accounting, feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2: clean self-dependency diagnostics`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` | `done` | The selected illegal combinational self-dependency diagnostic is now source-facing and stack-free through quiet CLI, check JSON, and normalized semantic JSON. |

## Decisions

- `2026-05-24`: Select the illegal combinational self-dependency diagnostic
  as the next bounded `R10` cleanup. This is a direct generation failure
  family documented in the mdBook and already covered by regression fixtures,
  but the then-current quiet CLI surface still leaked parser implementation
  frames.
- `2026-05-24`: Close the tree after `.2`. The selected diagnostic now raises
  a plain source-facing error instead of a Perl `confess` exception, preserving
  the rejection, dependency path, and remediation while removing parser
  filenames, parser routine names, and Perl stack frames from the covered
  public surfaces.

## Open Questions

- None. The tree is closed.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c t/1348-self-dependency-diagnostic-cleanup.t`; `prove -Iperl t/1348-self-dependency-diagnostic-cleanup.t t/02-combinational-self-dependency.t t/299-check-json-diagnostics.t t/634-normalized-semantic-snapshot-failure-boundary.t t/636-normalized-semantic-diagnostic-summary.t t/637-check-json-diagnostic-summary.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused diagnostics tests Files=6, Tests=26; regression-corpus accounting Files=1, Tests=3149; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1` | `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1: select self-dependency diagnostic cleanup` | `selection slice` |
| `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` | `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2: clean self-dependency diagnostics` | `implementation close-out slice` |

## Changelog

- `2026-05-24`: Created active `R10` self-dependency diagnostic cleanup tree
  and selected `.2` as the implementation frontier.
- `2026-05-24`: Completed `.2` and closed the tree. Illegal combinational
  self-dependency diagnostics now remain targeted while avoiding parser
  implementation leakage across quiet CLI, check JSON, and normalized semantic
  JSON.
