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
- latest_commit: `BACKEND-API-VALIDATION-FRONTIER.73` (this commit) — selected bounded external-RTL scalar integer VHDL generic maps. `git log -1` for the hash.
- active_work_unit: `BACKEND-API-VALIDATION-FRONTIER.73.1` active frontier — implement only external-RTL C3 scalar integer VHDL generic-map lowering.
- recently_done: `BACKEND-API-VALIDATION-FRONTIER.73`; `BACKEND-API-VALIDATION-FRONTIER.72.1`; `BACKEND-API-VALIDATION-FRONTIER.72`; `BACKEND-API-VALIDATION-FRONTIER.71.1`; `BACKEND-API-VALIDATION-FRONTIER.71`; `BACKEND-API-VALIDATION-FRONTIER.70.1`; `BACKEND-API-VALIDATION-FRONTIER.70`; `BACKEND-API-VALIDATION-FRONTIER.69.1`; `BACKEND-API-VALIDATION-FRONTIER.69`; `BACKEND-API-VALIDATION-FRONTIER.68.1`; `BACKEND-API-VALIDATION-FRONTIER.68`; `BACKEND-API-VALIDATION-FRONTIER.67.1`; `BACKEND-API-VALIDATION-FRONTIER.67`; `BACKEND-API-VALIDATION-FRONTIER.66.1`.
- in_flight_uncommitted: none expected after this `.73` selection commit; unrelated untracked `fx/` intentionally left alone.
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
