# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.5` (this commit) — refined private outstanding-child lifetime proofs and violations; public lowering/diagnostics unchanged.
- active_work_unit: `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.6` — model binding handoffs, domain ownership, and CDC activation requirements as explicit effects.
- recently_done: `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.5`; `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.4`; `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.3`; `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.2.1`; `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.1`; `ISF-SCHEDULING-BACKLOG-FRONTIER.3.1`; `ISF-SCHEDULING-BACKLOG-FRONTIER.2.1`; `ISF-SCHEDULING-BACKLOG-FRONTIER.1`; `CI-SHARED-DP-SURFACE-REPAIR.1`; `COMPOSITION-T84-NET-COUNT-REPAIR.1`; `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1`; `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1`.
- in_flight_uncommitted: none expected after the `.5` commit; unrelated untracked `fx/` intentionally left alone.
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
