# ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS: Package Constants In Generated Child Transaction Defaults

## Metadata

- Tree ID: `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow generated-child transaction parameter scalar defaults and scalar leaves
inside compatible aggregate/list defaults to reference imported package scalar
constants by qualified name, for example `shared.DEFAULT_WIDTH`.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as generated-child transaction parameter defaults in this slice.
- Do not widen activation-site overrides, reusable-library use-site overrides,
  waits, watchdogs, latency bounds, contract windows, repeat counts, storage or
  interface dimensions, or other value domains to package constants in this
  tree.
- Do not change actor-static transaction parameter defaults, earlier
  transaction-parameter dependency defaults, or enum-member transaction
  parameter defaults except where diagnostics need to name the new boundary.
- Do not introduce arbitrary expressions, dependency graph solving, package
  aliasing, or package namespace pollution.

## Acceptance Criteria

- A generated child transaction may use `PACKAGE.CONSTANT` as a scalar
  parameter default when the parent actor imports the package and the package
  constant resolves to a scalar numeric or exact-width literal.
- Scalar leaves inside compatible aggregate/list generated-child transaction
  parameter defaults may use the same qualified package scalar constants.
- Authored `PACKAGE.CONSTANT` tokens remain visible in generated child `.fsm`
  `+params`, generated-composition child summaries, and default instance
  bindings because generated child artifacts preserve package imports and
  embedded package roots.
- Resolved literals are recorded internally for lowerer consumers and
  diagnostics.
- Unknown package constants, package aggregate constants, ambiguous
  package-enum-versus-package-constant spellings, runtime signals, actor
  parameters that are not already shipped in this context, arbitrary
  expressions, and package constants outside this generated-child transaction
  default surface fail closed.
- ISF spec, downstream integration handoff, public contract, mdBook, manifest
  metadata, focused tests, task tree, roadmap, and live docs are synchronized
  where this public behavior changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS`
  Status: `active`
  Goal: `Ship bounded package scalar constants in generated-child transaction parameter defaults.`
  Children: `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.1`,
    `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.2`

- ID: `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.1`
  Status: `done`
  Goal: `Select the bounded package-constant generated-child transaction parameter default slice.`
  Acceptance: `Task tree, roadmap, README index, and live docs name the
  selected value-domain boundary before implementation.`
  Verification: `passed`
  Commit: `this commit: ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.1: select transaction package constants`

- ID: `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.2`
  Status: `pending`
  Goal: `Implement package scalar constants as generated-child transaction parameter defaults.`
  Acceptance: `Lowering behavior, diagnostics, public contracts, focused
  tests, mdBook, downstream handoff, and broader ISF gate are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.2` | `pending` | The package-constant generated-child transaction parameter default boundary is selected and ready for implementation. |

## Decisions

- `2026-05-24`: Select only qualified package scalar constants in
  generated-child transaction parameter defaults. This mirrors the actor
  parameter package-constant boundary while keeping unrelated value domains
  closed.
- `2026-05-24`: Preserve authored package-constant tokens in generated child
  review surfaces because generated child scheduled `.fsm` artifacts already
  carry package imports and embedded package roots for package enum defaults.

## Open Questions

- None. Broader package constant surfaces are deferred by this task tree rather
  than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.1` | `this commit: ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.1: select transaction package constants` | `selection slice` |
| `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the bounded package scalar
  constants in generated-child transaction parameter defaults implementation
  frontier.
