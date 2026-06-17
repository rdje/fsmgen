# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after .171 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.171: ship write depth-3 demux`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.172` select the next IAL2 feature-completeness slice after write depth-3 queue-head response-demux; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.171` shipped generated write-family depth-3 concrete same-ID queue-head response-demux for one `w0`/`w1`/`w2` group sharing concrete `BID` `3`, queue depth `3`, and boundary `generated_write_bid_queue_head_demux`; added public PPIF/support/tests/docs/mdBook/KM and preserved adjacent write depth-2/multi-group and read depth-3 behavior.
- in_flight_uncommitted: none after `.171` commit. `.172` is a selector/audit only: read `.171`, `.170`, current reports/support accounting, roadmap, mdBook, task tree, Memory, and Knowledge Map; choose the next exact leaf before any behavior-bearing code changes. Do not implement multiple/mixed depth-3 groups, mixed auto-ID, group-local enqueue widening, packed outputs, direct backend, verification-output generation, VHDL, or backend-language variants without a new owned leaf. Ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
