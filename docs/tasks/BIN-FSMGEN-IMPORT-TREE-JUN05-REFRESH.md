# BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH: Refresh import-tree measurements after June R14 work

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH`
- Status: `active`
- Roadmap lane: bootstrap architecture maintenance
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Refresh the live `bin/fsmgen` import-tree architecture note after the session
bootstrap audit found that the project-owned import topology is still stable, but
several recorded ISF line-count measurements are stale after recent R14 work.

## Ground Truth

- The live static dependency trace from `bin/fsmgen` still reaches `196` project
  files total and `195` `.pm` packages.
- Reachable package-family counts are unchanged: `Support=65`,
  `Composition=36`, `HDL=32`, `Package=14`, `Synthesis=10`,
  `Adapter=8`, `IR=7`, `Pipeline=5`, `Scheduler=5`, `Backend=3`,
  `Extension=3`, plus the same singleton support surfaces.
- Current measured line counts that drifted from
  `docs/BIN_FSMGEN_IMPORT_TREE.md`: `perl/FSM/Adapter/ISF/Parser.pm=9468`,
  `perl/FSM/Scheduler/ISF.pm=591`,
  `perl/FSM/Scheduler/ISF/LoweringIR.pm=12124`,
  `perl/FSM/Scheduler/ISF/Emitter/FSM.pm=547`, and
  `perl/FSM/Scheduler/ISF/Emitter/JSON.pm=1053`.
- `bin/fsmgen` remains `1175` lines.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  manifests, tests, or runtime behavior.
- Do not rewrite the qualitative architecture note unless the live topology
  proves a package-ownership change. This refresh is measurement-only.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the current measured line counts for
  the stale ISF files at both relevant measurement tables.
- Topology summary remains `196` project files and `195` `.pm` packages.
- The owning task tree records validation and completion evidence.
- Focused documentation/memory gates pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH`
  Status: `active`
  Goal: `Refresh stale live import-tree measurements after the June 5 bootstrap audit.`
  Children: `.1` (select), `.2` (refresh)

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH.1`
  Status: `done`
  Goal: `Select the measurement-only refresh and record the live bootstrap audit facts.`
  Acceptance: `Task tree and TASK_TREE.md index row exist before editing the import-tree architecture note.`
  Verification: `scripts/check_memory_architecture.sh PASS; git diff --check PASS`
  Commit: `pending`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH.2`
  Status: `pending`
  Goal: `Update docs/BIN_FSMGEN_IMPORT_TREE.md with the current stale ISF line counts and record verification.`
  Acceptance: `The import-tree note records Parser.pm=9468, Scheduler/ISF.pm=591, LoweringIR.pm=12124, Emitter/FSM.pm=547, Emitter/JSON.pm=1053, and unchanged topology.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection and ownership created before the architecture-note edit. |
| 2 | `.2` | `pending` | Refresh the stale measured line counts found by the bootstrap audit. |

## Decisions

- `2026-06-05`: Treat the stale import-tree measurements as a bootstrap
  architecture-maintenance slice, not as an R14 behavior slice. The topology did
  not move, so a measurement-only refresh is sufficient.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-05` | `.1` | `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `pending` | `pending` |
| `.2` | `pending` | `pending` |

## Changelog

- `2026-06-05`: Created after the session bootstrap audit remeasured the
  project-owned import topology and found stable closure counts but stale ISF
  line-count measurements in `docs/BIN_FSMGEN_IMPORT_TREE.md`.
