# ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS: Transaction Port Package-Constant Widths

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow transaction-local `(ports ...)` declarations to use qualified imported
package scalar constants for port widths when those constants resolve to
positive integer literals.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as transaction-local port widths in this tree.
- Do not support transaction-parameter-backed transaction port widths in this
  tree.
- Do not specialize transaction port widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not accept runtime interface signals, unknown names, arbitrary
  expressions, zero-valued package constants, aggregate values, or use-site
  override values as transaction-local port widths.
- Do not change activation binding semantics, binding timing, binding
  expression width inference, output binding shapes, generated-top handoff
  naming, or schedule-report `transaction_port_bindings[]` key families.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Transaction-local `(input NAME (width PACKAGE.CONSTANT))` and
  `(output NAME (width PACKAGE.CONSTANT))` declarations parse and lower when
  the owning actor imports `PACKAGE`, the package declares `CONSTANT`, and the
  constant resolves to a positive integer scalar literal.
- Accepted package-constant transaction port widths lower exactly like
  equivalent positive literal widths in public parser handoff, scheduled
  `.fsm`, activation handoff storage, schedule reports, and generated HDL.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  and package constants outside this transaction-port-width surface remain
  fail-closed with targeted diagnostics.
- Existing positive literal, actor-constant, actor-parameter, omitted one-bit,
  and `(type NAME)` transaction port widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS`
  Status: `active`
  Goal: `Ship qualified imported package scalar constants as transaction-local port widths.`
  Children: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1`,
    `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2`

- ID: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select transaction port package-constant widths.`
  Acceptance: `Create the active task tree, record the qualified package
  scalar-constant transaction-port width boundary, preserve non-goals, and
  update roadmap/live docs without behavior changes.`
  Verification: `feature-backlog/live-book/book-matrix audits with Files=3,
  Tests=364; mdbook build docs/book; git diff --check`
  Commit: `pending this commit`

- ID: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2`
  Status: `pending`
  Goal: `Implement and document qualified package scalar constants as transaction-local port widths.`
  Acceptance: `Positive imported package scalar constants lower as
  transaction-local port widths; unsupported width sources fail closed; specs,
  book, public contract, downstream handoff, focused tests, and broader ISF
  gate are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` | `pending` | Transaction-local port widths are the next explicit package-constant dimension deferral after actor interface, scalar storage, bank width, and bank depth package constants. |

## Decisions

- `2026-05-25`: Select transaction-local port widths as the next bounded
  imported package scalar-constant dimension widening. Actor top-level
  interface widths, actor-owned scalar storage widths, actor-owned bank
  widths, and actor-owned bank depths already accept qualified package scalar
  constants when they resolve to positive integers.
- `2026-05-25`: Resolve only explicitly qualified constants from packages
  imported by the owning actor. Unqualified lookup and package namespace
  pollution remain fail-closed.
- `2026-05-25`: Publish the resolved positive integer width in parser
  handoff, scheduled `.fsm`, activation handoff storage, schedule reports, and
  generated HDL, matching actor-constant and actor-parameter transaction port
  width behavior rather than preserving package tokens in generated width
  fields.

## Open Questions

- None. Wider package-constant dimension/value surfaces are deferred by this
  task tree rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1` | `feature-backlog/live-book/book-matrix audits; mdbook build docs/book; git diff --check` | `passed: Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1` | `pending this commit` | `selection slice` |
| `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-25`: Created task tree and selected qualified imported package
  scalar constants in transaction-local port widths as the next bounded
  static-dimension implementation frontier.
