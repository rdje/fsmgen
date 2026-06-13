# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.56: select AXI burst read-data contract`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.57` pending; next action is to select the public AXI burst read-data contract after generated `RLAST` completion/report alignment.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.56`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.55`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.54`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.53`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.52`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.51`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.50`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.49`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.48`. Older completed slices are in the task tree and git history.
- in_flight_uncommitted: none after this commit; unrelated untracked `fx/` intentionally left alone.
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
