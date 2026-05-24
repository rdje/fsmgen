# ISF-LIBRARY-USE-ACTOR-STATIC-VALUES: Actor Static Values In Library Use Overrides

## Metadata

- Tree ID: `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow reusable-library use-site parameter overrides to use the importing
actor's static values in the same bounded source class as generated activation
overrides: declared actor constants, actor-local scalar parameter defaults,
and scalar enum members.

## Non-Goals

- Do not accept transaction parameters as reusable-library use-site parameter
  override values.
- Do not accept runtime interface, storage, transaction, or actor-network
  route signals as use-site parameter override values.
- Do not accept arbitrary override expressions.
- Do not accept non-scalar actor parameters as scalar override values.
  Aggregate/list override values may use actor-local scalar parameters as
  leaves only through the selected implementation leaf.
- Do not change library actor defaults or generated child transaction
  parameter defaults beyond their existing value domains.
- Do not infer use-site parameter-driven interface shape, storage/bank shape,
  route mux/storage, fan-in/fan-out, ready/backpressure, payload protocols, or
  child cloning beyond existing specialized library instances.

## Acceptance Criteria

- The selected contract is documented before implementation.
- Reusable-library use-site `(params ...)` overrides may use actor-local
  constants and actor-local scalar parameter defaults by name.
- Actor static values are resolved to literal values before generated-top
  emission and before `library_uses[]` schedule-report publication.
- Scalar leaves inside compatible aggregate/list use-site override values may
  use actor-local constants, actor-local scalar parameter defaults, and enum
  members.
- Unknown names, transaction parameters, runtime signals, arbitrary
  expressions, and non-scalar actor parameters fail closed with targeted
  diagnostics.
- The mdBook, ISF spec, downstream handoff, public contract, task tree,
  roadmap, and live docs stay synchronized when behavior ships.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES`
  Status: `active`
  Goal: `Track actor static values as reusable-library use-site parameter override values`
  Children: `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.1`,
  `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.2`

- ID: `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.1`
  Status: `done`
  Goal: `Select the reusable-library actor-static override contract`
  Acceptance: `The task tree, live docs, and mdBook backlog state the selected source shape, resolution point, diagnostics, non-goals, and next implementation leaf before code changes.`
  Verification: `passed`
  Commit: `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.1: select library use actor static values`

- ID: `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.2`
  Status: `pending`
  Goal: `Implement actor constants and actor-local scalar parameter defaults as reusable-library use-site override values`
  Acceptance: `Reusable-library use-site overrides accept importing-actor constants and actor-local scalar parameter defaults for scalar values and compatible aggregate/list leaves; malformed or runtime-looking names fail closed; focused tests and synchronized public docs pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.2` | `pending` | Implement the selected bounded contract now that `.1` has recorded the review boundary. |

## Decisions

- `2026-05-24`: The selected widening is importing-actor static values only:
  declared actor constants, actor-local scalar parameter defaults that resolve
  to scalar literals, and already shipped enum members.
- `2026-05-24`: Values must resolve before generated-top `?fsmc` parameter
  emission and `library_uses[]` report publication, so downstream consumers
  continue to see self-contained literal specialization bindings.
- `2026-05-24`: Library use-site overrides remain static specialization, not
  runtime payload movement. Runtime-varying data still belongs on explicit
  ports and bindings.

## Open Questions

- None for the selected first implementation leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.1` | `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.1: select library use actor static values` | `contract-selection slice` |
| `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the actor-static
  reusable-library use-site override contract.
- `2026-05-24`: Completed the selection leaf and advanced the frontier to
  `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.2`.
