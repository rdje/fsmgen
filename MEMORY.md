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
- latest_commit: `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1` (this commit) — audited mdBook/codebase/user-facing sync: mdBook/public-contract/book-example/feature/backlog/path/memory/Knowledge Map/docs-contract/ISF gates passed; quick suite reproducibly fails stale `t/84` plan-net count assertion against documented `shared_dp_unused_*` sink nets.
- active_work_unit: none — audit complete; no active or proposed task-tree remains. Future repair of the `t/84` quick-suite lock failure needs a new or reactivated exact owner before source/config/test/doc changes.
- recently_done: `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.1`; `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.1`; `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1`; `ARCHITECTURE-DEBT-FRONTIER.3`; `ARCHITECTURE-DEBT-FRONTIER.2.1`; `ARCHITECTURE-DEBT-FRONTIER.2`; `ARCHITECTURE-DEBT-FRONTIER.1`; `BACKEND-API-VALIDATION-FRONTIER.132`; `BACKEND-API-VALIDATION-FRONTIER.131.1`; `BACKEND-API-VALIDATION-FRONTIER.131`; `BACKEND-API-VALIDATION-FRONTIER.130.1`; `BACKEND-API-VALIDATION-FRONTIER.130`.
- in_flight_uncommitted: none expected after this audit commit; unrelated untracked `fx/` intentionally left alone.
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
