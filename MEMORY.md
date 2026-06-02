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
- latest_commit: `ISF-TRIGGER-ANCHOR.6c` (this commit) — neutralized user-facing "contract" wording: renamed the shared within-resolver → `_resolve_monitor_window_cycles` + reworded its diagnostics to "monitor window …"; reframed the downstream-spec stale `(contract …)` block to `(assert (monitor …))`. Kept the deeply-wired internal kind/role names (`temporal_contract_monitor`, `kind=>'contract'`) — golden-checked, accurate. **ISF-TRIGGER-ANCHOR fully complete.** `git log -1` for the hash.
- active_work_unit: none active. **ISF-TRIGGER-ANCHOR done** (`.1`–`.6` + `.5a/.5b/.5c` + `.6c`): event/inline/ref triggers + synthesizable monitor + window parity + Ref (signal-anchored, ISF↔FSM boundary respected) + `(contract …)` removed; thorough synced mdBook docs (7 runnable examples). This session also shipped decisions `0008`–`0011`, `TRACE-SEVERITY-NEVER-GATED`, `DOCS-RELATIVE-PATHS`, artifact cleanup. Next: pick a frontier item per `0002`/`0003`.
- queued: `ISF-TRIGGER-ANCHOR.5b` **activation label** `(on SIGNAL as NAME)` (bare `as`, NOT `:as` — user) binding NAME → entry state, sibling of `.5a`'s `(point NAME)`. `.5a` (point + `(at NAME)` → `(state_active <state>)`, module-wide, fail-closed) is DONE this commit (`t/1416`). Then `.6c` neutralize residual "contract" wording. `(contract …)` already removed (`.6`).
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
