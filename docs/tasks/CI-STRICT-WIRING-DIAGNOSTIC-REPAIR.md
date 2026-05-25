# CI-STRICT-WIRING-DIAGNOSTIC-REPAIR: Hosted Strict Wiring and Diagnostic CI Repair

## Metadata

- Tree ID: `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR`
- Status: `active`
- Roadmap lane: `project operations`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Repair the hosted `Perl FSM Regression` failure on run `26386567406` by
bringing stale local tests and generated fixtures back in line with the current
strict composition wiring and direct LHS deconstruct diagnostics.

## Non-Goals

- Do not relax strict mode's rejection of legacy `?wiring` slash-link tokens.
- Do not change `.fsm`, `.isf`, scheduler, HDL, or public API behavior.
- Do not change GitHub workflow definitions unless local reproduction proves
  the workflow is the cause.
- Do not push outside the configured cadence unless explicitly requested for
  hosted CI validation.

## Acceptance Criteria

- The hosted failures are reproduced or otherwise matched locally with focused
  evidence.
- Stale generated test fixtures use canonical strict `?wiring` forms instead
  of legacy slash-link tokens where strict mode is expected.
- The direct LHS deconstruct diagnostic expectation matches the current
  operand-preserving diagnostic text without weakening the asserted contract.
- Focused failing tests pass locally.
- Broader validation runs when the repaired surface warrants it.
- Live docs record the CI diagnosis and repair.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR`
  Status: `active`
  Goal: `Repair hosted strict-wiring and diagnostic expectation CI failures`
  Children: `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.1, CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.2`

- ID: `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.1`
  Status: `done`
  Goal: `Select and scope the hosted CI repair`
  Acceptance: `The CI failure is mapped to a task-tree owner with explicit
  non-goals, acceptance criteria, and the next executable implementation leaf`
  Verification: `live-doc selection audits; mdBook build; git diff check`
  Commit: `pending this commit`

- ID: `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.2`
  Status: `pending`
  Goal: `Repair stale strict wiring fixtures and direct LHS diagnostic expectation`
  Acceptance: `The focused hosted-failing tests pass locally, live docs capture
  the exact repair, and no user-facing behavior changes are introduced`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.2` | `pending` | `The repair scope is selected; the implementation leaf must update stale tests/fixtures and validate the hosted-failing set.` |

## Decisions

- `2026-05-25`: Treat run `26386567406` as a repo-side regression repair, not
  a GitHub workflow repair, because the failed log points at stale local test
  expectations and strict-mode fixtures.
- `2026-05-25`: Preserve strict mode's slash-link rejection. Tests that expect
  strict HDL generation should use canonical `?wiring` list forms.
- `2026-05-25`: Preserve the current direct LHS diagnostic surface unless
  focused reproduction shows a behavior bug; the hosted evidence currently
  indicates a stale expectation around slice-decorated RHS concat text.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.1` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1256-feature-backlog-status-audit.t` | `passed: Files=3, Tests=40` |
| `2026-05-25` | `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.1` | `mdbook build docs/book` | `passed` |
| `2026-05-25` | `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.1` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.1` | `pending this commit` | `selection slice` |
| `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-25`: Created and activated the task tree for the hosted strict
  wiring and direct LHS diagnostic CI repair.
- `2026-05-25`: Closed selection validation with live-doc audits and mdBook
  build passing.
