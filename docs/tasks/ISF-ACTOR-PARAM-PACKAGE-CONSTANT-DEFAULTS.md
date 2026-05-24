# ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS: Package Constants In Actor Parameter Defaults

## Metadata

- Tree ID: `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow actor-level `(params ...)` scalar defaults and scalar leaves inside
compatible aggregate/list defaults to reference imported package scalar
constants by qualified name, for example `shared.DEFAULT_WIDTH`.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as actor parameter defaults in this slice.
- Do not widen interface/storage/transaction-port width tokens, watchdogs,
  waits, latency bounds, contract windows, repeat counts, activation
  overrides, reusable-library use-site overrides, generated child transaction
  parameter defaults, or other value domains to package constants in this
  tree.
- Do not introduce arbitrary expressions, dependency graph solving, package
  aliasing, or package namespace pollution.

## Acceptance Criteria

- A parsed actor importing a package may use `PACKAGE.CONSTANT` as an
  actor-level scalar parameter default when the imported package constant
  resolves to a scalar numeric or exact-width literal.
- Scalar leaves inside compatible aggregate/list actor parameter defaults may
  use the same qualified package scalar constants.
- Authored `PACKAGE.CONSTANT` tokens remain visible in scheduled `.fsm`
  `+params` and `actor_params[]`, while resolved literals are recorded
  internally for scalar actor-parameter consumers.
- Unknown package constants, package aggregate constants, ambiguous
  local-enum-versus-package-constant two-part tokens, runtime signals,
  transaction parameters, arbitrary expressions, and package constants outside
  this actor parameter default surface fail closed.
- ISF spec, downstream integration handoff, public contract, mdBook, manifest
  metadata, focused tests, task tree, roadmap, and live docs are synchronized
  where this public behavior changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS`
  Status: `active`
  Goal: `Ship bounded package scalar constants in actor parameter defaults.`
  Children: `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1`,
    `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2`

- ID: `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1`
  Status: `done`
  Goal: `Select the bounded package-constant actor parameter default slice.`
  Acceptance: `Task tree, roadmap, README index, and live docs name the
  selected value-domain boundary before implementation.`
  Verification: `passed`
  Commit: `this commit: ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1: select package constant defaults`

- ID: `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2`
  Status: `pending`
  Goal: `Implement package scalar constants as actor parameter defaults.`
  Acceptance: `Parser/lowerer behavior, diagnostics, public contracts,
  focused tests, mdBook, downstream handoff, and broader ISF gate are
  synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2` | `pending` | The package-constant actor parameter default boundary is now selected and ready for implementation. |

## Decisions

- `2026-05-24`: Select only qualified package scalar constants in actor
  parameter defaults. This reuses existing package `+constants` parsing while
  avoiding broader package value-domain widening.
- `2026-05-24`: Preserve authored package-constant tokens in review surfaces
  because scheduled `.fsm` artifacts embed the imported package root and keep
  the matching `+import` review artifact.

## Open Questions

- None. Broader package constant surfaces are deferred by this task tree
  rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1` | `this commit: ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1: select package constant defaults` | `selection slice` |
| `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the bounded package scalar
  constants in actor parameter defaults implementation frontier.
