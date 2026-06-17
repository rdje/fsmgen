# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after .169 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.169: select write depth-3 readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.170` audit generated write-family depth-3 concrete same-ID queue-head response-demux readiness; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.169` selected `.170` after live probes showed existing write depth-2 one-group and multi-group queue-head response-demux samples are generated, while a temporary write depth-3 candidate strict-checks cleanly and remains selected-not-generated at `generated_same_id_queue_head_demux`.
- in_flight_uncommitted: none after `.169` commit. `.170` is audit-only: read the selector and adjacent read/write queue-head behavior, probe one temporary write depth-3 candidate plus existing generated siblings, and decide whether implementation can widen only the local write queue-head admission boundary. Do not enable behavior, read-data, burst-length, runtime-validation, multi-beat payload, multiple/mixed depth-3 groups, mixed auto-ID, group-local enqueue widening, packed outputs, direct backend, verification-output generation, VHDL, or backend-language variants without a new owned leaf. Ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
