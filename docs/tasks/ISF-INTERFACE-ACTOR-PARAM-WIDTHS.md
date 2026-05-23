# ISF-INTERFACE-ACTOR-PARAM-WIDTHS: Interface Actor-Parameter Widths

## Metadata

- Tree ID: `ISF-INTERFACE-ACTOR-PARAM-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor top-level interface port `(width PARAM)` declarations to use
actor-local scalar parameter defaults when those defaults resolve to positive
integer literals.

## Non-Goals

- Do not support actor-parameter-backed actor-owned storage widths or bank
  depths in this tree.
- Do not support actor-parameter-backed transaction-local port widths in this
  tree.
- Do not specialize interface widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not accept transaction parameters, runtime signals, arbitrary
  expressions, unknown names, zero-valued actor parameters, or non-scalar actor
  parameters as interface widths.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Actor interface `(input NAME (width PARAM))` and
  `(output NAME (width PARAM))` parse and lower when `PARAM` names an
  actor-local scalar parameter default whose resolved value is positive.
- Accepted parameter-backed interface widths lower exactly like equivalent
  positive literal widths in scheduled `.fsm`, schedule reports, and generated
  HDL.
- Zero-valued, non-scalar, unknown, transaction-parameter, runtime-signal, and
  expression-valued width sources remain fail-closed with targeted diagnostics.
- Existing positive literal widths, omitted one-bit widths, and `(type NAME)`
  interface widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-INTERFACE-ACTOR-PARAM-WIDTHS`
  Status: `active`
  Goal: `Ship actor-parameter-backed actor interface port widths.`
  Children: `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.1`,
  `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.2`

- ID: `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.1`
  Status: `done`
  Goal: `Select interface actor-parameter widths.`
  Acceptance: `Create the active task tree, record the static actor-parameter
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.2`
  Status: `pending`
  Goal: `Implement and document actor-parameter interface widths.`
  Acceptance: `Positive actor scalar parameters lower as actor interface port
  widths; unsupported width sources fail closed; specs, book, public contract,
  downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.2` | `pending` | The source boundary is selected; implementation can extend actor interface width parsing/resolution with actor-parameter-backed positive widths only. |

## Decisions

- `2026-05-23`: Select only actor top-level interface port widths for the
  first parameter-driven interface/storage elaboration slice. This is the
  smallest author-facing surface that improves interface reuse without
  touching bank scalarization, transaction-port binding semantics, or storage
  schedule-report roles.
- `2026-05-23`: Resolve only the actor shell's own scalar parameter default.
  Use-site override specialization and generated-top respecialization remain
  separate policy work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.1` | `this commit: ISF-INTERFACE-ACTOR-PARAM-WIDTHS.1: select interface actor-param widths` | `selects static actor-parameter interface port width support` |
| `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-parameter-backed actor
  interface port widths as the next bounded parameter-driven interface slice.
