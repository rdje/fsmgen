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
- latest_commit: `TRACE-SEVERITY-NEVER-GATED.2` (this commit) — triaged the 34 severity-bearing gated trace calls: genuine warnings/errors → ungated `fsm_warn`/`fsm_error`; 6 high/moderate-frequency routine notes kept gated + reworded (a literal "surface every severity word" pass flooded ~3755×/run from 2 notes). Full suite PASS. `git log -1` for the hash.
- active_work_unit: `TRACE-SEVERITY-NEVER-GATED` (`.1`,`.2` done). **Refined rule (decision `0010`):** notes are gatable even when worded with "fail"/"error"; only GENUINE problems ungate. Heuristic: fires repeatedly during normal passing runs ⇒ note (gate); fires only on a genuine edge/error path ⇒ warning (ungate). Remaining: `.3` sweep `warn`/`print STDERR` gated by level (initial sweep found none); `.4` optional guard test.
- queued: `ISF-TRIGGER-ANCHOR.5` **Ref** trigger — user chose **both** `(point NAME)` body marker AND `(on … :as NAME)`; `(at NAME)` → `(state_active <state>)` (both bind to state_active of the named state; module-wide bindings + late resolution; substrate in FSMGenFull ExpressionBuilder). Then `.6c` neutralize residual "contract" wording. `(contract …)` already removed (`.6`).
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
