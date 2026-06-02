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
- latest_commit: `ISF-TRIGGER-ANCHOR.2` (this commit) — **Event trigger** `(after SIG CONS)` → `$rose(SIG) |-> (CONS)` end-to-end (parse/render/keep-alive/partition); `t/1413`; `--verify-hdl` + `verilator --binary --assert` proven. `git log -1` for the hash.
- active_work_unit: `ISF-TRIGGER-ANCHOR` (`.1`,`.2` done). One engine `TRIGGER |-> (bounded-eventually) CONSEQUENT`; three trigger forms (event done; inline/ref pending) + monitor output-mode; `(contract …)` dissolves into it and is removed last (no capability gap).
- next_action: `ISF-TRIGGER-ANCHOR.3` — **synthesizable-monitor output-mode** for `(within …)` consequents (reuse/generalize `_contract_monitor_signals` arm/age/fail so bounded-eventually is verilator-simulable, not only formal). Then `.4` Inline positioned, `.5` Ref named, `.6` remove `(contract …)`. Build order dependency-driven (decision `0009`).
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
