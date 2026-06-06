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
- latest_commit: `BACKEND-API-VALIDATION-FRONTIER.33` (this commit) — selected direct VHDL scalar multiplication-chain RHS lowering for `.33.1`. `git log -1` for the hash.
- active_work_unit: `BACKEND-API-VALIDATION-FRONTIER.33.1` active frontier — implement only scalar multiplication-chain RHS lowering before broader scalar arithmetic or aggregate/composition VHDL.
- recently_done: `BACKEND-API-VALIDATION-FRONTIER.33`; `BACKEND-API-VALIDATION-FRONTIER.32.1`; `BACKEND-API-VALIDATION-FRONTIER.32`; `BACKEND-API-VALIDATION-FRONTIER.31.1`; `BACKEND-API-VALIDATION-FRONTIER.31`; `BACKEND-API-VALIDATION-FRONTIER.30.1`; `BACKEND-API-VALIDATION-FRONTIER.30`; `BACKEND-API-VALIDATION-FRONTIER.29.1`; `BACKEND-API-VALIDATION-FRONTIER.29`; `BACKEND-API-VALIDATION-FRONTIER.28.1`; `BACKEND-API-VALIDATION-FRONTIER.28`; `BACKEND-API-VALIDATION-FRONTIER.27.1`; `BACKEND-API-VALIDATION-FRONTIER.27`; `BACKEND-API-VALIDATION-FRONTIER.26.1`; `BACKEND-API-VALIDATION-FRONTIER.26`.
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
