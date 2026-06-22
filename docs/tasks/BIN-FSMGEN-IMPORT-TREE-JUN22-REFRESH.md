# BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH: Refresh import-tree measurements after dynamic ID metadata

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-06-22`
- Last updated: `2026-06-22`
- Owner: repo-local workflow

## Goal

Refresh the live `bin/fsmgen` import-tree architecture note after the session
bootstrap audit found that the saved closure shape is still current, but the
measured line counts lag the latest IAL2 dynamic transaction-ID metadata work.

## Ground Truth

- The live static trace from `bin/fsmgen` still reaches `206` project files
  total, including `205` `FSM::...` `.pm` packages plus `bin/fsmgen`.
- Reachable package-family counts remain: `Support=68`, `Composition=36`,
  `HDL=33`, `Package=14`, `Synthesis=10`, `Adapter=9`, `IR=7`,
  `Scheduler=7`, `Pipeline=5`, `Backend=4`, `Extension=3`, `IAL2=2`,
  `AST=1`, plus the singleton support surfaces.
- The stale measurements are line-count drift only, concentrated in
  `bin/fsmgen`, the PPIF parser, AXI manager capacity/status owner, ISF parser,
  ISF lowering/report owners, and regression corpus.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  manifests, tests, samples, support-accounting behavior, or runtime behavior.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).
- Do not broaden the roadmap; this is a bootstrap-maintenance documentation
  refresh.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the current import-closure counts
  and refreshed line-count measurements.
- The owning task tree records validation and completion evidence.
- Focused documentation/memory gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH`
  Status: `done`
  Goal: `Refresh stale live import-tree measurements after the June 22 bootstrap audit.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.1`
  Status: `done`
  Goal: `Update docs/BIN_FSMGEN_IMPORT_TREE.md with the current closure counts and stale line-count measurements.`
  Acceptance: `The import-tree note records total=206, pm=205, unchanged family counts, and refreshed line counts for the changed CLI/IAL2/ISF/support owners; no behavior-bearing files change.`
  Verification: `perl -Iperl static import-closure trace`; `wc -l` measured files; stale measured-value `rg` scan; `perl -Iperl -c bin/fsmgen`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git --no-pager diff --check`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.1: refresh import tree after dynamic ID metadata`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.1` | `done` | Bootstrap audit found stale measured line counts while the import closure remains structurally current. |

## Decisions

- `2026-06-22`: Treat stale import-tree measurements as
  bootstrap architecture-maintenance documentation drift, not as a behavior
  slice.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-22` | `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.1` | `perl -Iperl static import-closure trace`; `wc -l` measured files; stale measured-value `rg` scan; `perl -Iperl -c bin/fsmgen`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git --no-pager diff --check` | `pass`; import closure `total=206`, `.pm=205`; stale measured-value scan clean |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.1: refresh import tree after dynamic ID metadata` | Documentation-only bootstrap maintenance slice. |

## Changelog

- `2026-06-22`: Created after the session bootstrap audit remeasured the
  project-owned import topology and found unchanged closure counts but stale
  measured line counts in `docs/BIN_FSMGEN_IMPORT_TREE.md`.
- `2026-06-22`: Completed by refreshing the import-tree note with unchanged
  closure counts and current measured line counts after dynamic transaction-ID
  metadata growth.
