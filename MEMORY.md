# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after IAL2-FEATURE-COMPLETENESS-FRONTIER.238 commit` - `IAL2-FEATURE-COMPLETENESS-FRONTIER.238: ship dynamic burst-length capture`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.239` audits dynamic runtime beat-count/RLAST validation readiness over generated dynamic last-beat read-data with report-only raw-ARLEN support; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.238` shipped generated report-only dynamic raw-ARLEN burst-length capture over one generated dynamic last-beat read-data transaction. New public sample `ppif/axi_manager_capacity_status_dynamic_read_data_burst_length.ppif` is support-accounted; generated `axi0_arlen` input/storage/request capture/report fields and focused t/1438 coverage passed. Dynamic runtime validation, multi-beat output banks, multiple/mixed dynamic demux, same-cycle recapture, dynamic same-ID ordering, queues, scoreboards, direct backend behavior, and VHDL remain fail-closed.
- in_flight_uncommitted: `.238` implementation/docs are staged for commit workflow in this turn. Full guarded t/1436 and t/1437 attempts were stopped by host-memory guard at default 88% without TAP diagnostics; syntax, direct schedule/check/semantic/default-HDL probes, guarded t/1438, guarded t/248, and focused runtime-validation fail-closed probe passed. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
