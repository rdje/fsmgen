# BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH: Refresh import-tree measurements after VHDL reachability

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH`
- Status: `done`
- Roadmap lane: bootstrap architecture maintenance
- Created: `2026-06-07`
- Last updated: `2026-06-07`
- Owner: repo-local workflow

## Goal

Refresh the live `bin/fsmgen` import-tree architecture note after the session
bootstrap audit found that the reachable project-owned closure and several line-count
measurements drifted from the saved `2026-06-05` baseline.

## Ground Truth

- The live static dependency trace from `bin/fsmgen` now reaches `198` project files
  total and `197` `.pm` packages.
- Reachable package-family counts are now: `Support=65`, `Composition=36`, `HDL=33`,
  `Package=14`, `Synthesis=10`, `Adapter=8`, `IR=7`, `Pipeline=5`, `Scheduler=5`,
  `Backend=4`, `Extension=3`, plus the same singleton support surfaces.
- The closure moved because `perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm` and
  `perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm` are now reachable through the
  direct/composition generation path.
- Current measured line counts that drifted from `docs/BIN_FSMGEN_IMPORT_TREE.md`
  include `perl/FSM/Scheduler/ISF/LoweringIR.pm=12266`,
  `perl/FSM/Adapter/ISF/Parser.pm=9529`,
  `perl/FSM/Pipeline/DirectGenerationOrchestrator.pm=118`,
  `perl/FSM/Composition/GenerationOrchestrator.pm=509`, and
  `perl/FSM/HDL/FlattenedDT.pm=178`.
- `bin/fsmgen` remains `1175` lines.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  manifests, tests, or runtime behavior.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).
- Do not broaden the roadmap; this is a bootstrap-maintenance documentation refresh.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the current import-closure counts, family
  counts, VHDL reachability note, and measured line-count drift.
- The owning task tree records validation and completion evidence.
- Focused documentation/memory gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH`
  Status: `done`
  Goal: `Refresh stale live import-tree measurements after the June 7 bootstrap audit.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1`
  Status: `done`
  Goal: `Update docs/BIN_FSMGEN_IMPORT_TREE.md with the current closure counts, VHDL reachability, and stale line-count measurements.`
  Acceptance: `The import-tree note records total=198, pm=197, HDL=33, Backend=4, the newly reachable VHDL backend owners, and refreshed line counts; no behavior-bearing files change.`
  Verification: `import closure total=198 pm=197`; `wc -l` measured files; stale-value `rg` clean; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1332-isf-atl-doc-status-audit.t`; `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1: refresh import tree after VHDL reachability`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1` | `done` | Saved import-tree note refreshed and validation passed. |

## Decisions

- `2026-06-07`: Treat the stale import-tree measurements as a bootstrap
  architecture-maintenance slice, not as a behavior slice.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-07` | `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1` | `perl -Iperl -MModule::ScanDeps=scan_deps ... bin/fsmgen`; `wc -l` measured files; `rg -n '196|195|12124|9468|11143|11141|11137' docs/BIN_FSMGEN_IMPORT_TREE.md`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1332-isf-atl-doc-status-audit.t`; `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `PASS`; import closure `total=198`, `.pm=197`; stale-value grep clean; focused tests `Files=3, Tests=413` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1: refresh import tree after VHDL reachability` | `pending commit hash` |

## Changelog

- `2026-06-07`: Created after the session bootstrap audit remeasured the project-owned
  import topology and found stale closure counts plus stale measured line counts in
  `docs/BIN_FSMGEN_IMPORT_TREE.md`.
- `2026-06-07`: `.1` completed. Refreshed `docs/BIN_FSMGEN_IMPORT_TREE.md` baseline
  date, import closure (`total=198`, `.pm=197`), package-family counts (`HDL=33`,
  `Backend=4`), VHDL backend reachability, runtime spine entries, and stale measured
  line counts including `LoweringIR.pm=12266`, `Adapter/ISF/Parser.pm=9529`,
  `DirectGenerationOrchestrator.pm=118`, `Composition/GenerationOrchestrator.pm=509`,
  and `FlattenedDT.pm=178`.
