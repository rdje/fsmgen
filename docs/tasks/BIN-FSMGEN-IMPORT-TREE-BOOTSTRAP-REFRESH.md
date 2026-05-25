# BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH: Bootstrap Import-Tree Measurement Refresh

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Execute the `SESSION_BOOTSTRAP.md` import-tree audit by comparing the live
`bin/fsmgen` project-owned `FSM::...` import closure and measured hotspot
line counts against `docs/BIN_FSMGEN_IMPORT_TREE.md`, then refresh the saved
architecture note where it is stale.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  tests, or runtime behavior.
- Do not broaden the roadmap lane or pick an implementation feature inside
  this documentation-maintenance leaf.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the current measured line counts
  for the reachable hotspot files checked during bootstrap.
- The saved import-tree topology remains honest: project-owned closure count,
  `.pm` count, and family counts are either confirmed unchanged or updated.
- README, task tree, roadmap, live docs, change history, and development notes
  are synchronized for this bootstrap refresh.
- Validation confirms the import-closure counts and stale measured values were
  checked, and `git diff --check` passes.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH`
  Status: `done`
  Goal: `Refresh the bin/fsmgen bootstrap import-tree architecture note.`
  Children: `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.1`
  Status: `done`
  Goal: `Update stale measured line counts after rebuilding the live import closure.`
  Acceptance: `Import closure counts are confirmed, stale hotspot line counts are refreshed, docs/live status are synchronized, and commit workflow is complete.`
  Verification: `import-closure recount total=196 pm=195; stale measured-value grep; git diff --check`
  Commit: `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.1: refresh import-tree counts`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.1` refreshed stale measured import-tree line counts after confirming topology is unchanged. |

## Decisions

- `2026-05-25`: Treat this as a documentation-only bootstrap architecture
  maintenance slice. The live import topology still measures `196` project
  files and `195` `.pm` packages, but several recorded line counts are stale
  after recent R14 scheduler/parser work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.1` | import-closure recount; stale measured-value grep; `git diff --check` | passed; topology remains `196` project files and `195` `.pm` packages |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.1: refresh import-tree counts` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created active bootstrap architecture maintenance tree after
  rebuilding the live `bin/fsmgen` import closure.
- `2026-05-25`: Refreshed stale measured line counts and closed the tree.
