# ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS: Transaction Port Actor-Constant Widths

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow transaction-local `(ports ...)` declarations to use actor-local positive
constants for port widths when those constants resolve to positive integer
literals.

## Non-Goals

- Do not support transaction-parameter-backed transaction port widths in this
  tree.
- Do not change the already shipped actor-parameter-backed transaction port
  width behavior.
- Do not change the already shipped actor-interface, actor-owned scalar
  storage, actor-owned bank width, or actor-owned bank depth static-dimension
  behavior.
- Do not specialize transaction port widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not accept runtime interface signals, unknown names, arbitrary
  expressions, zero-valued actor constants, aggregate values, or use-site
  override values as transaction-local port widths.
- Do not change activation binding semantics, binding timing, binding
  expression width inference, output binding shapes, generated-top handoff
  naming, or schedule-report `transaction_port_bindings[]` key families.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Transaction-local `(input NAME (width CONST))` and
  `(output NAME (width CONST))` declarations parse and lower when `CONST`
  names an actor-local constant whose resolved value is positive.
- Accepted actor-constant transaction port widths lower exactly like
  equivalent positive literal widths in public parser handoff, scheduled
  `.fsm`, activation handoff storage, schedule reports, and generated HDL.
- Zero-valued, unknown, runtime-signal, expression-valued, aggregate-like, and
  transaction-parameter-like width sources remain fail-closed with targeted
  diagnostics. Existing positive literal and actor-parameter transaction port
  widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS`
  Status: `active`
  Goal: `Ship actor-constant-backed transaction-local port widths.`
  Children: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1`,
  `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2`

- ID: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select transaction port actor-constant widths.`
  Acceptance: `Create the active task tree, record the actor-constant source
  boundary, preserve non-goals, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2`
  Status: `pending`
  Goal: `Implement and document actor-constant transaction port widths.`
  Acceptance: `Positive actor constants lower as transaction-local port
  widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2` | `pending` | `Actor-owned interface/storage/bank constant dimensions are shipped; transaction-local port widths are the remaining static actor-constant width frontier named by the roadmap.` |

## Decisions

- `2026-05-23`: Select transaction-local port widths as the next
  actor-constant static-dimension surface. Actor top-level interface widths,
  actor-owned scalar storage widths, actor-owned bank widths, and actor-owned
  bank depths already accept declared actor constants when they resolve to
  positive integers.
- `2026-05-23`: Resolve only the owning actor shell's constant value.
  Transaction parameters, use-site overrides, and generated-top
  respecialization remain separate policy work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1` | `this commit: ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1: select transaction port actor-constant widths` | `selects actor-constant transaction port width support` |
| `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-constant-backed
  transaction-local port widths as the next bounded static-dimension slice.
