# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after .176 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.176: audit depth-3 read-data readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.177` implement generated read single-beat scalar read-data over multiple or mixed depth-3 concrete same-ID queue-head groups; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.176` selected `.177` as direct bounded implementation of read single-beat scalar `RDATA`/`RRESP` over generated multiple/mixed depth-3 queue-head groups. Temporary two-depth-3 and mixed depth-3/depth-2 read-data probes fail closed at the current single-beat coverage gate; no behavior-bearing files changed in `.176`.
- in_flight_uncommitted: none after `.176` commit. `.177` may change behavior only within its owned boundary: read family, response-demux completion source, capture-scope single-beat, scalar read-data outputs, generated read single-beat queue-head demux, selected groups of computed depth 2 or 3 with at least one depth-3 group. Do not enable burst-last read-data, burst-length, runtime-validation, multi-beat, write-family read-data, mixed auto-ID, group-local enqueue widening, packed outputs, alternate burst assembly, direct backend, verification-output generation, VHDL, or backend-language variants. Ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
