# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after implementation commit` — `IAL2-FEATURE-COMPLETENESS-FRONTIER.146: ship single-beat multi-group read-data`.
- active_work_unit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` pending first SV/UVM verification output contract selector; `IAL2-FEATURE-COMPLETENESS-FRONTIER.147` select the next AXI manager feature-completeness slice after generated read-data over read single-beat multi-group queue-head response-demux; `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remains active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.146` shipped generated read-data over read single-beat multi-group queue-head response-demux; `IAL2-FEATURE-COMPLETENESS-FRONTIER.145` selected `.146`; `IAL2-FEATURE-COMPLETENESS-FRONTIER.144` selected `.145`; `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1`; older completed slices are in task trees and git history.
- in_flight_uncommitted: none after implementation commit; `.146` added `ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif`, support accounting, generator and PPIF/CLI tests, docs/book/roadmap/task-tree/Knowledge Map sync, and report/residue support prose. Direct schedule/check/semantic probes passed for the new sample; focused `prove -lv t/1437-axi-ial2-manager-capacity-status-generator.t` and `prove -lv t/1436-ial2-ppif-parser-cli.t` passed. Next IAL2 action is `.147`, a selector before any further behavior change; ignored local-only mirrors are at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
