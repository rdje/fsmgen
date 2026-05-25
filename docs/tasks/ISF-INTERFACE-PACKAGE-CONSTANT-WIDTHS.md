# ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS: Interface Package-Constant Widths

## Metadata

- Tree ID: `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow actor top-level interface `(input NAME (width PACKAGE.CONSTANT))` and
`(output NAME (width PACKAGE.CONSTANT))` declarations to use qualified
imported package scalar constants for port widths when those constants resolve
to positive integer literals.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as interface widths in this tree.
- Do not support package-constant-backed scalar storage widths, bank widths,
  bank depths, transaction-local port widths, watchdog limits, latency bounds,
  contract windows, repeat counts, waits, or other value domains in this tree.
- Do not change actor-constant-backed or actor-parameter-backed interface
  width behavior already shipped.
- Do not specialize interface widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not change `(type NAME)` alias behavior or allow `(width ...)` together
  with `(type ...)`.

## Acceptance Criteria

- Actor interface `(input NAME (width PACKAGE.CONSTANT))` and
  `(output NAME (width PACKAGE.CONSTANT))` declarations parse and lower when
  the owning actor imports `PACKAGE`, the package declares `CONSTANT`, and the
  constant resolves to a positive integer scalar literal.
- Accepted package-constant interface widths lower exactly like equivalent
  positive literal widths in public parser handoff, scheduled `.fsm`,
  schedule reports, and generated HDL.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  and package constants outside this interface-width surface remain
  fail-closed with targeted diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS`
  Status: `done`
  Goal: `Ship qualified imported package scalar constants as actor top-level interface widths.`
  Children: `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.1`,
    `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2`

- ID: `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select interface package-constant widths.`
  Acceptance: `Create the active task tree, record the qualified package
  scalar-constant source boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `passed`
  Commit: `cb381c19 ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.1: select interface package-constant widths`

- ID: `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document qualified package scalar constants as actor interface port widths.`
  Acceptance: `Positive imported package scalar constants lower as actor
  top-level interface widths; unsupported width sources fail closed; specs,
  book, public contract, downstream handoff, focused tests, and broader ISF
  gate are synchronized.`
  Verification: `passed`
  Commit: `dd27c60a ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2: ship interface package-constant widths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The qualified package-constant actor interface width implementation shipped and the tree is closed. |

## Decisions

- `2026-05-24`: Select actor top-level interface widths as the next bounded
  imported package scalar-constant value-domain widening. This mirrors the
  already shipped actor-constant and actor-parameter interface width slices
  while keeping storage, bank, transaction-port, wait, watchdog, latency,
  contract, repeat, and generated-top specialization behavior out of the
  first dimension-oriented package-constant implementation.
- `2026-05-24`: Resolve only explicitly qualified constants from packages
  imported by the owning actor. Unqualified lookup and package namespace
  pollution remain fail-closed.
- `2026-05-24`: Publish the resolved positive integer width in the scheduled
  `.fsm`, schedule report, and generated HDL, matching actor-constant and
  actor-parameter interface width behavior rather than preserving a package
  token in the width field.

## Open Questions

- None. Wider package-constant dimension surfaces are deferred by this task
  tree rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-24` | `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2` | syntax checks; focused public/interface/package tests with `Files=10, Tests=350`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` with `Files=259, Tests=1703`; post-closure public/spec/book/backlog audits with `Files=7, Tests=374`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.1` | `cb381c19 ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.1: select interface package-constant widths` | `selection slice` |
| `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2` | `dd27c60a ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2: ship interface package-constant widths` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected qualified imported package
  scalar constants in actor top-level interface port widths as the next
  bounded static-dimension implementation frontier.
- `2026-05-24`: Shipped qualified imported package scalar constants in actor
  top-level interface port widths, resolved those widths to positive integer
  parser handoff, scheduled `.fsm`, report, and HDL surfaces, and closed the
  task tree.
