# ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS: Package Constants In Actor Parameter Defaults

## Metadata

- Tree ID: `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Implement package scalar constants as actor parameter defaults.`
  Acceptance: `Parser/lowerer behavior, diagnostics, public contracts,
  focused tests, mdBook, downstream handoff, and broader ISF gate are
  synchronized.`
  Verification: `passed`
  Commit: `this commit: ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2: ship package constant defaults`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The package-constant actor parameter default implementation leaf shipped and the task tree is complete. |

## Decisions

- `2026-05-24`: Select only qualified package scalar constants in actor
  parameter defaults. This reuses existing package `+constants` parsing while
  avoiding broader package value-domain widening.
- `2026-05-24`: Preserve authored package-constant tokens in review surfaces
  because scheduled `.fsm` artifacts embed the imported package root and keep
  the matching `+import` review artifact.
- `2026-05-24`: Keep package constants qualified and scalar-only in this
  slice. Parser and LoweringIR both reject unqualified constants, unknown
  constants, aggregate constants, member/item paths, and ambiguous
  local-enum/package-constant spellings.

## Open Questions

- None. Broader package constant surfaces are deferred by this task tree
  rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-24` | `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2` | syntax checks; `prove -Iperl t/1349-isf-actor-param-package-constants.t t/1345-isf-actor-param-actor-constants.t t/1346-isf-actor-param-actor-params.t t/1269-isf-enum-member-actor-params.t t/1277-isf-enum-member-actor-aggregate-params.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1113-isf-public-interface-contract-json-roundtrip-audit.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1` | `this commit: ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1: select package constant defaults` | `selection slice` |
| `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2` | `this commit: ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2: ship package constant defaults` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the bounded package scalar
  constants in actor parameter defaults implementation frontier.
- `2026-05-24`: Shipped qualified imported package scalar constants in actor
  parameter defaults, synchronized specs/contracts/mdBook/downstream handoff,
  and closed the task tree.
