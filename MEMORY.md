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
- latest_commit: `TRACE-SEVERITY-NEVER-GATED.1` (this commit) — ungated severity channel `fsm_warn`/`fsm_error`/`fsm_fatal` in `FSM::Debug` (always → STDERR, regardless of `$DEBUG_LEVEL`; mirror to trace file); decision `0010`. `git log -1` for the hash.
- active_work_unit: `TRACE-SEVERITY-NEVER-GATED` (`.1` done) — user priority: no warning/error/fatal may be masked by trace level (decision `0010`). next: `.2` reroute the 36 severity-bearing gated `fsm_debug(..., N)` calls (18 files) onto the ungated emitters; `.3` sweep other masking patterns; `.4` guard test. Simple rule: ANY message conveying severity (warn/error/fatal/fail/cannot/invalid/missing/…) displays regardless of level — no "is it really a warning" debate.
- queued: `ISF-TRIGGER-ANCHOR.5` **Ref** trigger — user chose **both** `(point NAME)` body marker AND `(on … :as NAME)`; `(at NAME)` → `(state_active <state>)` (both bind to state_active of the named state; module-wide bindings + late resolution; substrate in FSMGenFull ExpressionBuilder). Then `.6c` neutralize residual "contract" wording. `(contract …)` already removed (`.6`).
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
