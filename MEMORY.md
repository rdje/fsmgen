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
- latest_commit: `ISF-TRIGGER-ANCHOR.3` (this commit) — **synthesizable-monitor output-mode + Inline trigger** `(assert (monitor (within S N)))` → arm-state + `arm`/`pending`/`age`/`fail` monitor DT (extracted `_build_eventually_monitor`, shared with `contract`) asserting `(! fail)`, verilator-simulable; `t/1413` (9 subtests); `--verify-hdl` + `verilator --binary --assert` proven; `git log -1` for the hash.
- active_work_unit: `ISF-TRIGGER-ANCHOR` (`.1`,`.2`,`.3` done; `.4` Inline folded into `.3`). Event + Inline/monitor triggers ship; `contract` now lowers byte-identically through the shared monitor engine. Remaining: Ref `(at NAME)`, then remove `(contract …)` (now redundant).
- next_action: `ISF-TRIGGER-ANCHOR.5` — **Ref (named)** trigger: `(on … :as NAME)` binding + `(at NAME)` trigger leaf. Then `.6` remove `(contract …)` entirely (clause + `_ir_contract` + `_parse_bounded_eventual_contract_clause` + tests/docs), retargeting onto the shared `_build_eventually_monitor`. Hard-to-reverse — user-authorized (`0008`).
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
