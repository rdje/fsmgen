# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after .178 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.178: select burst-last depth-3 audit`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.179` audit generated read burst-last scalar last-beat read-data over multiple/mixed depth-3 concrete same-ID queue-head groups; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.178` selected `.179` after reading `.177` behavior, `.176` audit, current reports/support accounting, roadmap/book/task-tree/Memory/Knowledge Map, code coverage gates, and live probes. `.177` single-beat read-data generates over depth `3,3` and `3,2` queue sets; adjacent read burst-last multiple/mixed depth-3 samples remain response-demux-only; temporary last-beat read-data candidates over those queue sets fail closed at the current last-beat coverage gate. No behavior-bearing files changed.
- in_flight_uncommitted: none after `.178` commit. `.179` is an audit only: decide whether generated read burst-last scalar last-beat read-data over multiple/mixed depth-3 queue-head groups can be implemented directly or needs a smaller prerequisite before any parser, generator, sample, support-accounting, validation, test, HDL, or generated-artifact behavior changes. Ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
