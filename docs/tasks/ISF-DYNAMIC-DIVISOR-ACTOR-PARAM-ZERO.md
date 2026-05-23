# ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO: Dynamic Divisor Actor-Parameter Zero Safety

## Metadata

- Tree ID: `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Reject ISF runtime division and modulo expressions whose divisor names an
actor-local scalar parameter default that resolves to zero.

## Non-Goals

- Do not prove arbitrary dynamic scalar divisors nonzero.
- Do not accept nonzero actor parameters as proof that every use-site
  specialization is nonzero.
- Do not evaluate transaction parameters as divisor constants.
- Do not add generated runtime divide guards or rewrite authored expressions.
- Do not extend division/modulo validation outside shipped ISF runtime
  expression contexts.

## Acceptance Criteria

- Actor-local scalar parameter defaults that resolve to zero fail closed when
  used as division or modulo divisors in shipped runtime expression contexts.
- Diagnostics identify the owning expression context, authored divisor token,
  and division/modulo operator family.
- Nonzero actor parameters, transaction parameters, dynamic scalar divisors,
  nonzero literals, and nonzero actor constants keep their shipped behavior.
- The ISF spec, downstream handoff, public contract, mdBook, task index,
  roadmap status, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO`
  Status: `active`
  Goal: `Close actor-parameter-zero divisor safety inside shipped ISF runtime expressions.`
  Children: `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.1`,
  `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2`

- ID: `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.1`
  Status: `done`
  Goal: `Select actor-parameter-zero divisor rejection.`
  Acceptance: `Create the active task tree, define the fail-closed source
  boundary, preserve non-goals, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2`
  Status: `pending`
  Goal: `Implement and document actor-parameter-zero divisor rejection.`
  Acceptance: `Zero-valued actor scalar parameters fail closed as runtime
  division/modulo divisors; nonzero actor parameters and dynamic divisors keep
  shipped behavior; specs, book, public contract, downstream handoff, and
  focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2` | `pending` | The source boundary is selected; implementation can extend the shipped literal-zero and actor-constant-zero divisor validation path with actor-parameter-zero rejection only. |

## Decisions

- `2026-05-23`: Select only zero-valued actor-local scalar parameter defaults
  for fail-closed divisor safety. Rejecting a default that resolves to zero is
  conservative and does not claim that nonzero actor-parameter defaults prove
  every use-site specialization nonzero.
- `2026-05-23`: Preserve authored nonzero actor parameters as normal symbolic
  divisors. Proving them safe would require a separate specialization policy,
  range proof, or generated runtime guard.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.1` | `this commit: ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.1: select actor-param zero divisors` | `selects actor-parameter-zero dynamic-divisor safety` |
| `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-parameter-zero divisor
  rejection.
