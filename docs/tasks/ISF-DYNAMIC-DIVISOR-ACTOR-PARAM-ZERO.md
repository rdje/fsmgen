# ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO: Dynamic Divisor Actor-Parameter Zero Safety

## Metadata

- Tree ID: `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO`
- Status: `done`
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
  Status: `done`
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
  Commit: `f7cd9c76`

- ID: `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2`
  Status: `done`
  Goal: `Implement and document actor-parameter-zero divisor rejection.`
  Acceptance: `Zero-valued actor scalar parameters fail closed as runtime
  division/modulo divisors; nonzero actor parameters and dynamic divisors keep
  shipped behavior; specs, book, public contract, downstream handoff, and
  focused tests are synchronized.`
  Verification: `syntax`; `focused dynamic-divisor/public/doc tests`;
  `mdbook build docs/book`; `git diff --check`;
  `./bin/ci-regression isf --no-book`
  Commit: `this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| | | | No remaining frontier; tree is closed. |

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
| `2026-05-23` | `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c t/1308-isf-dynamic-divisor-safety.t`; `prove -Iperl t/1308-isf-dynamic-divisor-safety.t`; `prove -Iperl t/1308-isf-dynamic-divisor-safety.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book` | `passed; broad gate Files=238, Tests=1615` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.1` | `f7cd9c76 ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.1: select actor-param zero divisors` | `selects actor-parameter-zero dynamic-divisor safety` |
| `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2` | `this commit: ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2: ship actor-param zero divisors` | `ships actor-parameter-zero dynamic-divisor safety` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-parameter-zero divisor
  rejection.
- `2026-05-23`: Shipped actor-local scalar parameter defaults resolving to
  zero as fail-closed runtime division/modulo divisor facts, preserved nonzero
  actor-parameter divisor behavior, synchronized specs/book/live docs, and
  closed the task tree.
