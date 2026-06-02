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
- latest_commit: `ISF-TRIGGER-ANCHOR.6` (this commit) — **`(contract …)` REMOVED** (decision `0008`'s headline). Clause no longer recognized; `(assert (monitor (within S N)))` is the lossless replacement (shared `_build_eventually_monitor` engine). Removed clause/parser/lowering + contract-window param-gate + rule-override checks; deleted 9 contract tests, updated 6 mixed + provenance/CI-tier; reframed book + ISF_SPEC/downstream clause docs; fixed a latent `.3` report-grouping bug (monitor arm states under `undef`). `git log -1` for the hash.
- active_work_unit: `ISF-TRIGGER-ANCHOR` (`.1`–`.4`,`.6` done). All-but-Ref shipped; `(contract …)` gone. `temporal_contracts` report field retained as always-`[]` (schema-v1 stability).
- next_action: `ISF-TRIGGER-ANCHOR.5` — **Ref (named)** trigger `(on … :as NAME)` + `(at NAME)` → `(state_active <state>)` (substrate in FSMGenFull ExpressionBuilder; has an open semantic fork — what a named `(on …)` point's "active" means). Then `.6c` neutralize residual "contract" wording (rename `_temporal_contract_within_cycles`; ISF_SPEC/downstream lowering/report-schema prose).
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
