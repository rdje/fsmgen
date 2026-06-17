# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after .163 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.163: select depth-3 runtime audit`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.164` audit generated runtime beat-count/`RLAST` validation over the `.162` read burst-last depth-3 queue-head report-only raw-`ARLEN` burst-length shape; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.163` selected `.164`, runtime-validation readiness audit, after live probes showed `.162` still carries `generated_beat_count_validation` residue and a temporary depth-3 `runtime-assertion` candidate fails closed only at the local queue-head coverage diagnostic.
- in_flight_uncommitted: none after `.163` commit. `.164` is audit-only: read `.163` selector, `.162` behavior, depth-2/multi-group runtime-validation behavior, current coverage gates, beat-count helpers, tests, support accounting, roadmap, mdBook, Memory, and Knowledge Map before choosing an implementation owner or prerequisite. Do not enable runtime-validation, multi-beat over read burst-last depth-3, write depth-3, multiple/mixed depth-3 groups, mixed auto-ID, group-local enqueue widening, direct backend, or VHDL without a new owned leaf. Ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
