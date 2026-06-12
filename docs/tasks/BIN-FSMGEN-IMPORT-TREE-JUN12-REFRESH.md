# BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH: Refresh import-tree measurements after PPIF bundle growth

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH`
- Status: `done`
- Roadmap lane: bootstrap architecture maintenance
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Refresh the live `bin/fsmgen` import-tree architecture note after the session
bootstrap audit found that the saved closure counts and line-count measurements
lag the current PPIF / protocol-intent bundle surface.

## Ground Truth

- The live `Module::ScanDeps` trace from `bin/fsmgen` reaches `203` project
  files total, including `202` `FSM::...` `.pm` packages plus `bin/fsmgen`.
- Reachable package-family counts are now: `Support=66`, `Composition=36`,
  `HDL=33`, `Package=14`, `Synthesis=10`, `Adapter=9`, `IR=7`,
  `Scheduler=7`, `Pipeline=5`, `Backend=4`, `Extension=3`, `AST=1`,
  `IAL2=1`, plus the singleton support surfaces.
- The closure drift is explained by the PPIF/protocol-intent bundle surface:
  `FSM::Adapter::IAL2::PPIF`, `FSM::IAL2::ProtocolIntent::ValidReadyChannel`,
  and `FSM::Support::NormalizedSemanticProtocolIntentBundleContract`.
- `bin/fsmgen` is now `1450` lines.

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

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH`
  Status: `done`
  Goal: `Refresh stale live import-tree measurements after the June 12 bootstrap audit.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.1`
  Status: `done`
  Goal: `Update docs/BIN_FSMGEN_IMPORT_TREE.md with the current closure counts, PPIF/IAL2 reachability, and stale line-count measurements.`
  Acceptance: `The import-tree note records total=203, pm=202, Support=66, Adapter=9, IAL2=1, PPIF/protocol-intent bundle reachability, and refreshed line counts; no behavior-bearing files change.`
  Verification: `passed`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.1: refresh import tree after PPIF growth`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.1` | `done` | Completed; no remaining leaf in this tree. |

## Decisions

- `2026-06-12`: Treat the stale import-tree measurements as bootstrap
  architecture-maintenance documentation drift, not as a behavior slice.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.1` | `perl -Iperl -MModule::ScanDeps=scan_deps ...`; `perl -Iperl -c bin/fsmgen`; `./bin/fsmgen --capability-manifest >/tmp/fsmgen_manifest_bootstrap_check.json`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git --no-pager diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.1: refresh import tree after PPIF growth` | Documentation-only bootstrap maintenance slice. |

## Changelog

- `2026-06-12`: Created after the session bootstrap audit remeasured the
  project-owned import topology and found stale closure counts plus stale
  measured line counts in `docs/BIN_FSMGEN_IMPORT_TREE.md`.
- `2026-06-12`: Completed by refreshing the import-tree note with current
  closure counts, PPIF/IAL2 reachability, protocol-intent bundle contract
  ownership, refreshed measured line counts, and validation evidence.
