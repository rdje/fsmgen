# BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH: Refresh Import Tree After Generated-Child Second AwaitAny

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Refresh the saved `bin/fsmgen` import-tree architecture snapshot after the
R14 generated-child prior-`await_any` plus second post-spawn `await_any`
slice changed the measured `LoweringIR.pm` hotspot line count.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  tests, or runtime behavior.
- Do not change the project-owned import-closure topology unless the live
  static trace proves it moved.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- Live `bin/fsmgen` project-owned import-closure counts are re-measured.
- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the current measured
  `LoweringIR.pm` line count and remains honest about unchanged closure
  topology.
- README, roadmap, task tree, memory, changes, development notes, and live
  achievement status record the maintenance slice.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH`
  Status: `done`
  Goal: `Refresh the import-tree note after generated-child second-awaitany R14 work.`
  Children: `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.1`
  Status: `done`
  Goal: `Update the saved import-tree note and live docs from the current static trace.`
  Acceptance: `The saved topology counts and selected line-count measurements match current source; the slice remains documentation-only.`
  Verification: `import-closure recount; LoweringIR/bin line-count recount; stale-value grep; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1332-isf-atl-doc-status-audit.t; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.1` | `done` | Refreshed the saved import-tree note after the generated-child second-awaitany slice. |

## Decisions

- `2026-05-26`: Treat the post-R14 generated-child second-awaitany
  `LoweringIR.pm` line-count drift as documentation-only bootstrap
  maintenance.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.1` | `perl -Iperl -MModule::ScanDeps=scan_deps ... bin/fsmgen`; `wc -l perl/FSM/Scheduler/ISF/LoweringIR.pm bin/fsmgen`; `rg -n '11137|repeat-body child-activation slices' docs/BIN_FSMGEN_IMPORT_TREE.md`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1332-isf-atl-doc-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; import closure `total=196`, `pm=195`; `LoweringIR.pm=11141`; stale grep clean; focused docs `Files=2, Tests=403` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.1: refresh import-tree count after generated-child awaitany` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created active bootstrap maintenance task tree after the live
  bootstrap measurement found `docs/BIN_FSMGEN_IMPORT_TREE.md` still
  recording `LoweringIR.pm` at `11137` lines while the current source is
  `11141` lines.
- `2026-05-26`: Completed the selected leaf; refreshed the saved import-tree
  note to `LoweringIR.pm=11141` while preserving the unchanged `total=196`
  and `pm=195` closure counts.
