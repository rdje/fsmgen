# ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS: Bank Storage Package-Constant Depths

## Metadata

- Tree ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS`
- Status: `done`
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
  Status: `done`
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
  Commit: `717b47ab ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1: select bank storage package-constant depths`

- ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2`
  Status: `done`
  Goal: `Implement and document qualified package scalar constants as actor-owned bank storage depths.`
  Acceptance: `Positive imported package scalar constants lower as
  actor-owned bank storage depths; unsupported depth sources fail closed;
  specs, book, public contract, downstream handoff, focused tests, and broader
  ISF gate are synchronized.`
  Verification: `syntax checks; focused public/storage/package tests with
  Files=11, Tests=35; ./bin/ci-regression isf --no-book with Files=262,
  Tests=1709; post-closure public/spec/book/backlog audits with Files=8,
  Tests=375; mdbook build docs/book; git diff --check`
  Commit: `aa044756 ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2: ship bank storage package-constant depths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The qualified package-constant actor-owned bank storage depth boundary is implemented and documented. |

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
- `2026-05-24`: Implement the selected boundary by resolving the qualified
  package scalar constant before bank signal-family scalarization. Storage
  width finalization still runs afterward so package-constant widths and
  package-constant depths can compose in one bank declaration.

## Open Questions

- None. Wider package-constant dimension surfaces are deferred by this task
  tree rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1` | `feature-backlog/live-book/book-matrix audits; mdbook build docs/book; git diff --check` | `passed: Files=3, Tests=364` |
| `2026-05-24` | `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -c t/1356-isf-bank-storage-package-constant-depths.t`; `perl -c t/1144-isf-public-tested-by-metadata-audit.t`; focused public/storage/package tests; `./bin/ci-regression isf --no-book`; post-closure public/spec/book/backlog audits; `mdbook build docs/book`; `git diff --check` | `passed: focused Files=11, Tests=35; full ISF Files=262, Tests=1709; post-closure Files=8, Tests=375` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1` | `717b47ab ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1: select bank storage package-constant depths` | `selection slice` |
| `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2` | `aa044756 ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2: ship bank storage package-constant depths` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected qualified imported package
  scalar constants in actor-owned bank storage depths as the next bounded
  static-dimension implementation frontier.
- `2026-05-24`: Implemented and documented qualified imported package scalar
  constants in actor-owned bank storage depths, then closed the tree.
