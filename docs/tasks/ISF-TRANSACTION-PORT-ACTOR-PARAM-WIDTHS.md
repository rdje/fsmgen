# ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS: Transaction Port Actor-Parameter Widths

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow transaction-local `(ports ...)` declarations to use actor-local scalar
parameter defaults for port widths when those defaults resolve to positive
integer literals.

## Non-Goals

- Do not support transaction-parameter-backed transaction port widths in this
  tree.
- Do not support actor-parameter-backed bank depths in this tree.
- Do not specialize transaction port widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not accept actor constants, runtime interface signals, unknown names,
  arbitrary expressions, zero-valued actor parameters, or non-scalar actor
  parameters as transaction port widths.
- Do not change activation binding semantics, binding timing, binding
  expression width inference, output binding shapes, generated-top handoff
  naming, or schedule-report `transaction_port_bindings[]` key families.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Transaction-local `(input NAME (width PARAM))` and
  `(output NAME (width PARAM))` declarations parse and lower when `PARAM`
  names an actor-local scalar parameter default whose resolved value is
  positive.
- Accepted parameter-backed transaction port widths lower exactly like
  equivalent positive literal widths in public parser handoff, scheduled
  `.fsm`, activation handoff storage, schedule reports, and generated HDL.
- Zero-valued, non-scalar, unknown, actor-constant, transaction-parameter,
  runtime-signal, and expression-valued width sources remain fail-closed with
  targeted diagnostics.
- Existing positive literal transaction port widths, omitted one-bit widths,
  `(type NAME)` widths, activation binding checks, and transaction port report
  behavior keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS`
  Status: `active`
  Goal: `Ship actor-parameter-backed transaction-local port widths.`
  Children: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1`,
  `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2`

- ID: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1`
  Status: `done`
  Goal: `Select transaction port actor-parameter widths.`
  Acceptance: `Create the active task tree, record the static
  actor-parameter source boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2`
  Status: `pending`
  Goal: `Implement and document actor-parameter transaction port widths.`
  Acceptance: `Positive actor scalar parameters lower as transaction-local
  port widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2` | `pending` | Selection is complete; implementation can reuse the actor-parameter width policy already shipped for actor interface and actor-owned storage widths. |

## Decisions

- `2026-05-23`: Select transaction-local port widths as the next bounded
  actor-parameter elaboration surface. Actor interface widths, scalar storage
  widths, and bank element widths already accept actor-local scalar parameter
  defaults; transaction ports are the remaining width-bearing surface named in
  the current ISF limitations.
- `2026-05-23`: Resolve only the owning actor shell's scalar parameter
  default. Transaction parameters remain deferred because transaction port
  width specialization would need activation-site/generated-top policy beyond
  this static actor-parameter slice.
- `2026-05-23`: Keep actor constants and runtime interface signals out of the
  symbolic width path. This tree is actor-parameter elaboration, not a general
  symbolic dimension system.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1` | `this commit: ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1: select transaction port actor-param widths` | `selects static actor-parameter transaction-local port width support` |
| `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-parameter-backed
  transaction-local port widths as the next bounded parameter-driven
  transaction boundary slice.
