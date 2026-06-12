# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1` — recorded the first AXI ID/order/concurrency source-anchor evidence inventory for future IAL2 manager rule-engine work.
- active_work_unit: none; no active or proposed PNT-eligible task tree remains after `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1`.
- recently_done: `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1`; `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE.1`; `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.1`; `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.1`; `AXI-VALID-READY-INTENT-PROBE.2`; `.1`. Older completed slices are in the task tree and git history.
- in_flight_uncommitted: none for owned work; unrelated untracked `fx/` intentionally left alone.
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
