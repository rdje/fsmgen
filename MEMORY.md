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
- latest_commit: `BACKEND-API-VALIDATION-FRONTIER.15` (this commit) — selected structural-RTL `instances[]` shallow entry schemas as the next normalized semantic export hardening edge. `git log -1` for the hash.
- active_work_unit: `BACKEND-API-VALIDATION-FRONTIER.15.1` active frontier — publish bounded structural-RTL `instances[]` shallow entry key families without freezing nested instance arrays.
- recently_done: `BACKEND-API-VALIDATION-FRONTIER.15`; `BACKEND-API-VALIDATION-FRONTIER.14.1`; `BACKEND-API-VALIDATION-FRONTIER.14`; `BACKEND-API-VALIDATION-FRONTIER.13.1`; `BACKEND-API-VALIDATION-FRONTIER.13`; `BACKEND-API-VALIDATION-FRONTIER.12.1`; `BACKEND-API-VALIDATION-FRONTIER.12`; `BACKEND-API-VALIDATION-FRONTIER.11.1`; `BACKEND-API-VALIDATION-FRONTIER.11`; `BACKEND-API-VALIDATION-FRONTIER.10.1`; `BACKEND-API-VALIDATION-FRONTIER.10`; `BACKEND-API-VALIDATION-FRONTIER.9.1`; `BACKEND-API-VALIDATION-FRONTIER.9`; `BACKEND-API-VALIDATION-FRONTIER.8.1`; `BACKEND-API-VALIDATION-FRONTIER.8`.
- in_flight_uncommitted: none expected after this commit; unrelated untracked `fx/` intentionally left alone.
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
