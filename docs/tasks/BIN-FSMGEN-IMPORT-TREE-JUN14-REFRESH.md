# BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH: Refresh import-tree measurements after AXI PPIF growth

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH`
- Status: `done`
- Roadmap lane: bootstrap architecture maintenance
- Created: `2026-06-14`
- Last updated: `2026-06-14`
- Owner: repo-local workflow

## Goal

Refresh the live `bin/fsmgen` import-tree architecture note after the session
bootstrap audit found that the saved closure counts and line-count measurements
lag the current AXI manager capacity/status PPIF surface.

## Ground Truth

- The live static trace from `bin/fsmgen` reaches `204` project files total,
  including `203` `FSM::...` `.pm` packages plus `bin/fsmgen`.
- Reachable package-family counts are now: `Support=66`, `Composition=36`,
  `HDL=33`, `Package=14`, `Synthesis=10`, `Adapter=9`, `IR=7`,
  `Scheduler=7`, `Pipeline=5`, `Backend=4`, `Extension=3`, `IAL2=2`,
  `AST=1`, plus the singleton support surfaces.
- The closure drift is explained by the PPIF/protocol-intent surface now
  reaching both `FSM::IAL2::ProtocolIntent::ValidReadyChannel` and
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- `bin/fsmgen` remains `1450` lines; `FSM::Adapter::IAL2::PPIF` is now
  `1493` lines; `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` is
  `3703` lines.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  manifests, tests, or runtime behavior.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).
- Do not broaden the roadmap; this is a bootstrap-maintenance documentation refresh.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the current import-closure counts,
  family counts, PPIF/IAL2 reachability, and measured line-count drift.
- The owning task tree records validation and completion evidence.
- Focused documentation/memory gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH`
  Status: `done`
  Goal: `Refresh stale live import-tree measurements after the June 14 bootstrap audit.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.1`
  Status: `done`
  Goal: `Update docs/BIN_FSMGEN_IMPORT_TREE.md with the current closure counts, AXI PPIF/IAL2 reachability, and stale line-count measurements.`
  Acceptance: `The import-tree note records total=204, pm=203, Support=66, Adapter=9, IAL2=2, AXI manager capacity/status reachability, and refreshed line counts; no behavior-bearing files change.`
  Verification: `passed`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.1: refresh import tree after AXI PPIF growth`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.1` | `done` | Completed; no remaining leaf in this tree. |

## Decisions

- `2026-06-14`: Treat the stale import-tree measurements as bootstrap
  architecture-maintenance documentation drift, not as a behavior slice.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-14` | `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.1` | `perl -Iperl static import-closure trace`; `wc -l` measured files; stale measured-value `rg` scan; `perl -Iperl -c bin/fsmgen`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git --no-pager diff --check` | `passed`; import closure `total=204`, `.pm=203`; stale measured-value scan clean |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.1: refresh import tree after AXI PPIF growth` | Documentation-only bootstrap maintenance slice. |

## Changelog

- `2026-06-14`: Created after the session bootstrap audit remeasured the
  project-owned import topology and found stale closure counts plus stale
  measured line counts in `docs/BIN_FSMGEN_IMPORT_TREE.md`.
- `2026-06-14`: Completed by refreshing the import-tree note with current
  closure counts, AXI manager capacity/status PPIF reachability, refreshed
  measured line counts, and validation evidence.
