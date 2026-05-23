# ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS: Scalar Storage Actor-Parameter Widths

## Metadata

- Tree ID: `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor-owned scalar storage `(var NAME (width PARAM))` and
`(variable NAME (width PARAM))` declarations to use actor-local scalar
parameter defaults when those defaults resolve to positive integer literals.

## Non-Goals

- Do not support actor-parameter-backed actor-owned bank widths or bank depths
  in this tree.
- Do not support actor-parameter-backed transaction-local port widths in this
  tree.
- Do not change the actor top-level interface width behavior already shipped by
  `ISF-INTERFACE-ACTOR-PARAM-WIDTHS`.
- Do not specialize storage widths through reusable-library use-site parameter
  overrides or generated-top respecialization.
- Do not accept actor constants, transaction parameters, runtime signals,
  arbitrary expressions, unknown names, zero-valued actor parameters, or
  non-scalar actor parameters as scalar storage widths.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Actor-owned scalar storage `(var NAME (width PARAM))` and
  `(variable NAME (width PARAM))` parse and lower when `PARAM` names an
  actor-local scalar parameter default whose resolved value is positive.
- Accepted parameter-backed scalar storage widths lower exactly like equivalent
  positive literal widths in scheduled `.fsm`, schedule reports, and generated
  HDL.
- Zero-valued, non-scalar, unknown, actor-constant, transaction-parameter,
  runtime-signal, and expression-valued width sources remain fail-closed with
  targeted diagnostics.
- Existing positive literal widths, omitted type-alias storage declarations,
  bank declarations, bank access lowering, and actor top-level interface
  widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS`
  Status: `active`
  Goal: `Ship actor-parameter-backed actor-owned scalar storage widths.`
  Children: `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.1`,
  `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.2`

- ID: `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.1`
  Status: `done`
  Goal: `Select scalar storage actor-parameter widths.`
  Acceptance: `Create the active task tree, record the static actor-parameter
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.2`
  Status: `pending`
  Goal: `Implement and document actor-parameter scalar storage widths.`
  Acceptance: `Positive actor scalar parameters lower as actor-owned scalar
  storage widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.2` | `pending` | The source boundary is selected; implementation can extend scalar actor-owned storage width parsing/resolution with actor-parameter-backed positive widths only. |

## Decisions

- `2026-05-23`: Select only actor-owned scalar storage widths as the next
  parameter-driven storage slice. This is the smallest internal-state surface
  that improves reusable actor authoring without touching bank scalarization
  counts, bank access metadata, transaction-port binding semantics, or
  generated-top specialization.
- `2026-05-23`: Resolve only the owning actor shell's scalar parameter
  default. Use-site override specialization and generated-top
  respecialization remain separate policy work.
- `2026-05-23`: Keep actor constants and runtime interface signals out of the
  scalar storage width symbolic path. This tree is specifically
  actor-parameter elaboration, not a general symbolic dimension system.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.1` | `this commit: ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.1: select scalar storage actor-param widths` | `selects static actor-parameter scalar storage width support` |
| `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-parameter-backed
  actor-owned scalar storage widths as the next bounded parameter-driven
  storage slice.
