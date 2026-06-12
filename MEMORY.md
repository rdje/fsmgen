# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.17: audit AXI ID response readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.18` pending; next action is to implement additive concrete transaction ID request/response assertions before any auto-ID allocation, ID release, response demux, ordering, burst, queued-policy, alias, full-manager, or VHDL behavior changes.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.17`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.16`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.15`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.14`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.13`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.12`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.11`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.10`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.9`. Older completed slices are in the task tree and git history.
- in_flight_uncommitted: none; unrelated untracked `fx/` intentionally left alone.
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
