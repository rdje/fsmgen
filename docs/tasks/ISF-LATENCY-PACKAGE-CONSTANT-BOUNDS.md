# ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS: Latency Package-Constant Bounds

## Metadata

- Tree ID: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow transaction latency `(min ...)` and `(max ...)` bounds to use qualified
imported package scalar constants when those constants resolve to positive
integer scalar literals.

## Non-Goals

- Do not support unqualified package-constant lookup.
- Do not support package aggregate constants or package member/item paths as
  latency bounds.
- Do not support transaction parameters, runtime interface signals, storage
  signals, arbitrary expressions, or package constants inside latency-bound
  expressions.
- Do not specialize latency bounds through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not change latency counter timing, timeout-state semantics,
  schedule-report storage roles, or generated HDL behavior beyond resolving
  one more static source kind before existing lowering.
- Do not add stage-local latency or actor-level stage runtime semantics.

## Acceptance Criteria

- `(latency (min PACKAGE.CONSTANT) (max PACKAGE.CONSTANT))` lowers when each
  token names a qualified imported package scalar constant whose resolved
  value is positive.
- Accepted package constants lower exactly like equivalent positive literal,
  actor-constant, and actor-local scalar-parameter latency bounds.
- Unsupported latency-bound sources fail closed with targeted diagnostics:
  unknown package constants, unqualified package constants, aggregate package
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, zero-valued constants, transaction parameters, runtime signals,
  arbitrary expressions, and package constants in unrelated value domains.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS`
  Status: `done`
  Goal: `Ship qualified package scalar constants as transaction latency min/max bounds.`
  Children: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.1`,
  `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2`

- ID: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.1`
  Status: `done`
  Goal: `Select latency package-constant bounds.`
  Acceptance: `Create the active task tree, record the static package-constant
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`
  Commit: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.1: select latency package bounds`

- ID: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2`
  Status: `done`
  Goal: `Implement and document package scalar constants in transaction latency bounds.`
  Acceptance: `Positive package scalar constants lower as literal latency
  bounds; unsupported bound tokens fail closed; specs, book, public contract,
  downstream handoff, and focused tests are synchronized.`
  Verification: `syntax checks`; focused latency/public/spec/book tests with `Files=9, Tests=380`; `./bin/ci-regression isf --no-book` with `Files=267, Tests=1719`; post-closure public/spec/book audits with `Files=7, Tests=374`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2: support latency package bounds`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2` | `done` | Closed: transaction latency min/max bounds now accept qualified imported package scalar constants in the bounded positive integer surface. |

## Decisions

- `2026-05-25`: Select qualified imported package scalar constants only.
  Latency bounds are static timing metadata, so accepted package constants
  should resolve before the existing latency counter and timeout lowering.
- `2026-05-25`: Preserve the existing positive-only latency-bound policy.
  Package constants resolving to zero should fail closed, matching literal
  zero, actor constants resolving to zero, and actor scalar parameters
  resolving to zero.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |
| `2026-05-25` | `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2` | syntax checks; `prove -Iperl t/1197-isf-latency-clause-boundary.t t/1361-isf-latency-package-constant-bounds.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; post-closure public/spec/book audits; `mdbook build docs/book`; `git diff --check` | `passed`; focused audits `Files=9, Tests=380`; broad gate `Files=267, Tests=1719`; post-closure audits `Files=7, Tests=374` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.1` | `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.1: select latency package bounds` | Selection slice; no behavior change. |
| `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2` | `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2: support latency package bounds` | Implementation slice; package scalar constants in transaction latency min/max bounds. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2` as the next implementation frontier.
- `2026-05-25`: Implemented qualified imported package scalar constants in
  transaction latency min/max bounds and closed the task tree.
