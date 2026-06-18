# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after IAL2-FEATURE-COMPLETENESS-FRONTIER.185 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.185: audit depth-3 runtime validation readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.186` is the next IAL2 direct implementation of generated runtime beat-count/RLAST validation over multiple/mixed depth-3 queue-head scalar last-beat read-data; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.185` selected `.186` after reading `.184` selector, `.183` report-only raw-ARLEN behavior, `.182` audit, `.180` no-burst behavior, one-group depth-3 and multi-group depth-2 runtime precedents, code/report helpers, support accounting, roadmap, mdBook, downstream spec, task tree, Memory, and Knowledge Map. Temporary runtime-assertion variants fail closed only at the local coverage gate. No parser/generator/sample/support-accounting/validation/generated-artifact/test/HDL behavior changed.
- in_flight_uncommitted: none after the `IAL2-FEATURE-COMPLETENESS-FRONTIER.185` audit/docs commit. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
