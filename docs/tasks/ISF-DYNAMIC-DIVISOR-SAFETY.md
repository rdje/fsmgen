# ISF-DYNAMIC-DIVISOR-SAFETY: Dynamic Divisor Safety

## Metadata

- Tree ID: `ISF-DYNAMIC-DIVISOR-SAFETY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Fail closed on ISF division and modulo expressions whose divisor is statically
known to be literal zero, and keep the shipped/backlog boundary clear for
broader dynamic nonzero proofs.

## Non-Goals

- Proving that arbitrary runtime scalar divisors are nonzero.
- Rewriting user expressions or introducing generated runtime divide guards.
- Changing the scheduled `.fsm` expression syntax for nonzero or dynamic
  divisors.

## Acceptance Criteria

- Literal-zero divisor operands in shipped ISF runtime expression positions are
  rejected before scheduled `.fsm` emission.
- Nonzero literal divisors and dynamic scalar divisors continue to lower
  unchanged.
- Focused validation covers rejected division, rejected modulo, accepted
  nonzero literals, accepted dynamic divisors, and at least one activation or
  wait expression context.
- `docs/ISF_SPEC.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, the mdBook,
  and live docs describe the exact shipped boundary and remaining backlog.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-DIVISOR-SAFETY`
  Status: `done`
  Goal: `Close the literal-zero divisor hole while preserving the dynamic-proof backlog boundary.`
  Children: `ISF-DYNAMIC-DIVISOR-SAFETY.1`

- ID: `ISF-DYNAMIC-DIVISOR-SAFETY.1`
  Status: `done`
  Goal: `Reject literal-zero division/modulo divisors in shipped ISF expression surfaces.`
  Acceptance: `Parser/scheduler rejects literal-zero divisors, accepts nonzero and dynamic divisors, documents the boundary, and passes focused plus ISF regression gates.`
  Verification: `prove -l t/1308-isf-dynamic-divisor-safety.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-DYNAMIC-DIVISOR-SAFETY.1: reject literal-zero divisors`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-DIVISOR-SAFETY.1` | `done` | Literal-zero divisor detection shipped and documented; broader dynamic nonzero proof remains backlog. |

## Decisions

- `2026-05-16`: Keep this first slice to statically literal-zero divisors only. Runtime scalar nonzero proofs require dataflow/range analysis and remain backlog.
- `2026-05-16`: Validate the authored ISF AST before scheduled `.fsm` emission so downstream consumers get an early, context-rich diagnostic.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-DIVISOR-SAFETY.1` | `prove -l t/1308-isf-dynamic-divisor-safety.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t` | `PASS: Files=4, Tests=86` |
| `2026-05-16` | `ISF-DYNAMIC-DIVISOR-SAFETY.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=214, Tests=930` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-DIVISOR-SAFETY.1` | `8c995e9e ISF-DYNAMIC-DIVISOR-SAFETY.1: reject literal-zero divisors` | `completion commit` |

## Changelog

- `2026-05-16`: Created task tree and started the literal-zero divisor safety leaf.
- `2026-05-16`: Completed literal-zero divisor parser validation, focused tests, ISF spec/downstream/public-contract/mdBook synchronization, and broad ISF regression.
