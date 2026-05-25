# ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS: Watchdog Package-Constant Limits

## Metadata

- Tree ID: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow actor-level and await-local watchdog limits to use qualified imported
package scalar constants when those constants resolve to positive integer
scalar literals.

## Non-Goals

- Do not support unqualified package-constant lookup.
- Do not support package aggregate constants or package member/item paths as
  watchdog limits.
- Do not support transaction parameters, runtime interface signals, storage
  signals, arbitrary expressions, or package constants inside watchdog-limit
  expressions.
- Do not specialize watchdog limits through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not change omitted watchdog defaults, watchdog counter decrement/timeout
  semantics, reset behavior, schedule-report key families, or generated HDL
  behavior beyond resolving one more static source kind before existing
  watchdog lowering.
- Do not add distinct per-await limits in one transaction, cross-domain
  watchdog policy, dynamic watchdog limits, or per-await counter reset
  semantics.

## Acceptance Criteria

- Actor-level `(watchdog PACKAGE.CONSTANT)` lowers when the token names a
  qualified imported package scalar constant whose resolved value is positive.
- Await-local `(await ready (watchdog PACKAGE.CONSTANT))` lowers through the
  same watchdog counter path as a literal, actor-constant, or actor-parameter
  limit when the package constant resolves to a positive integer scalar.
- Accepted package constants lower exactly like equivalent positive literal,
  actor-constant, and actor-local scalar-parameter watchdog limits.
- Unsupported watchdog limit sources fail closed with targeted diagnostics:
  unknown package constants, unqualified package constants, aggregate package
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, zero-valued constants, transaction parameters, runtime signals,
  arbitrary expressions, and package constants in unrelated value domains.
- Schedule reports and public parser shells continue to expose watchdog limits
  as resolved integers without adding a separate source-token field.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS`
  Status: `done`
  Goal: `Ship qualified package scalar constants as watchdog limits.`
  Children: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.1`,
  `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2`

- ID: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.1`
  Status: `done`
  Goal: `Select watchdog package-constant limits.`
  Acceptance: `Create the active task tree, record the static package-constant
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`
  Commit: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.1: select watchdog package limits`

- ID: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2`
  Status: `done`
  Goal: `Implement and document package scalar constants in watchdog limits.`
  Acceptance: `Positive package scalar constants lower as literal watchdog
  limits; unsupported watchdog tokens fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `syntax checks`; `prove -Iperl t/1331-isf-timing-conventions.t t/1363-isf-watchdog-package-constant-limits.t t/1160-isf-public-actor-shell-value-shape-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; post-closure public/spec/book audits; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2: support watchdog package limits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2` shipped qualified package scalar constants as watchdog limits and closed the tree. |

## Decisions

- `2026-05-25`: Select qualified imported package scalar constants only.
  Watchdog limits are static timing metadata in the current scheduler, so
  accepted package constants should resolve before the existing watchdog
  counter lowering.
- `2026-05-25`: Preserve the existing positive-only watchdog-limit policy.
  Package constants resolving to zero should fail closed, matching literal
  zero, actor constants resolving to zero, and actor scalar parameters
  resolving to zero.
- `2026-05-25`: Keep the report shape unchanged. Accepted package constants
  should publish only through resolved watchdog integers and normal
  package/import metadata, not through a new source-token field.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |
| `2026-05-25` | `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1363-isf-watchdog-package-constant-limits.t`; `prove -Iperl t/1331-isf-timing-conventions.t t/1363-isf-watchdog-package-constant-limits.t t/1160-isf-public-actor-shell-value-shape-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `prove -Iperl t/1160-isf-public-actor-shell-value-shape-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; focused `Files=12, Tests=393`; broad `Files=269, Tests=1723`; post-closure `Files=8, Tests=377`; final audits `Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.1` | `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.1: select watchdog package limits` | Selection slice; no behavior change. |
| `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2` | `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2: support watchdog package limits` | Implementation slice; package scalar constants now ship for actor-level and await-local watchdog limits. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.1` as the current selection frontier.
- `2026-05-25`: Completed selection leaf and selected
  `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2` as the implementation frontier.
- `2026-05-25`: Completed implementation leaf and closed the task tree.
