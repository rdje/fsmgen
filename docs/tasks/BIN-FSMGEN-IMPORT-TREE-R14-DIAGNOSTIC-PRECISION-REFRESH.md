# BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH: Refresh Import-Tree LoweringIR Count After Diagnostic-Precision Slices

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Refresh the recorded `perl/FSM/Scheduler/ISF/LoweringIR.pm` line count
in `docs/BIN_FSMGEN_IMPORT_TREE.md` after the four R14 diagnostic-
precision slices added cumulative validator code:

1. `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.2` (helper +
   three gate sites)
2. `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.2`
   (four sub-axis preserves helpers + four-way gate split at two
   activation-override sites)
3. `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`
   (helper + two gate sites)
4. `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`
   (helper + two gate sites)

The recorded count is `11144`; the current measurement is `11309`
(`+165`). Topology (total reachable project files, `.pm` package
count, and `bin/fsmgen` line count) is unchanged because no new
module file was added.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL,
  public API, manifests, tests, or runtime behavior.
- Do not refresh historical task-tree records that name the prior
  `11144` measurement — those are dated snapshots, not live values.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records
  `perl/FSM/Scheduler/ISF/LoweringIR.pm: 11309` at both the
  per-file listing and the largest-reachable-files summary.
- Topology summary (`total reachable project files: 196`,
  `reachable .pm packages: 195`, `bin/fsmgen: 1175`) unchanged.
- Live docs (MEMORY.md, ROADMAP_STATUS.md, CHANGES.md,
  DEVELOPMENT_NOTES.md, LIVE_ACHIEVEMENT_STATUS.md, README.md,
  docs/TASK_TREE.md) reflect the refresh.
- mdBook builds clean; `git diff --check` clean.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH`
  Status: `pending`
  Goal: `Refresh import-tree LoweringIR.pm line count after diagnostic-precision slices.`
  Children:
    `BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.1`
  Status: `pending`
  Goal: `Update both occurrences of the LoweringIR.pm line count from 11144 to 11309 and synchronize live docs.`
  Acceptance: `Both occurrences in BIN_FSMGEN_IMPORT_TREE.md updated; topology unchanged; live docs synchronized.`
  Verification: `wc -l perl/FSM/Scheduler/ISF/LoweringIR.pm bin/fsmgen; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Refresh shipped. Recorded `LoweringIR.pm` line count updated from `11144` to `11309`; topology unchanged. |

## Decisions

- `2026-05-27`: Consolidate the four diagnostic-precision slices'
  bootstrap-refresh into one task tree rather than four. The slices
  shipped consecutively and the only architectural drift is the
  LoweringIR.pm line count; topology is unchanged. One refresh
  commit is sufficient.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.1` | `wc -l perl/FSM/Scheduler/ISF/LoweringIR.pm bin/fsmgen`; `mdbook build docs/book`; `git diff --check` | `PASS`; `LoweringIR.pm=11309`, `bin/fsmgen=1175`; stale `11144` grep clean against the live import-tree note; mdBook built clean; whitespace clean. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.1: refresh import-tree count after diagnostic-precision slices` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created single-leaf documentation-only task tree to
  refresh the `bin/fsmgen` import-tree note's recorded
  `LoweringIR.pm` line count after the four R14 diagnostic-precision
  slices added cumulative validator code. Topology unchanged; only
  the recorded line count for the LoweringIR hotspot moves from
  `11144` to `11309`.
