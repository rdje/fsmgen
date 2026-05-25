# ISF-LIBRARY-USE-PACKAGE-CONSTANTS: Package Constants In Reusable-Library Use-Site Overrides

## Metadata

- Tree ID: `ISF-LIBRARY-USE-PACKAGE-CONSTANTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow reusable-library use-site parameter override scalar values and scalar
leaves inside compatible aggregate/list override values to reference imported
package scalar constants by qualified name, for example
`shared.DEFAULT_WIDTH`.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as reusable-library use-site parameter override values in this tree.
- Do not widen waits, watchdogs, latency bounds, contract windows, repeat
  counts, storage or interface dimensions, activation overrides, generated
  child transaction defaults, or other value domains to package constants in
  this tree.
- Do not introduce generated-top package imports for use-site overrides;
  reusable-library use-site publication already specializes override values.
- Do not introduce arbitrary expressions, dependency graph solving, package
  aliasing, or package namespace pollution.

## Acceptance Criteria

- Reusable-library `(use ALIAS.actor as INSTANCE (params ...))` override
  scalar values may use `PACKAGE.CONSTANT` when the importing actor imports
  that package and the package constant resolves to a scalar numeric or
  exact-width literal.
- Scalar leaves inside compatible aggregate/list reusable-library use-site
  override values may use the same qualified package scalar constants.
- Publication stays self-contained by resolving package constants to literal
  generated-top/generated-composition bindings and `library_uses[]` report
  values.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous
  package-enum-versus-package-constant spellings, runtime signals, unsupported
  actor values, arbitrary expressions, and package constants outside this
  use-site override surface fail closed.
- ISF spec, downstream integration handoff, public contract, mdBook, manifest
  metadata, focused tests, task tree, roadmap, and live docs are synchronized
  where this public behavior changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LIBRARY-USE-PACKAGE-CONSTANTS`
  Status: `done`
  Goal: `Ship bounded package scalar constants in reusable-library use-site parameter overrides.`
  Children: `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.1`,
    `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2`

- ID: `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.1`
  Status: `done`
  Goal: `Select the bounded package-constant reusable-library use-site override slice.`
  Acceptance: `Task tree, roadmap, README index, and live docs name the
  selected value-domain boundary before implementation.`
  Verification: `passed`
  Commit: `f3be036f ISF-LIBRARY-USE-PACKAGE-CONSTANTS.1: select library use package constants`

- ID: `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2`
  Status: `done`
  Goal: `Implement package scalar constants as reusable-library use-site parameter override values.`
  Acceptance: `Lowering behavior, diagnostics, public contracts, focused
  tests, mdBook, downstream handoff, and broader ISF gate are synchronized.`
  Verification: `passed`
  Commit: `684ed1de ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2: ship library use package constants`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The package-constant reusable-library use-site override implementation shipped and the tree is closed. |

## Decisions

- `2026-05-24`: Select only qualified package scalar constants in reusable
  ISF library use-site parameter overrides. This completes the obvious static
  package-constant sibling of actor parameter defaults, generated-child
  transaction defaults, and generated activation overrides without widening
  unrelated value domains.
- `2026-05-24`: Publish use-site override package constants as resolved
  literal generated-top/generated-composition bindings and `library_uses[]`
  report values because reusable-library use-site overrides already
  specialize values at the importing actor boundary.

## Open Questions

- None. Broader package constant surfaces are deferred by this task tree rather
  than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-24` | `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2` | syntax checks; focused reusable-library/package tests with `Files=8, Tests=21`; public/spec/book/backlog audits with `Files=7, Tests=352`; `./bin/ci-regression isf --no-book` with `Files=258, Tests=1701`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.1` | `f3be036f ISF-LIBRARY-USE-PACKAGE-CONSTANTS.1: select library use package constants` | `selection slice` |
| `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2` | `684ed1de ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2: ship library use package constants` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the bounded package scalar
  constants in reusable-library use-site parameter overrides implementation
  frontier.
- `2026-05-24`: Shipped qualified imported package scalar constants in
  reusable-library use-site parameter overrides, resolved those values to
  literal generated-top/generated-composition and `library_uses[]` bindings,
  and closed the task tree.
