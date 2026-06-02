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
- latest_commit: `ISF-PROPERTY-IMPLICATION.3` (this commit) — `(next X)`/`(within X N)` → `##1`/`##[1:N]` (formal-only under `ifdef FORMAL`); completes the implication grammar (steps 1+2 of decision `0008` done); `git log -1` for the hash.
- active_work_unit: none active. Decision `0008` chain status: step 1 (concurrent) done, step 2 (implication grammar) done; **remaining = remove `(contract …)`** (user request), which needs a transaction-point trigger anchor first.
- next_action: design + build the transaction-point **trigger anchor** (so `(assert (=> <here-active> (within S N)))` can anchor to a transaction point, like `contract` does), THEN remove `(contract …)` entirely (its clause, monitor lowering, tests, docs) — decision `0008`. Or pick another frontier item per `0002`/`0003`.
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
