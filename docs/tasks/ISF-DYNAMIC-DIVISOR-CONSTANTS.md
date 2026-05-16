# ISF-DYNAMIC-DIVISOR-CONSTANTS: Dynamic Divisor Actor Constant Safety

## Metadata

- Tree ID: `ISF-DYNAMIC-DIVISOR-CONSTANTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Reject ISF runtime division and modulo expressions whose divisor is an
actor-level constant that resolves to zero.

## Non-Goals

- Proving arbitrary runtime scalar divisors nonzero.
- Evaluating actor parameters or transaction parameters as divisor constants.
- Extending division/modulo validation outside shipped ISF runtime expression
  contexts.

## Acceptance Criteria

- Actor constants that resolve to zero fail closed when used as division or
  modulo divisors in shipped runtime expression contexts.
- Nonzero actor constants remain accepted and lower as authored constants in
  scheduled `.fsm` review artifacts.
- Dynamic scalar divisors still lower unchanged.
- Diagnostics identify the owning expression context, authored divisor token,
  and division/modulo operator family.
- The ISF spec, downstream handoff, mdBook, public contract, live docs, and
  backlog boundary stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-DIVISOR-CONSTANTS`
  Status: `done`
  Goal: `Close actor-constant zero divisor safety inside shipped ISF runtime expressions.`
  Children: `ISF-DYNAMIC-DIVISOR-CONSTANTS.1`

- ID: `ISF-DYNAMIC-DIVISOR-CONSTANTS.1`
  Status: `done`
  Goal: `Reject actor-level zero constants used as runtime division/modulo divisors.`
  Acceptance: `Parser validation rejects zero actor constants, preserves nonzero constants and dynamic divisors, documents the exact boundary, and passes focused plus ISF regression gates.`
  Verification: `prove -l t/1308-isf-dynamic-divisor-safety.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-DYNAMIC-DIVISOR-CONSTANTS.1: reject actor zero constant divisors`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-DIVISOR-CONSTANTS.1` | `done` | Shipped in this tree; no remaining frontier. |

## Decisions

- `2026-05-16`: Treat actor constants as compile-time divisor facts, not
  runtime dynamic divisors.
- `2026-05-16`: Keep actor parameters out of this slice because they are
  overrideable and require a separate specialization-time policy.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-DIVISOR-CONSTANTS.1` | `prove -l t/1308-isf-dynamic-divisor-safety.t t/1305-isf-book-feature-matrix-audit.t` | `PASS: Files=2, Tests=87` |
| `2026-05-16` | `ISF-DYNAMIC-DIVISOR-CONSTANTS.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-DYNAMIC-DIVISOR-CONSTANTS.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=214, Tests=939` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-DIVISOR-CONSTANTS.1` | `ISF-DYNAMIC-DIVISOR-CONSTANTS.1: reject actor zero constant divisors` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started actor-constant zero divisor
  safety slice.
- `2026-05-16`: Shipped actor-constant zero divisor rejection, including
  enum-resolved zero constants, nonzero-constant preservation, spec/book/
  downstream/public-contract synchronization, and focused plus broad
  validation.
