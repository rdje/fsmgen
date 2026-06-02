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
- latest_commit: `ISF-ASSERT.2` (this commit) — the `(assert COND)` `+assert` `.fsm` carrier round-trips ISF → `.fsm` → FSMGenFull; `git log -1` for the hash.
- active_work_unit: `ISF-ASSERT` → frontier leaf: `.3` (next; `.1`–`.2` done) — `(assert COND [message])` verification intent.
- next_action: implement `ISF-ASSERT.3` — surface `$fsm_module->{attributes}{immediate_assertions}` into `module_info` (`GeneratedModuleInfoBuilder::build_from_fsm_module`), add `immediate_assertion_runtime_lines` to `GeneratedModuleEmitter` (emit `ifndef SYNTHESIS` / `always_comb` / `assert (COND) else $error("msg")` from the condition's `to_systemverilog`) wired into `augment_with_runtime_assertions`; verify with `--verify-hdl` + a `verilator --binary` pass/fail testbench.
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
