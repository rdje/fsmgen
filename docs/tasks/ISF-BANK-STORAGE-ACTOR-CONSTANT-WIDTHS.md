# ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS: Bank Storage Actor-Constant Widths

## Metadata

- Tree ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor-owned bank storage `(bank NAME (width CONST) (depth D))`
declarations to use actor-local positive constants for bank element widths
when those constants resolve to positive integer literals.

## Non-Goals

- Do not support actor-constant-backed bank depths or transaction-local port
  widths in this tree.
- Do not change the actor-parameter-backed interface, storage, bank, or
  transaction-port behavior already shipped.
- Do not accept runtime interface signals, transaction parameters, arbitrary
  expressions, unknown names, zero-valued actor constants, aggregate values,
  or use-site override values as bank storage widths.
- Do not specialize bank widths through reusable-library use-site parameter
  overrides or generated-top respecialization.
- Do not change bank scalarization, pointer-index semantics, same-cycle bank
  access policy, memory-array backend emission, or `(type NAME)` alias
  behavior.

## Acceptance Criteria

- Actor-owned storage `(bank NAME (width CONST) (depth D))` declarations parse
  and lower when `CONST` names an actor-local constant whose resolved value is
  positive.
- Accepted actor-constant bank widths lower exactly like equivalent positive
  literal widths in public parser handoff, scheduled `.fsm`, schedule reports,
  bank access metadata, and generated HDL.
- Zero-valued, unknown, runtime-signal, expression-valued, and aggregate-like
  width sources remain fail-closed with targeted diagnostics. Existing
  actor-parameter bank widths and depths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS`
  Status: `active`
  Goal: `Ship actor-constant-backed actor-owned bank storage widths.`
  Children: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1`,
  `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2`

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select bank storage actor-constant widths.`
  Acceptance: `Create the active task tree, record the actor-constant source
  boundary, preserve non-goals, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2`
  Status: `pending`
  Goal: `Implement and document actor-constant bank storage widths.`
  Acceptance: `Positive actor constants lower as actor-owned bank storage
  widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2` | `pending` | `The scalar-storage constant tree is closed; implementation can now widen bank element width elaboration under task-tree ownership.` |

## Decisions

- `2026-05-23`: Select actor-owned bank element widths as the next
  actor-constant static-dimension slice. This follows the shipped
  actor-parameter bank-width slice and the shipped actor-constant scalar
  storage-width slice while keeping bank depth scalarization policy and
  generated-top specialization separate.
- `2026-05-23`: Resolve only the owning actor shell's constant value.
  Use-site overrides and generated-top respecialization remain separate policy
  work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1` | `this commit: ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1: select bank storage actor-constant widths` | `selects actor-constant bank storage width support` |
| `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-constant-backed
  actor-owned bank storage widths as the next bounded static-dimension slice.
