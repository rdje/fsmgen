# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after IAL2-FEATURE-COMPLETENESS-FRONTIER.234 commit` - `IAL2-FEATURE-COMPLETENESS-FRONTIER.234: ship dynamic read-data capture`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.235` selects the next exact IAL2 owner after scalar dynamic read-data capture over generated single-active dynamic read response-demux; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.234` shipped bounded scalar dynamic read-data capture over generated dynamic read single-beat and burst-last/`RLAST` response-demux. New support-accounted PPIF samples are `ppif/axi_manager_capacity_status_dynamic_read_data.ppif` and `ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif`; generated `RDATA`/`RRESP` capture is guarded by the generated dynamic completion pulse.
- in_flight_uncommitted: none after the `IAL2-FEATURE-COMPLETENESS-FRONTIER.234` commit. The active `.235` selector must read `.234` behavior, `.233` readiness, dynamic read/write metadata and response-demux precedents, remaining dynamic residue, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map before choosing exactly one next owner. Full `prove t/1437-axi-ial2-manager-capacity-status-generator.t` was attempted in `.234` but stayed CPU-bound in pre-existing regex-heavy assertions without TAP; a guarded `t/1436` rerun after a stale diagnostic expectation fix hit the host-memory cutoff at 90.5%; focused parser/generator/support-accounting/HDL probes and doctrine gates covered the new behavior. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: none.

## Notes
- Before re-deriving a logged fact, consult `KNOWLEDGE_MAP.md` (derived question→fact
  index; cards under `docs/knowledge/`, bundle `knowledge-map/`). Write a fact card
  whenever you establish a durable fact or catch archaeology — lazily, never a sweep
  (`docs/tasks/KNOWLEDGE-MAP-ADOPT.md`).
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Heavy broad Perl/`prove`/`fsmgen` commands must run under
  `scripts/run_with_ram_guard.sh` or equivalent monitoring; default cutoff is
  host RAM 88% / descendant RSS 4096 MiB, below the user's 90% danger zone.
- Optional `slang` HDL validation is a future backend-validation candidate only;
  no `--verify-hdl` policy changed in `.194`
  (`docs/knowledge/hdl-validation-slang-candidate.md`).
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
