# R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP: Self-Dependency Diagnostic Cleanup

## Metadata

- Tree ID: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`
- Status: `active`
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
  Status: `active`
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
  Status: `pending`
  Goal: `Clean stack-frame leakage from illegal combinational self-dependency diagnostics.`
  Acceptance: `The selected combinational self-dependency failure still rejects before HDL emission with the existing actionable message, but CLI/check-JSON/semantic-JSON output contains no raw parser implementation frame or Perl call stack; focused tests and live docs pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` | `pending` | A corpus probe found that `assignment_comb_self_dependency.fsm` still leaks `Parser.pm line ...` and `called at` frames through quiet CLI failure output. |

## Decisions

- `2026-05-24`: Select the illegal combinational self-dependency diagnostic
  as the next bounded `R10` cleanup. This is a direct generation failure
  family documented in the mdBook and already covered by regression fixtures,
  but the current quiet CLI surface still leaks parser implementation frames.

## Open Questions

- None. `.2` owns the selected self-dependency diagnostic cleanup.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1` | `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1: select self-dependency diagnostic cleanup` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R10` self-dependency diagnostic cleanup tree
  and selected `.2` as the implementation frontier.
