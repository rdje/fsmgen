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
- latest_commit: `e3d2eb83` — "MEMORY-ARCHITECTURE-ADOPTION.2: docs/decisions/ (layer C) + migrate durable facts to ADRs"
- active_work_unit: `MEMORY-ARCHITECTURE-ADOPTION` → frontier leaf: `.3` (in progress; demote MEMORY.md + reconcile COMMIT.md), then `.4` (enforcement kit) + `.5` (verify/close)
- next_action: finish `.3` (this commit), then `.4` — install `scripts/check_memory_architecture.sh`, `.githooks/` (+ `git config core.hooksPath .githooks`), tool-neutral bootstrap pointers, and wire the check into CI (`regression.yml`).
- also_active: `ISF-ASSERT` paused at `.2` (design done in `.1`); resume after this tree — `(assert COND)` via a thin `+assert` `.fsm` carrier.
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — not appended to; git is the audit trail (`docs/decisions/0007`).
