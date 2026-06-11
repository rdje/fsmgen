# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `AXI-SPEC-LOCAL-REFERENCE-IMPORT.1` (`fd8232fe`) — tracked the provided AXI spec PDF as a repo-local reference artifact.
- active_work_unit: `AXI-VALID-READY-INTENT-PROBE.1` (selection slice) — selected the bounded AXI valid/ready source-anchor probe; next frontier is `.2`.
- recently_done: `AXI-SPEC-LOCAL-REFERENCE-IMPORT.1`; `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.2`; `.1`; `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.2`; `.1`. Older completed slices are in the task tree and git history.
- in_flight_uncommitted: selection-only task-tree/index/README/mdBook/MEMORY edits for `AXI-VALID-READY-INTENT-PROBE.1`; unrelated untracked `fx/` intentionally left alone.
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
