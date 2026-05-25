# CI-FULL-REGRESSION-GREEN: Hosted Full Regression Green Gate

## Metadata

- Tree ID: `CI-FULL-REGRESSION-GREEN`
- Status: `done`
- Roadmap lane: `project operations`
- Created: `2026-05-19`
- Last updated: `2026-05-19`
- Owner: repo-local workflow

## Goal

Restore the hosted `Perl FSM Regression` workflow to a green full regression
gate after the Perl 5.32 compatibility blockers have been removed.

## Non-Goals

- Do not change ISF syntax, ATL syntax, or downstream `.isf` integration
  contracts unless a failing test proves a required behavioral correction.
- Do not weaken assertions, skip failing tests, or reduce hosted CI coverage to
  hide regressions.
- Do not alter the project push cadence policy beyond publishing CI fixes when
  they are ready for GitHub validation.

## Acceptance Criteria

- Every locally reproducible full-regression failure that still blocks
  `./bin/ci-regression` is root-caused and fixed or explicitly split into a
  smaller tracked blocker.
- Focused tests for each fixed failure pass.
- `./bin/ci-regression quick --no-book` and the relevant focused suites pass.
- `./bin/ci-regression full --no-book` is rerun after the fixes, with any
  remaining failures documented precisely.
- `mdbook build docs/book` passes when documentation is changed.
- Live docs and task-tree status are synchronized.
- Each completed leaf is committed through `COMMIT.md` and pushed promptly when
  it restores hosted CI.

## Task Tree

- ID: `CI-FULL-REGRESSION-GREEN`
  Status: `done`
  Goal: `Restore the hosted full regression workflow to a green gate.`
  Children: `CI-FULL-REGRESSION-GREEN.1`

- ID: `CI-FULL-REGRESSION-GREEN.1`
  Status: `done`
  Goal: `Root-cause and repair the five locally reproducible full-regression failures that remain after the Perl 5.32 compatibility fix.`
  Acceptance: `The five known failing test files are reproduced, corrected through focused source/test changes, validated locally, documented, committed, and pushed for hosted CI rerun.`
  Verification: `focused five-test cluster; ./bin/ci-regression quick --no-book; ./bin/ci-regression full --no-book; mdbook build docs/book; git diff --check`
  Commit: `de04debd CI-FULL-REGRESSION-GREEN.1: restore full regression gate`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `CI-FULL-REGRESSION-GREEN.1` | `done` | The stale regression contracts have been aligned with shipped behavior and the local full gate is green. |

## Decisions

- `2026-05-19`: Keep the remaining red full-regression gate in a separate
  project-operations task tree so the original Perl 5.32 compatibility fix
  remains a closed, reviewable slice.
- `2026-05-19`: Do not weaken `./bin/ci-regression`; the hosted workflow should
  keep exercising the same full regression entrypoint used locally.
- `2026-05-19`: Treat the five remaining failures as stale regression
  contracts rather than production compiler bugs: each one reproduced before
  this slice, and the fixes align tests with behavior that is already
  documented or intentionally covered elsewhere.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-19` | `CI-FULL-REGRESSION-GREEN.1` | `./bin/ci-regression full --no-book` before this tree was created, during `CI-PERL-532-REGRESSION-COMPAT.1` validation | failed on `t/214-factorization-fixpoint-pass-support.t`, `t/217-factorization-fixpoint-pass-execution-support.t`, `t/25-composition-legacy-scope-errors.t`, `t/310-systemverilog-implicit-width-and-truthiness-hardening.t`, and `t/44-language-contract-relational-operators.t` |
| `2026-05-19` | `CI-FULL-REGRESSION-GREEN.1` | detached clean baseline replay at pre-fix `HEAD` for the same five test files | failed on the same five files, proving these failures pre-date the Perl 5.32 compatibility slice |
| `2026-05-19` | `CI-FULL-REGRESSION-GREEN.1` | `prove -Iperl -v t/214-factorization-fixpoint-pass-support.t t/217-factorization-fixpoint-pass-execution-support.t t/25-composition-legacy-scope-errors.t t/310-systemverilog-implicit-width-and-truthiness-hardening.t t/44-language-contract-relational-operators.t` | passed |
| `2026-05-19` | `CI-FULL-REGRESSION-GREEN.1` | `./bin/ci-regression quick --no-book` | passed: 8 files, 145 tests |
| `2026-05-19` | `CI-FULL-REGRESSION-GREEN.1` | `./bin/ci-regression full --no-book` | passed: 1328 files, 6199 tests |
| `2026-05-19` | `CI-FULL-REGRESSION-GREEN.1` | `mdbook build docs/book`; `git diff --check` | passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-FULL-REGRESSION-GREEN.1` | `CI-FULL-REGRESSION-GREEN.1: restore full regression gate` | Aligns stale regression contracts with shipped behavior and restores the local full regression gate. |

## Changelog

- `2026-05-19`: Created task tree for the remaining hosted full-regression
  failures after the Perl 5.32 compatibility slice.
- `2026-05-19`: Closed the task tree after the focused five-test cluster and
  local full regression passed.
