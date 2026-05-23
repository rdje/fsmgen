# ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE: Dynamic Divisor Drive Coverage

## Metadata

- Tree ID: `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Prove the documented dynamic-divisor zero guards cover ISF drive-call actuals
and inline drive RHS expressions.

## Non-Goals

- Do not change parser, scheduler, emitter, report, generated artifact, or HDL
  behavior.
- Do not widen dynamic-divisor proof beyond the shipped literal-zero and
  actor-constant-zero divisor boundary.
- Do not reject dynamic scalar divisors or parameter divisors in this slice.
- Do not add new source syntax.

## Acceptance Criteria

- Focused dynamic-divisor tests cover named drive-call actual expressions with
  literal-zero divisors.
- Focused dynamic-divisor tests cover inline drive RHS expressions with
  actor-constant-zero divisors.
- Existing dynamic scalar, nonzero literal, and nonzero actor-constant divisor
  behavior remains unchanged.
- Roadmap, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE`
  Status: `done`
  Goal: `Harden focused coverage for documented drive expression divisor guards.`
  Children: `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.1`,
  `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.2`

- ID: `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.1`
  Status: `done`
  Goal: `Select dynamic-divisor drive coverage hardening.`
  Acceptance: `Create the active task tree, scope the drive-call and inline
  drive coverage gap, set the implementation frontier, and update
  roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending commit`

- ID: `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.2`
  Status: `done`
  Goal: `Add drive-surface dynamic-divisor coverage.`
  Acceptance: `Focused tests prove literal-zero divisors fail in named
  drive-call actual expressions and actor-constant-zero divisors fail in
  inline drive RHS expressions; focused dynamic-divisor and doc checks pass.`
  Verification: `perl -Iperl -c t/1308-isf-dynamic-divisor-safety.t`;
  `prove -Iperl t/1308-isf-dynamic-divisor-safety.t`; public/doc audits;
  `mdbook build docs/book`; `git diff --check`
  Commit: `pending commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| | | | No remaining frontier; tree is closed. |

## Decisions

- `2026-05-22`: Select coverage hardening rather than behavior changes. The
  parser already claims to validate drive-call actual and inline drive RHS
  expressions, so this slice should prove the existing boundary without
  widening it.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-22` | `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.2` | `perl -Iperl -c t/1308-isf-dynamic-divisor-safety.t`; `prove -Iperl t/1308-isf-dynamic-divisor-safety.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `focused coverage and doc checks passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.1` | `this commit: ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.1: select divisor drive coverage` | `selects focused coverage hardening for drive expression divisor guards` |
| `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.2` | `this commit: ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.2: cover divisor drive expressions` | `adds focused drive-call actual and inline drive RHS divisor-zero coverage` |

## Changelog

- `2026-05-22`: Created task tree and selected drive-surface dynamic-divisor
  coverage hardening.
- `2026-05-22`: Added focused coverage for named drive-call actual and inline
  drive RHS divisor-zero guards and closed the tree.
