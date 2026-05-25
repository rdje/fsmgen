# ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS: Scalar Storage Package-Constant Widths

## Metadata

- Tree ID: `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow actor-owned scalar storage `(var NAME (width PACKAGE.CONSTANT))` and
verbose `(variable NAME (width PACKAGE.CONSTANT))` declarations to use
qualified imported package scalar constants for storage widths when those
constants resolve to positive integer literals.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as scalar storage widths in this tree.
- Do not support package-constant-backed actor interface widths, bank widths,
  bank depths, transaction-local port widths, watchdog limits, latency bounds,
  contract windows, repeat counts, waits, or other value domains in this tree.
  Actor interface widths are already handled by their own closed task tree.
- Do not change actor-constant-backed or actor-parameter-backed scalar storage
  width behavior already shipped.
- Do not change `(type NAME)` alias behavior or allow `(width ...)` together
  with `(type ...)`.

## Acceptance Criteria

- Actor-owned scalar storage declarations parse and lower when their `(width
  PACKAGE.CONSTANT)` token names a scalar package constant imported by the
  owning actor and the resolved constant value is a positive integer.
- Accepted package-constant scalar storage widths lower exactly like
  equivalent positive literal widths in public parser handoff, scheduled
  `.fsm`, schedule reports, width evidence, and generated HDL.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  and package constants outside this scalar-storage-width surface remain
  fail-closed with targeted diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS`
  Status: `done`
  Goal: `Ship qualified imported package scalar constants as actor-owned scalar storage widths.`
  Children: `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.1`,
    `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2`

- ID: `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select scalar storage package-constant widths.`
  Acceptance: `Create the active task tree, record the qualified package
  scalar-constant source boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `feature-backlog/live-book/book-matrix audits with Files=3,
  Tests=364; mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.1: select scalar storage package-constant widths`

- ID: `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document qualified package scalar constants as actor-owned scalar storage widths.`
  Acceptance: `Positive imported package scalar constants lower as
  actor-owned scalar storage widths; unsupported width sources fail closed;
  specs, book, public contract, downstream handoff, focused tests, and broader
  ISF gate are synchronized.`
  Verification: `syntax checks; focused public/scalar-storage/package tests
  with Files=10, Tests=350; ./bin/ci-regression isf --no-book with Files=260,
  Tests=1705; post-closure public/spec/book/backlog audits with Files=7,
  Tests=374; mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2: ship scalar storage package-constant widths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The qualified package-constant actor-owned scalar storage width boundary is implemented and documented. |

## Decisions

- `2026-05-24`: Select actor-owned scalar storage widths as the next bounded
  imported package scalar-constant dimension widening after actor interface
  widths. This mirrors the already shipped actor-constant and actor-parameter
  scalar storage width slices while keeping bank dimensions and
  transaction-local port widths out of this implementation.
- `2026-05-24`: Resolve only explicitly qualified constants from packages
  imported by the owning actor. Unqualified lookup and package namespace
  pollution remain fail-closed.
- `2026-05-24`: Publish the resolved positive integer width in the parser
  handoff, scheduled `.fsm`, schedule report/evidence, and generated HDL,
  matching actor-constant and actor-parameter scalar storage width behavior.

## Open Questions

- None. Wider package-constant dimension surfaces are deferred by this task
  tree rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=364` |
| `2026-05-24` | `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -c t/1354-isf-scalar-storage-package-constant-widths.t`; `perl -c t/1144-isf-public-tested-by-metadata-audit.t`; focused public/scalar-storage/package tests; `./bin/ci-regression isf --no-book`; post-closure public/spec/book/backlog audits; `mdbook build docs/book`; `git diff --check` | `passed: focused Files=10, Tests=350; full ISF Files=260, Tests=1705; post-closure Files=7, Tests=374` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.1` | `this commit: ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.1: select scalar storage package-constant widths` | `selection slice` |
| `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2` | `this commit: ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2: ship scalar storage package-constant widths` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected qualified imported package
  scalar constants in actor-owned scalar storage widths as the next bounded
  static-dimension implementation frontier.
- `2026-05-24`: Implemented and documented qualified imported package scalar
  constants in actor-owned scalar storage widths, then closed the tree.
