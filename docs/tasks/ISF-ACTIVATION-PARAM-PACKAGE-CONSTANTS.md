# ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS: Package Constants In Activation Parameter Overrides

## Metadata

- Tree ID: `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow generated activation parameter override scalar values and scalar leaves
inside compatible aggregate/list override values to reference imported package
scalar constants by qualified name, for example `shared.DEFAULT_WIDTH`.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as activation parameter override values in this tree.
- Do not widen reusable-library use-site overrides, waits, watchdogs, latency
  bounds, contract windows, repeat counts, storage or interface dimensions, or
  other value domains to package constants in this tree.
- Do not change the already shipped actor parameter or generated-child
  transaction parameter package-constant defaults except where diagnostics need
  to name the new boundary.
- Do not introduce arbitrary expressions, dependency graph solving, package
  aliasing, or package namespace pollution.

## Acceptance Criteria

- Generated activation parameter overrides on shipped spawn, generated blocking
  `do`, and rule-trigger activation sites may use `PACKAGE.CONSTANT` when the
  parent actor imports the package and the package constant resolves to a scalar
  numeric or exact-width literal.
- Scalar leaves inside compatible aggregate/list generated activation override
  values may use the same qualified package scalar constants.
- Activation override publication stays self-contained by resolving package
  constants to literal generated-top bindings and generated-composition report
  values.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous
  package-enum-versus-package-constant spellings, runtime signals, unsupported
  actor values, arbitrary expressions, and package constants outside this
  activation override surface fail closed.
- ISF spec, downstream integration handoff, public contract, mdBook, manifest
  metadata, focused tests, task tree, roadmap, and live docs are synchronized
  where this public behavior changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS`
  Status: `done`
  Goal: `Ship bounded package scalar constants in generated activation parameter overrides.`
  Children: `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.1`,
    `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2`

- ID: `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.1`
  Status: `done`
  Goal: `Select the bounded package-constant generated activation override slice.`
  Acceptance: `Task tree, roadmap, README index, and live docs name the
  selected value-domain boundary before implementation.`
  Verification: `passed`
  Commit: `d915dd57 ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.1: select activation package constants`

- ID: `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2`
  Status: `done`
  Goal: `Implement package scalar constants as generated activation parameter override values.`
  Acceptance: `Lowering behavior, diagnostics, public contracts, focused
  tests, mdBook, downstream handoff, and broader ISF gate are synchronized.`
  Verification: `passed`
  Commit: `8531b4af ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2: ship activation package constants`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The package-constant generated activation override boundary shipped and the tree is complete. |

## Decisions

- `2026-05-24`: Select only qualified package scalar constants in generated
  activation parameter overrides. This follows the actor parameter and
  generated-child transaction parameter package-constant boundaries while
  keeping unrelated value domains closed.
- `2026-05-24`: Publish activation override package constants as resolved
  literal generated-top bindings and generated-composition report values
  because activation override publication already specializes values into the
  generated top rather than preserving child-local parameter defaults.

## Open Questions

- None. Broader package constant surfaces are deferred by this task tree rather
  than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2` | syntax checks; `prove -Iperl t/1351-isf-activation-param-package-constants.t t/1249-isf-activation-parameter-constants.t t/1271-isf-enum-member-activation-params.t t/1276-isf-enum-member-activation-aggregate-params.t t/1350-isf-transaction-param-package-constants.t t/1349-isf-actor-param-package-constants.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1113-isf-public-interface-contract-json-roundtrip-audit.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed: focused Files=6 Tests=18; audits Files=7 Tests=352; ISF gate Files=257 Tests=1699` |
| `2026-05-24` | `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.1` | `d915dd57 ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.1: select activation package constants` | `selection slice` |
| `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2` | `8531b4af ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2: ship activation package constants` | `implementation slice` |

## Changelog

- `2026-05-24`: Shipped qualified imported package scalar constants in
  generated activation parameter overrides; spawn, generated blocking `do`,
  and rule-trigger activation sites resolve those constants to literal
  generated-top bindings and generated-composition report values.
- `2026-05-24`: Created task tree and selected the bounded package scalar
  constants in generated activation parameter overrides implementation
  frontier.
