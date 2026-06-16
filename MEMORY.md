# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after commit` — `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2: audit IAL1 verification source`.
- active_work_unit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` pending; `IAL2-FEATURE-COMPLETENESS-FRONTIER.144` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2`; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1`; `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.1`; `FX-UNTRACKED-LEGACY-REMOVAL.1`; `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.1`; `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1`; `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.1`; `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.143`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.142`. Older completed slices are in the task tree and git history.
- in_flight_uncommitted: none after this commit; `.3` is the next IAL1 verification-code generation selector, centered on an IAL1 verification observation/source-feature contract before SV/UVM, VHDL-oriented, direct IAL2, or public artifact/report verification-code generation behavior; `.144` remains the next IAL2 selector/audit owner and `.2.2` remains the backend-language-neutral contract/infrastructure readiness audit owner; ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
