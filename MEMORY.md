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
- latest_commit: `ISF-TRIGGER-ANCHOR.5b` (this commit) — **Ref complete**: activation label `(on SIGNAL as NAME)` (bare `as`) binding NAME → entry state, sibling of `.5a`'s `(point NAME)`; both feed `(at NAME)` → `(state_active <state>)`, shared name space; `t/1416` (9 subtests); `--verify-hdl` clean. `git log -1` for the hash.
- active_work_unit: `ISF-TRIGGER-ANCHOR` (`.1`–`.6` + `.5a`/`.5b` done — **all three trigger forms event/inline/ref ship**, `(contract …)` removed). Remaining tail: `.6c` neutralize residual internal "contract" wording (rename `_temporal_contract_within_cycles`; ISF_SPEC/downstream lowering/report-schema prose for the now-empty `temporal_contracts[]` field). Decisions `0008`–`0011` shipped this session; `TRACE-SEVERITY-NEVER-GATED` + `DOCS-RELATIVE-PATHS` done.
- queued: `ISF-TRIGGER-ANCHOR.5b` **activation label** `(on SIGNAL as NAME)` (bare `as`, NOT `:as` — user) binding NAME → entry state, sibling of `.5a`'s `(point NAME)`. `.5a` (point + `(at NAME)` → `(state_active <state>)`, module-wide, fail-closed) is DONE this commit (`t/1416`). Then `.6c` neutralize residual "contract" wording. `(contract …)` already removed (`.6`).
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
