# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after .180 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.180: ship burst-last depth-3 read-data`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.181` select the next IAL2 feature-completeness slice after generated read burst-last scalar last-beat read-data over multiple/mixed depth-3 concrete same-ID queue-head groups; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.180` shipped generated read burst-last scalar last-beat `RDATA`/`RRESP` over two-depth-3 and mixed depth-3/depth-2 concrete same-ID queue-head groups with no `burst_length` metadata. Two new public PPIF samples are support-accounted, strict check/semantic JSON matched, and HDL-verifiable; the change widened only the local no-`burst_length` last-beat read-data coverage gate.
- in_flight_uncommitted: none after `.180` commit. `.181` owns the next selector and must compare burst-length/runtime/multi-beat over multiple/mixed depth-3 groups, write-family read-data, same-family mixed auto-ID plus concrete queue-head demux, group-local enqueue widening, packed burst-vector outputs, alternate full burst assembly, verification-output generation, direct backend, VHDL, and backend-language variants before any further behavior change. Ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
