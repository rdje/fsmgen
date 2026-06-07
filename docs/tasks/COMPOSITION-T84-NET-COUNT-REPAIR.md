# COMPOSITION-T84-NET-COUNT-REPAIR: Repair t/84 Composition Net Count Assertion

## Metadata

- Tree ID: `COMPOSITION-T84-NET-COUNT-REPAIR`
- Status: `done`
- Roadmap lane: `composition/test integrity`
- Created: `2026-06-07`
- Last updated: `2026-06-07`
- Owner: repo-local workflow

## Goal

Repair the stale `t/84-composition-external-fsm-child-sources.t` assertion so
the quick regression proves the intended child-to-child composition carrier
while accepting documented generated-child `shared_dp_unused_*` sink nets.

## Non-Goals

- Do not change composition behavior, generated HDL, public top interfaces,
  mdBook feature claims, or shared-datapath semantics.
- Do not weaken the test to merely count fewer things; the repaired assertion
  must still prove the expected explicit child-to-child carrier.

## Acceptance Criteria

- `t/84-composition-external-fsm-child-sources.t` passes in isolation.
- `./bin/ci-regression quick --no-book` passes.
- The Knowledge Map fact for the audit gap is updated to the repaired state.
- Task-tree, resume pointer, Knowledge Map, memory, and path gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `COMPOSITION-T84-NET-COUNT-REPAIR`
  Status: `done`
  Goal: `Repair stale t/84 composition net-count regression.`
  Children: `COMPOSITION-T84-NET-COUNT-REPAIR.1`

- ID: `COMPOSITION-T84-NET-COUNT-REPAIR.1`
  Status: `done`
  Goal: `Update t/84 to assert the explicit child-to-child carrier separately
  from documented shared-datapath sink nets.`
  Acceptance: The test checks for the expected `comp_link_producer_output_data`
  carrier and does not fail merely because current generated-child composition
  also reports documented `shared_dp_unused_*` sink nets.
  Verification: `prove -Iperl t/84-composition-external-fsm-child-sources.t`;
  `./bin/ci-regression quick --no-book`; required documentation/memory gates.
  Commit: `COMPOSITION-T84-NET-COUNT-REPAIR.1: repair t84 net count`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `COMPOSITION-T84-NET-COUNT-REPAIR.1` | `done` | Repaired the stale net-count assertion and restored quick-suite pass. |

## Decisions

- `2026-06-07`: The fix is test-integrity only. Current code behavior and
  mdBook documentation already agree that `shared_dp_unused_*` sink wires are
  intentional and do not alter the public top interface.
- `2026-06-07`: `t/84` now proves the explicit child-to-child data carrier by
  name, width, source, and target, while rejecting any non-carrier net that is
  not a documented generated-child shared-datapath sink net.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-07` | `COMPOSITION-T84-NET-COUNT-REPAIR.1` | `prove -Iperl t/84-composition-external-fsm-child-sources.t` | `PASS`; 1 file / 3 subtests. |
| `2026-06-07` | `COMPOSITION-T84-NET-COUNT-REPAIR.1` | `./bin/ci-regression quick --no-book` | `PASS`; 8 files / 145 tests. |
| `2026-06-07` | `COMPOSITION-T84-NET-COUNT-REPAIR.1` | `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `COMPOSITION-T84-NET-COUNT-REPAIR.1` | `COMPOSITION-T84-NET-COUNT-REPAIR.1: repair t84 net count` | Repaired stale quick-regression assertion without behavior changes. |

## Changelog

- `2026-06-07`: Created exact owner for repairing the stale `t/84`
  composition net-count assertion.
- `2026-06-07`: Completed the repair and restored the quick regression gate.
