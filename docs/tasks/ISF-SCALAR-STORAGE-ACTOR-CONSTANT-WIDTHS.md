# ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS: Scalar Storage Actor-Constant Widths

## Metadata

- Tree ID: `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor-owned scalar storage `(var NAME (width CONST))` and
`(variable NAME (width CONST))` declarations to use actor-local positive
constants for storage widths when those constants resolve to positive integer
literals.

## Non-Goals

- Do not support actor-constant-backed bank widths, bank depths, or
  transaction-local port widths in this tree.
- Do not change the actor-parameter-backed interface, storage, bank, or
  transaction-port behavior already shipped.
- Do not accept runtime interface signals, transaction parameters, arbitrary
  expressions, unknown names, zero-valued actor constants, aggregate values,
  or use-site override values as scalar storage widths.
- Do not specialize scalar storage widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not change `(type NAME)` alias behavior or allow `(width ...)` together
  with `(type ...)`.

## Acceptance Criteria

- Actor-owned storage `(var NAME (width CONST))` and
  `(variable NAME (width CONST))` declarations parse and lower when `CONST`
  names an actor-local constant whose resolved value is positive.
- Accepted actor-constant scalar storage widths lower exactly like equivalent
  positive literal widths in public parser handoff, scheduled `.fsm`,
  schedule reports, and generated HDL.
- Zero-valued, unknown, runtime-signal, expression-valued, and aggregate-like
  width sources remain fail-closed with targeted diagnostics. Existing
  actor-parameter scalar storage widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS`
  Status: `done`
  Goal: `Ship actor-constant-backed actor-owned scalar storage widths.`
  Children: `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.1`,
  `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.2`

- ID: `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select scalar storage actor-constant widths.`
  Acceptance: `Create the active task tree, record the actor-constant source
  boundary, preserve non-goals, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document actor-constant scalar storage widths.`
  Acceptance: `Positive actor constants lower as actor-owned scalar storage
  widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `perl -Iperl -c t/1339-isf-scalar-storage-actor-constant-widths.t`;
  `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`;
  focused `prove` with `Files=10, Tests=339`; `mdbook build docs/book`;
  broad `./bin/ci-regression isf --no-book` with `Files=245, Tests=1638`;
  post-closure doc/public audits with `Files=6, Tests=348`;
  `git diff --check`
  Commit: `this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `Actor-constant-backed actor-owned scalar storage widths are shipped and the tree is closed.` |

## Decisions

- `2026-05-23`: Select actor-owned scalar storage widths as the next
  actor-constant static-dimension slice. This follows the shipped
  actor-parameter storage width slice and the shipped actor-constant
  interface width slice while keeping bank scalarization, transaction-port
  handoff, and generated-top specialization out of the first storage-constant
  implementation.
- `2026-05-23`: Resolve only the owning actor shell's constant value.
  Use-site overrides and generated-top respecialization remain separate policy
  work.
- `2026-05-23`: Actor constants are accepted only for actor-owned scalar
  storage widths in this tree. Bank widths, bank depths, transaction-local
  ports, runtime interface signals, arbitrary expressions, use-site
  overrides, and generated-top respecialization remain out of scope.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-23` | `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.2` | syntax checks; focused storage/public tests with `Files=10, Tests=339`; `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with `Files=245, Tests=1638`; post-closure doc/public audits with `Files=6, Tests=348`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.1` | `44d87399: ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.1: select scalar storage actor-constant widths` | `selects actor-constant scalar storage width support` |
| `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.2` | `this commit: ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.2: ship scalar storage actor-constant widths` | `ships actor-constant scalar storage width support and closes the tree` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-constant-backed
  actor-owned scalar storage widths as the next bounded static-dimension
  slice.
- `2026-05-23`: Shipped actor-constant-backed actor-owned scalar storage
  widths. Positive declared actor constants, including enum-backed constants,
  now resolve to concrete actor-owned scalar storage widths, scheduled `.fsm`
  `+size` entries, schedule-report storage widths, and HDL register ranges.
  Unsupported symbolic/runtime/expression/zero width sources and
  actor-constant bank widths still fail closed. Synchronized the ISF spec,
  downstream integration handoff, public contract, mdBook, roadmap status,
  and live docs.
