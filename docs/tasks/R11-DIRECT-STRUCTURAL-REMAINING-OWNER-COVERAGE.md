# R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE: Direct Structural Remaining Owner Coverage

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Give every roadmap-named remaining direct `StructuralRTLIR` gap an exact
task-tree owner before any further behavior-bearing direct structural work.

## Non-Goals

- Do not change code, tests, generated artifacts, generated HDL, or public
  semantic payloads in this owner-coverage slice.
- Do not activate a behavior-bearing implementation leaf in the same slice.
- Do not collapse distinct remaining direct structural gaps into one vague
  catch-all owner.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).

## Acceptance Criteria

- Exact proposed task trees exist for direct port dependency connectivity,
  output-drive/always-block consumers, direct instances/links, full direct
  module rerouting, and VHDL rerouting through `StructuralRTLIR`.
- `docs/TASK_TREE.md` lists those proposed owners so a future PNT slice can
  explicitly activate one before implementation.
- Roadmap, README, mdBook backlog, and Knowledge Map wording name the owners
  and stay aligned with the current shipped direct structural surface.
- Documentation, memory, Knowledge Map, and path/diff gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE`
  Status: `done`
  Goal: `Task-tree own the remaining roadmap-named direct StructuralRTLIR gaps.`
  Children: `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.1`

- ID: `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.1`
  Status: `done`
  Goal: `Create exact proposed owners for remaining direct StructuralRTLIR gaps.`
  Acceptance: `The five remaining direct StructuralRTLIR gaps named by README, ROADMAP_V2, and the mdBook backlog have proposed task-tree files, task-tree index rows, aligned public wording, and passing docs/memory gates without behavior changes.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.1: own remaining direct structural gaps`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.1` | `done` | Created exact proposed owners for the remaining direct `StructuralRTLIR` gaps; no active next leaf remains in this tree. |

## Decisions

- `2026-06-12`: Use exact proposed owner trees instead of appending more
  leaves to completed implementation trees, because the remaining gaps have
  distinct readiness criteria and blast radii.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.1` | `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.1` | `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.1: own remaining direct structural gaps` | Created exact proposed task-tree owners for remaining direct `StructuralRTLIR` gaps. |

## Changelog

- `2026-06-12`: Created owner-coverage tree for remaining direct
  `StructuralRTLIR` roadmap gaps.
- `2026-06-12`: Completed `.1`; proposed owner trees now track direct port
  dependency connectivity, output-drive consumers, direct instances/links,
  full direct SystemVerilog rerouting, and direct VHDL rerouting.
