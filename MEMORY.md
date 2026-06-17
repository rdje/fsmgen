# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after .167 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.167: audit depth-3 multi-beat readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.168` implement generated multi-beat output-bank behavior over exactly one read burst-last depth-3 queue-head runtime-validation group; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.167` audited generated depth-3 queue-head multi-beat readiness, found no parser, IAL1, IAL0, SystemVerilog lowerer, support-accounting framework, or mdBook prerequisite beyond the local multi-beat depth-3 admission gate, and selected `.168` as the bounded implementation owner.
- in_flight_uncommitted: none after `.167` commit. `.168` is bounded to one concrete `RID` depth-3 queue-head runtime-validation group (`r0`/`r1`/`r2`) with generated multi-beat output banks, valid masks, length outputs, and scalar `RRESP` aggregation; do not enable write depth-3, multiple/mixed depth-3 groups, mixed auto-ID, group-local enqueue widening, packed outputs, direct backend, verification-output generation, or VHDL without a new owned leaf. Ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
