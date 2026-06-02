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
- latest_commit: `ISF-PROPERTY-IMPLICATION.2` (this commit) — `(assert (=> A B))` → SVA `(A) |-> (B)` inside the clocked property (overlapping implication); verified fires-on-violation; step 2 of decision `0008`; `git log -1` for the hash.
- active_work_unit: `ISF-PROPERTY-IMPLICATION` → frontier leaf: `.3` (next; `.1`–`.2` done) — temporal property grammar.
- next_action: implement `ISF-PROPERTY-IMPLICATION.3` — next-cycle implication `(=> A (next B))` → `A |=> B`, and `(within S N)` consequent → `##[1:N] S` (literal `N>=1`), extending `parse_check_property` + `_render_check_condition_sv`. Then a later tree: the transaction-point trigger anchor + REMOVE `(contract …)` entirely (user request, decision `0008`) once the bounded-eventually intent is expressible.
- recently_done: `MEMORY-ARCHITECTURE-ADOPTION` (`.1`–`.5`, done); `ISF-ASSERT.1`/`.2`; the theme-3 ISF data/bit/field/arithmetic construct surface (see `docs/decisions/0002`).
- in_flight_uncommitted: none (working tree clean except untracked `fx/`, intentionally left alone).
- blockers: none.

## Notes
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
