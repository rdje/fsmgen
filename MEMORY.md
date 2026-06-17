# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after .151 commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.151: align support detail expectations`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.152` audit read-data over generated read single-beat depth-3 queue-head response-demux readiness; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.151` aligned the focused PPIF support-detail expectation with the production support prose that now explicitly names independent depth-2 queue-head groups; `.150` selected that validation-surface repair after `.149` shipped generated read single-beat depth-3 queue-head response-demux.
- in_flight_uncommitted: none after `.151` commit. The public depth-3 sample is `ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif`; it support-accounts as `intent.ppif_axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux`, generates slot0..slot2 compact same-ID queue state and r0/r1/r2 completion pulses, and keeps `RLAST`/read_data absent. `.152` is readiness/audit only until it selects an implementation or prerequisite; read-data over depth-3 queues, write or burst-last depth-3 response-demux, multiple or mixed depth-3 groups, same-family mixed auto-ID, group-local enqueue widening, direct backend, and VHDL remain deferred. Ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
