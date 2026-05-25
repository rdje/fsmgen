# ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS: Bank Storage Package-Constant Widths

## Metadata

- Tree ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow actor-owned bank storage `(bank NAME (width PACKAGE.CONSTANT) (depth
N|PARAM|CONST))` declarations to use qualified imported package scalar
constants for bank element widths when those constants resolve to positive
integer literals.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as bank storage widths in this tree.
- Do not support package-constant-backed actor interface widths or
  actor-owned scalar storage widths in this tree; those are already handled by
  their own closed task trees.
- Do not support package-constant-backed bank depths, transaction-local port
  widths, watchdog limits, latency bounds, contract windows, repeat counts,
  waits, or other value domains in this tree.
- Do not change actor-constant-backed or actor-parameter-backed bank storage
  width behavior already shipped.
- Do not change memory-array backend emission; banks still lower through the
  current deterministic scalarized storage element surface.

## Acceptance Criteria

- Actor-owned bank storage declarations parse and lower when their `(width
  PACKAGE.CONSTANT)` token names a scalar package constant imported by the
  owning actor and the resolved constant value is a positive integer.
- Accepted package-constant bank widths lower exactly like equivalent positive
  literal widths in public parser handoff, scheduled `.fsm`, schedule reports,
  width evidence, bank access metadata, and generated HDL.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  and package constants outside this bank-width surface remain fail-closed
  with targeted diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS`
  Status: `done`
  Goal: `Ship qualified imported package scalar constants as actor-owned bank storage widths.`
  Children: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.1`,
    `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2`

- ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select bank storage package-constant widths.`
  Acceptance: `Create the active task tree, record the qualified package
  scalar-constant bank-width boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `feature-backlog/live-book/book-matrix audits with Files=3,
  Tests=364; mdbook build docs/book; git diff --check`
  Commit: `474892c5 ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.1: select bank storage package-constant widths`

- ID: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document qualified package scalar constants as actor-owned bank storage widths.`
  Acceptance: `Positive imported package scalar constants lower as
  actor-owned bank storage widths; unsupported width sources fail closed;
  specs, book, public contract, downstream handoff, focused tests, and broader
  ISF gate are synchronized.`
  Verification: `syntax checks; focused public/storage/package tests with
  Files=11, Tests=352; ./bin/ci-regression isf --no-book with Files=261,
  Tests=1707; post-closure public/spec/book/backlog audits with Files=7,
  Tests=374; mdbook build docs/book; git diff --check`
  Commit: `74526f72 ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2: ship bank storage package-constant widths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The qualified package-constant actor-owned bank storage width boundary is implemented and documented. |

## Decisions

- `2026-05-24`: Select actor-owned bank storage widths as the next bounded
  imported package scalar-constant dimension widening after actor interface
  and scalar storage widths. This mirrors the already shipped actor-constant
  and actor-parameter bank width slices while keeping bank depths and
  transaction-local port widths out of this implementation.
- `2026-05-24`: Resolve only explicitly qualified constants from packages
  imported by the owning actor. Unqualified lookup and package namespace
  pollution remain fail-closed.
- `2026-05-24`: Publish the resolved positive integer width in the parser
  handoff, scheduled `.fsm`, schedule report/evidence, bank access metadata,
  and generated HDL, matching actor-constant and actor-parameter bank storage
  width behavior.

## Open Questions

- None. Wider package-constant dimension surfaces are deferred by this task
  tree rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=364` |
| `2026-05-24` | `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -c t/1355-isf-bank-storage-package-constant-widths.t`; `perl -c t/1144-isf-public-tested-by-metadata-audit.t`; focused public/storage/package tests; `./bin/ci-regression isf --no-book`; post-closure public/spec/book/backlog audits; `mdbook build docs/book`; `git diff --check` | `passed: focused Files=11, Tests=352; full ISF Files=261, Tests=1707; post-closure Files=7, Tests=374` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.1` | `474892c5 ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.1: select bank storage package-constant widths` | `selection slice` |
| `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2` | `74526f72 ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2: ship bank storage package-constant widths` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected qualified imported package
  scalar constants in actor-owned bank storage widths as the next bounded
  static-dimension implementation frontier.
- `2026-05-24`: Implemented and documented qualified imported package scalar
  constants in actor-owned bank storage widths, then closed the tree.
