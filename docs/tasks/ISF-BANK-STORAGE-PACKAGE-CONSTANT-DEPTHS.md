# ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS: Bank Storage Package-Constant Depths

## Metadata

- Tree ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow actor-owned bank storage `(bank NAME (width N|PARAM|CONST) (depth
PACKAGE.CONSTANT))` declarations to use qualified imported package scalar
constants for bank depths when those constants resolve to positive integer
literals.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as bank depths in this tree.
- Do not support package-constant-backed actor interface widths, actor-owned
  scalar storage widths, or actor-owned bank storage widths in this tree;
  those are already handled by their own closed task trees.
- Do not support package-constant-backed transaction-local port widths,
  watchdog limits, latency bounds, contract windows, repeat counts, waits, or
  other value domains in this tree.
- Do not change actor-constant-backed or actor-parameter-backed bank depth
  behavior already shipped.
- Do not change memory-array backend emission; banks still lower through the
  current deterministic scalarized storage element surface.

## Acceptance Criteria

- Actor-owned bank storage declarations parse and lower when their `(depth
  PACKAGE.CONSTANT)` token names a scalar package constant imported by the
  owning actor and the resolved constant value is a positive integer.
- Accepted package-constant bank depths lower exactly like equivalent positive
  literal depths in public parser handoff, scheduled `.fsm`, schedule reports,
  scalarized storage families, bank access metadata, and generated HDL.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  and package constants outside this bank-depth surface remain fail-closed
  with targeted diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS`
  Status: `active`
  Goal: `Ship qualified imported package scalar constants as actor-owned bank storage depths.`
  Children: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1`,
    `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2`

- ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1`
  Status: `done`
  Goal: `Select bank storage package-constant depths.`
  Acceptance: `Create the active task tree, record the qualified package
  scalar-constant bank-depth boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `feature-backlog/live-book/book-matrix audits with Files=3,
  Tests=364; mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1: select bank storage package-constant depths`

- ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2`
  Status: `pending`
  Goal: `Implement and document qualified package scalar constants as actor-owned bank storage depths.`
  Acceptance: `Positive imported package scalar constants lower as
  actor-owned bank storage depths; unsupported depth sources fail closed;
  specs, book, public contract, downstream handoff, focused tests, and broader
  ISF gate are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2` | `pending` | The qualified package-constant actor-owned bank storage depth boundary is selected and ready for implementation. |

## Decisions

- `2026-05-24`: Select actor-owned bank storage depths as the next bounded
  imported package scalar-constant dimension widening after actor interface,
  scalar storage, and bank width package constants.
- `2026-05-24`: Resolve only explicitly qualified constants from packages
  imported by the owning actor. Unqualified lookup and package namespace
  pollution remain fail-closed.
- `2026-05-24`: Publish the resolved positive integer depth in the parser
  handoff, scheduled `.fsm`, schedule report/evidence, scalarized storage
  family, bank access metadata, and generated HDL, matching actor-constant and
  actor-parameter bank storage depth behavior.

## Open Questions

- None. Wider package-constant dimension surfaces are deferred by this task
  tree rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1` | `feature-backlog/live-book/book-matrix audits; mdbook build docs/book; git diff --check` | `passed: Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1` | `this commit: ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1: select bank storage package-constant depths` | `selection slice` |
| `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected qualified imported package
  scalar constants in actor-owned bank storage depths as the next bounded
  static-dimension implementation frontier.
