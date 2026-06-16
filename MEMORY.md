# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after commit` — `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1: select phase response`.
- active_work_unit: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2` pending tracked response edit; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`, `IAL2-FEATURE-COMPLETENESS-FRONTIER.144`, and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1`; `ISF-VERIFICATION-OBSERVATION-METADATA.1`; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2`; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1`; `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.1`; `FX-UNTRACKED-LEGACY-REMOVAL.1`; `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.1`; `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1`; older completed slices are in task trees and git history.
- in_flight_uncommitted: none after this commit; `.2` must edit `docs/SPECFORGE_FEEDBACK_RESPONSE.md` only after this owner exists, answering the SPECFORGE 2026-06-16 phase-membership/value/order request: no fabricated drive values/order, future checked ISF phase-group metadata is the likely source feature, `.isf` remains SPECFORGE's synthesizable target, and `.val` is only a possible future verification artifact/layer; ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
