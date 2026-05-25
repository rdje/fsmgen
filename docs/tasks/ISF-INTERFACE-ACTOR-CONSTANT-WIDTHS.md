# ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS: Interface Actor-Constant Widths

## Metadata

- Tree ID: `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor top-level interface `(input NAME (width CONST))` and
`(output NAME (width CONST))` declarations to use actor-local positive
constants for port widths when those constants resolve to positive integer
literals.

## Non-Goals

- Do not support actor-constant-backed scalar storage widths, bank widths,
  bank depths, or transaction-local port widths in this tree.
- Do not change the actor-parameter-backed interface, storage, bank, or
  transaction-port behavior already shipped.
- Do not accept runtime interface signals, transaction parameters, arbitrary
  expressions, unknown names, zero-valued actor constants, or aggregate values
  as interface widths.
- Do not specialize interface widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not change `(type NAME)` alias behavior or allow `(width ...)` together
  with `(type ...)`.

## Acceptance Criteria

- Actor interface `(input NAME (width CONST))` and
  `(output NAME (width CONST))` declarations parse and lower when `CONST`
  names an actor-local constant whose resolved value is positive.
- Accepted actor-constant interface widths lower exactly like equivalent
  positive literal widths in public parser handoff, scheduled `.fsm`,
  schedule reports, and generated HDL.
- Zero-valued, unknown, runtime-signal, expression-valued, and aggregate-like
  width sources remain fail-closed with targeted diagnostics. Existing
  actor-parameter interface widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS`
  Status: `done`
  Goal: `Ship actor-constant-backed actor top-level interface widths.`
  Children: `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.1`,
  `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.2`

- ID: `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select interface actor-constant widths.`
  Acceptance: `Create the active task tree, record the actor-constant source
  boundary, preserve non-goals, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ea2e5003 ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.1: select interface actor-constant widths`

- ID: `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document actor-constant interface widths.`
  Acceptance: `Positive actor constants lower as actor top-level interface
  widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `perl -Iperl -c t/1338-isf-interface-actor-constant-widths.t`;
  `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`;
  focused `prove` with `Files=9, Tests=336`; `mdbook build docs/book`;
  broad `./bin/ci-regression isf --no-book` with `Files=244, Tests=1635`;
  post-closure doc/public audits with `Files=6, Tests=348`;
  `git diff --check`
  Commit: `7121b9c3 ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.2: ship interface actor-constant widths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `Actor-constant-backed actor top-level interface widths are shipped and the tree is closed.` |

## Decisions

- `2026-05-23`: Select actor top-level interface widths as the first
  actor-constant static-dimension slice. This mirrors the already shipped
  actor-parameter dimension sequence and keeps storage scalarization,
  transaction-port handoff, and generated-top specialization out of the first
  constant-width implementation.
- `2026-05-23`: Resolve only the owning actor shell's constant value.
  Use-site overrides and generated-top respecialization remain separate policy
  work.
- `2026-05-23`: Actor constants are accepted only for actor top-level
  interface port widths in this tree. Transaction-local ports, scalar
  storage widths, bank widths, bank depths, runtime interface signals, and
  arbitrary expressions still fail closed for actor-constant width sources.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-23` | `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.2` | syntax checks; focused public/interface tests with `Files=9, Tests=336`; `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with `Files=244, Tests=1635`; post-closure doc/public audits with `Files=6, Tests=348`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.1` | `ea2e5003: ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.1: select interface actor-constant widths` | `selects actor-constant interface width support` |
| `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.2` | `7121b9c3 ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.2: ship interface actor-constant widths` | `ships actor-constant interface width support and closes the tree` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-constant-backed actor
  top-level interface widths as the next bounded static-dimension slice.
- `2026-05-23`: Shipped actor-constant-backed actor top-level interface
  widths. Positive declared actor constants, including enum-backed constants,
  now resolve to concrete public port widths, scheduled `.fsm` `+size`
  entries, and HDL port ranges. Unsupported symbolic/runtime/expression/zero
  width sources still fail closed. Synchronized the ISF spec, downstream
  integration handoff, public contract, mdBook, roadmap status, and live docs.
