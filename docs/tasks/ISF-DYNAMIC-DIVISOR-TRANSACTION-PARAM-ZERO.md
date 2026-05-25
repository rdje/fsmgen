# ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO: Dynamic Divisor Transaction-Parameter Zero Safety

## Metadata

- Tree ID: `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Reject ISF runtime division and modulo expressions whose divisor names a
same-transaction scalar parameter default that resolves to zero.

## Non-Goals

- Do not prove arbitrary dynamic scalar divisors nonzero.
- Do not accept nonzero transaction parameters as proof that every generated
  use-site specialization is nonzero.
- Do not implement activation-site override-specialized divisor proofs.
- Do not add generated runtime divide guards or rewrite authored expressions.
- Do not widen division/modulo validation outside shipped ISF runtime
  expression contexts.

## Acceptance Criteria

- Same-transaction scalar parameter defaults that resolve to zero fail closed
  when used as division or modulo divisors in shipped runtime expression
  contexts.
- Diagnostics identify the owning expression context, authored divisor token,
  and division/modulo operator family.
- Transaction parameters shadow actor-level static names in the owning
  transaction expression context.
- Nonzero transaction parameters, nonzero actor parameters, dynamic divisors,
  nonzero literals, and nonzero actor constants keep their shipped behavior.
- The ISF spec, downstream handoff, public contract, mdBook, task index,
  roadmap status, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO`
  Status: `done`
  Goal: `Close zero-valued same-transaction parameter divisor safety inside shipped ISF runtime expressions.`
  Children: `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.1`

- ID: `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.1`
  Status: `done`
  Goal: `Implement and document transaction-parameter-zero divisor rejection.`
  Acceptance: `Zero-valued same-transaction scalar parameter defaults fail
  closed as runtime division/modulo divisors; transaction-local name shadowing
  is preserved; nonzero transaction parameters and dynamic divisors keep
  shipped behavior; specs, book, public contract, downstream handoff, and
  focused tests are synchronized.`
  Verification: `syntax checks; focused dynamic-divisor/public-doc tests Files=6, Tests=360; ci-regression isf --no-book Files=275, Tests=1754; mdbook build docs/book; git diff --check`
  Commit: `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.1: reject transaction-param zero divisors`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.1` shipped zero-valued same-transaction parameter divisor rejection. |

## Decisions

- `2026-05-25`: Select only zero-valued same-transaction scalar parameter
  defaults for fail-closed divisor safety. Rejecting a default that resolves
  to zero is conservative and does not claim that nonzero transaction
  parameters prove every use-site specialization nonzero.
- `2026-05-25`: Preserve authored nonzero transaction parameters as normal
  symbolic divisors where the generated child scheduled `.fsm` already carries
  those transaction parameters. Direct transaction parameters that are local
  lowering inputs remain governed by existing direct-transaction parameter
  support rules.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.1` | syntax checks; focused dynamic-divisor/public-doc tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused `Files=6, Tests=360`; broad ISF `Files=275, Tests=1754` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.1` | `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.1: reject transaction-param zero divisors` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created task tree and selected
  same-transaction-parameter-zero divisor rejection.
- `2026-05-25`: Implemented and documented transaction-parameter-zero divisor
  rejection; closed the tree.
