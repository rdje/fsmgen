# BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH: Refresh import-tree measurements after semantic-introspection and AXI growth

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-06-16`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Refresh the live `bin/fsmgen` import-tree architecture note after the session
bootstrap audit found that the saved closure counts and line-count
measurements lag the current semantic-introspection support surface and AXI
manager capacity/status implementation.

## Ground Truth

- The live static trace from `bin/fsmgen` reaches `206` project files total,
  including `205` `FSM::...` `.pm` packages plus `bin/fsmgen`.
- Reachable package-family counts are now: `Support=68`, `Composition=36`,
  `HDL=33`, `Package=14`, `Synthesis=10`, `Adapter=9`, `IR=7`,
  `Scheduler=7`, `Pipeline=5`, `Backend=4`, `Extension=3`, `IAL2=2`,
  `AST=1`, plus the singleton support surfaces.
- The closure drift is explained by the first-class semantic-introspection
  support surface now reaching both `FSM::Support::SemanticIntrospectionSection`
  and `FSM::Support::SemanticIntrospectionContract`.
- The measured AXI manager capacity/status owner line count is now `4882`.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  manifests, tests, or runtime behavior.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).
- Do not broaden the roadmap; this is a bootstrap-maintenance documentation
  refresh.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the current import-closure counts,
  support-section reachability, and refreshed line-count measurements.
- The owning task tree records validation and completion evidence.
- Focused documentation/memory gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH`
  Status: `done`
  Goal: `Refresh stale live import-tree measurements after the June 16 bootstrap audit.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.1`
  Status: `done`
  Goal: `Update docs/BIN_FSMGEN_IMPORT_TREE.md with the current closure counts, semantic-introspection reachability, and stale line-count measurements.`
  Acceptance: `The import-tree note records total=206, pm=205, Support=68, semantic-introspection section/contract reachability, and refreshed line counts; no behavior-bearing files change.`
  Verification: `perl -Iperl static import-closure trace`; `wc -l` measured files; stale measured-value `rg` scan; `perl -Iperl -c bin/fsmgen`; `knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.1: refresh import tree after semantic support growth`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.1` | `done` | Completed; no remaining leaf in this tree. |

## Decisions

- `2026-06-16`: Treat the stale import-tree measurements as bootstrap
  architecture-maintenance documentation drift, not as a behavior slice.
- `2026-06-16`: The refreshed static trace records `206` project files total
  and `205` `.pm` packages, with `Support=68` after first-class
  semantic-introspection support became reachable through the manifest surface.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `.1` | `perl -Iperl static import-closure trace`; `wc -l` measured files; stale measured-value `rg` scan; `perl -Iperl -c bin/fsmgen`; `knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass`; import closure `total=206`, `.pm=205`; stale measured-value scan clean |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.1: refresh import tree after semantic support growth` | Pending import-tree refresh commit. |

## Changelog

- `2026-06-16`: Created after the session bootstrap audit remeasured the
  project-owned import topology and found stale closure counts plus stale
  measured line counts in `docs/BIN_FSMGEN_IMPORT_TREE.md`.
- `2026-06-16`: Completed by refreshing the import-tree note with current
  closure counts, semantic-introspection reachability, refreshed measured line
  counts, a Knowledge Map pointer card, and validation evidence.
