# BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH: Static-Zero Repeat Import-Tree Measurement Refresh

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Execute the `SESSION_BOOTSTRAP.md` import-tree audit after the latest R14
static-zero repeat pruning work by comparing the live `bin/fsmgen`
project-owned `FSM::...` import closure and measured hotspot line counts
against `docs/BIN_FSMGEN_IMPORT_TREE.md`, then refresh the saved architecture
note where the measured snapshot is stale.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  tests, or runtime behavior.
- Do not broaden the roadmap lane or choose an R14 behavior-bearing feature
  inside this bootstrap maintenance leaf.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the current measured line count for
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` after the static-zero repeat pruning
  follow-up slices.
- The saved import-tree topology remains honest: project-owned closure count,
  `.pm` count, and family counts are either confirmed unchanged or updated.
- README, task tree, roadmap, live docs, change history, and development notes
  are synchronized for this bootstrap refresh.
- Validation confirms the import-closure counts and stale measured value were
  checked, and `git diff --check` passes.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH`
  Status: `done`
  Goal: `Refresh the bin/fsmgen bootstrap import-tree measurement after static-zero repeat pruning.`
  Children: `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.1`
  Status: `done`
  Goal: `Update stale LoweringIR measured line counts after rebuilding the live import closure.`
  Acceptance: `Import closure counts are confirmed, the stale LoweringIR count is refreshed, docs/live status are synchronized, and commit workflow is complete.`
  Verification: `import-closure recount total=196 pm=195; stale measured-value grep; git diff --check`
  Commit: `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.1: refresh static-zero import-tree count`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.1` refreshed the stale LoweringIR measurement after confirming topology is unchanged. |

## Decisions

- `2026-05-25`: Treat this as a documentation-only bootstrap architecture
  maintenance slice. The live import topology still measures `196` project
  files and `195` `.pm` packages, but the recorded `LoweringIR.pm` line count
  was stale after the latest R14 static-zero repeat pruning work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.1` | import-closure recount; stale measured-value grep; `git diff --check` | passed; topology remains `196` project files and `195` `.pm` packages |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.1: refresh static-zero import-tree count` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created and closed the bootstrap architecture maintenance
  tree after rebuilding the live `bin/fsmgen` import closure and refreshing
  the stale `LoweringIR.pm` measured line count.
