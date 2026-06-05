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
- latest_commit: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.8` (this commit) — closed repeat-contained branch cross-domain `(do)` behind the missing same-domain repeat-body branch prerequisite. `git log -1` for the hash.
- active_work_unit: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.9` pending. Audit remaining deeper combinations and close the tree or create exact new owner leaves; keep mdBook synced if behavior changes.
- recently_done: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.8`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.7`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.6`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.5`; `KNOWLEDGE-MAP-ADOPT.3`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11`.
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
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
