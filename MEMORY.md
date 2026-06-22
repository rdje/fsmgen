# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `HEAD after IAL2-FEATURE-COMPLETENESS-FRONTIER.237 commit` - `IAL2-FEATURE-COMPLETENESS-FRONTIER.237: audit dynamic burst-length readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.238` generates report-only dynamic raw-ARLEN burst-length capture over generated single-active dynamic read last-beat response-demux and scalar dynamic read-data; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.237` audited dynamic burst-length readiness and selected direct bounded implementation of report-only raw-ARLEN capture. Existing `read-data.read` burst-length syntax and generated raw-ARLEN input/storage/rule/report scaffolding are sufficient; the local dynamic coverage gate is the next implementation boundary. No parser, generator, PPIF sample, support-accounting, validation behavior, generated artifact, test, schedule/check/semantic JSON, or HDL behavior changed.
- in_flight_uncommitted: none after the `IAL2-FEATURE-COMPLETENESS-FRONTIER.237` commit. The active `.238` owner must implement only the .237-selected report-only dynamic raw-ARLEN shape, add a support-accounted public PPIF sample and focused t/1438 coverage, and keep dynamic runtime validation, multi-beat output banks, multiple/mixed dynamic demux, same-cycle recapture, dynamic same-ID ordering, queues, scoreboards, direct backend behavior, and VHDL fail-closed. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
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
