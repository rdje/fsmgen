# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

## Current state (OVERWRITE this block each update — do not append)
- latest_commit: `BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH.2` (this commit) — refreshed `docs/BIN_FSMGEN_IMPORT_TREE.md` after the 2026-06-05 bootstrap audit: topology still `196` total / `195` `.pm`; stale ISF line counts updated (`Parser.pm=9468`, `Scheduler/ISF.pm=591`, `LoweringIR.pm=12124`, `Emitter/FSM.pm=547`, `Emitter/JSON.pm=1053`). `git log -1` for the hash.
- active_work_unit: none active. `BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH` `.1`–`.2` done; `KNOWLEDGE-MAP-ADOPT` `.1`–`.2` done (tree left `active` only for optional later folding of high-traffic decision records into the map). Next: pick a frontier item per `0002`/`0003`, or seed/fold more KM cards lazily.
- recently_done: `BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH`; `ISF-LOOP-EARLY-EXIT.4` (`loop_early_exits[]` schedule-report metadata for exit-when/continue-when); `ISF-TRIGGER-ANCHOR` (complete, `.1`–`.6c`); decisions `0008`–`0011`; `TRACE-SEVERITY-NEVER-GATED`; `DOCS-RELATIVE-PATHS`.
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Before re-deriving a logged fact, consult `KNOWLEDGE_MAP.md` (derived question→fact
  index; cards under `docs/knowledge/`, bundle `knowledge-map/`). Write a fact card
  whenever you establish a durable fact or catch archaeology — lazily, never a sweep
  (`docs/tasks/KNOWLEDGE-MAP-ADOPT.md`).
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
