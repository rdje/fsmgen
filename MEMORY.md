# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after audit commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.145: audit single-beat multi-group read-data`.
- active_work_unit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` pending first SV/UVM verification output contract selector; `IAL2-FEATURE-COMPLETENESS-FRONTIER.146` implement generated read-data over read single-beat multi-group queue-head response-demux and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.145` selected `.146`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.144` selected `.145`; `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1`; `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2`; `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1`; older completed slices are in task trees and git history.
- in_flight_uncommitted: none after audit commit; `.145` changed docs/task-tree/Knowledge Map/Memory only. A `/tmp` future-shape probe failed closed at the exact-one-depth-2-group single-beat queue-head read-data gate, while schedule/check/semantic probes passed for `.143`, one-group single-beat queue-head read-data, and multi-group burst-last multi-beat read-data. Next IAL2 action is `.146`, implementation of that bounded single-beat multi-group read-data behavior; ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
