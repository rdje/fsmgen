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
- latest_commit: `ISF-REMAINING-BROAD-FRONTIER.2.1` (this commit) — shipped bounded rule-level qualified ATL trigger parent handoffs. `git log -1` for the hash.
- active_work_unit: `ISF-REMAINING-BROAD-FRONTIER.3` pending frontier — decide whether IAL2 remains horizon exploration or has one exact executable design slice before any IAL2 behavior change.
- recently_done: `ISF-REMAINING-BROAD-FRONTIER.2.1`; `ISF-REMAINING-BROAD-FRONTIER.2`; `ISF-REMAINING-BROAD-FRONTIER.7.1`; `ISF-REMAINING-BROAD-FRONTIER.1`; `ISF-COUNTED-REPEAT-TERMINATION.4`; `ISF-PROPERTY-SAMPLED-VALUE.3`; `ISF-LOOP-EARLY-EXIT.5`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.10`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.9`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.8`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.7`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.6`; `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.5`; `KNOWLEDGE-MAP-ADOPT.3`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13`; `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12`.
- in_flight_uncommitted: none (working tree clean except unrelated untracked `fx/`, intentionally left alone).
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
