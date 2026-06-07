# MDBOOK-CODEBASE-SYNC-AUDIT-JUN07: mdBook/Codebase Sync Audit

## Metadata

- Tree ID: `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07`
- Status: `done`
- Roadmap lane: `roadmap/documentation alignment`
- Created: `2026-06-07`
- Last updated: `2026-06-07`
- Owner: repo-local workflow

## Goal

Audit whether the user-facing mdBook and public documentation are synchronized
with the current codebase, task-tree roadmap, public contracts, shipped examples,
and explicit deferrals.

## Non-Goals

- Do not change code, generated artifacts, parser behavior, scheduler behavior,
  backend behavior, diagnostics, public contracts, or examples as part of this
  audit.
- Do not treat a discovered gap as implementation permission; any repair needs a
  separate exact task-tree owner before changes.

## Acceptance Criteria

- Existing mdBook, example, public-contract, task-tree, memory, knowledge-map,
  and path-safety gates are run or explicitly marked unavailable with a reason.
- The audit samples the current user-facing feature/backlog surfaces against the
  active task-tree and resume-pointer state.
- Findings are recorded in this task tree with enough evidence to recover the
  conclusion after a session loss.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07`
  Status: `done`
  Goal: `Audit mdBook/codebase/user-facing sync.`
  Children: `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1`

- ID: `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1`
  Status: `done`
  Goal: `Run the sync audit and record whether any user-facing drift is found.`
  Acceptance: `Existing documentation/build/example/contract gates pass or are
  recorded with blockers, user-facing roadmap/book surfaces are sampled against
  current task-tree status, and any gap is captured for future exact ownership.`
  Verification: `mdBook, public-contract, book-example, feature-matrix,
  feature-backlog, path, memory, Knowledge Map, documentation-contract, and ISF
  regression gates passed; quick regression reproduced one stale composition
  plan-net count assertion in t/84.`
  Commit: `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1: audit book/code sync`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `done` | Audit completed and finding recorded. |

## Decisions

- `2026-06-07`: This audit is documentation/roadmap maintenance only. It may
  record evidence, but any behavior-bearing or book-repair work discovered by
  the audit requires its own exact active task-tree leaf before changes.
- `2026-06-07`: The audit found no mdBook/public-doc drift in the checked
  user-facing surfaces. It did find one codebase lock failure:
  `t/84-composition-external-fsm-child-sources.t` still counts all
  `composition_plan->nets` entries as if only one child-to-child carrier should
  exist. Current code also emits documented `shared_dp_unused_*` sink wires for
  generated-child shared-datapath export-enable pins, so the quick-suite failure
  is classified as a stale test assertion requiring a future exact owner.

## Open Questions

- Future exact owner needed if the project chooses to repair the quick-suite
  lock failure: update or replace the stale `t/84` net-count assertion so it
  proves the child-to-child carrier without rejecting documented
  `shared_dp_unused_*` sink nets.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-07` | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t t/1332-isf-atl-doc-status-audit.t t/1376-isf-book-example-lowering-audit.t t/1377-book-fsm-example-generation-audit.t t/1414-docs-relative-paths-audit.t` | `PASS`; 10 files / 895 tests; 64 complete ISF book fixtures lowered; 14 standalone `.fsm` book fixtures generated; docs-relative path guard clean. |
| `2026-06-07` | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `prove -Iperl t/111*.t t/112*.t t/113*.t t/114*.t t/115*.t t/116*.t` | `PASS`; 66 files / 468 tests; public ISF parser/scheduler/facade/report/live-doc surfaces green. |
| `2026-06-07` | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `prove -Iperl t/318-documentation-contract.t t/362-documentation-section-runtime-contract-audit.t t/448-documentation-contract-defensive-copy-boundary-audit.t t/965-capability-manifest-documentation-contract-identity-json-roundtrip-audit.t t/966-capability-manifest-documentation-contract-entrypoints-json-roundtrip-audit.t t/967-capability-manifest-documentation-contract-public-path-keys-json-roundtrip-audit.t t/970-capability-manifest-documentation-contract-identity-defensive-copy-audit.t t/971-capability-manifest-documentation-contract-entrypoints-defensive-copy-audit.t t/973-capability-manifest-documentation-contract-path-contracts-defensive-copy-audit.t` | `PASS`; 9 files / 15 tests. |
| `2026-06-07` | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `mdbook build docs/book` | `PASS`; HTML book generated. |
| `2026-06-07` | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `./bin/ci-regression isf --no-book` | `PASS`; 294 files / 2126 tests. |
| `2026-06-07` | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `prove -Iperl t/247-protocol-fixture-regression-smoke.t t/146-composition-shared-datapath-lifted-register-runtime.t t/147-composition-shared-datapath-internal-lifted-register-runtime.t t/308-systemverilog-external-validation.t` | `PASS`; 4 files / 16 tests; reverified documented `shared_dp_unused_*` sink-wire behavior. |
| `2026-06-07` | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `./bin/ci-regression quick --no-book`; `prove -Iperl t/84-composition-external-fsm-child-sources.t`; read `t/84`, `docs/book/src/09-generated-hdl-debugging-and-inspection.md`, `docs/book/src/14-feature-backlog.md`, `docs/knowledge/composition-shared-datapath-export-sinks.md`; temp probe of the failing fixture's `composition_plan->nets` | `FAIL reproduced`; `t/84` expected 1 net but observed 3: `comp_link_producer_output_data` plus two documented `shared_dp_unused_*` sink nets. Classified as stale test assertion, not observed mdBook drift. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` | `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1: audit book/code sync` | Audit completed; no checked mdBook/public-doc drift found; one stale quick-regression assertion recorded for future exact ownership. |

## Changelog

- `2026-06-07`: Created task tree for the requested mdBook/codebase sync audit.
- `2026-06-07`: Completed the audit, recorded the green gates, and captured the
  reproducible `t/84` quick-suite lock failure as a future exact-owner repair.
