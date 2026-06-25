# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.471: generate queue runtime validation`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.472` audits multi-beat output-bank readiness after generated dynamic read same-ID issue-order queue runtime validation; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.471` shipped runtime beat-count/`RLAST` validation over generated dynamic read same-ID `issue-order-queue` raw-`ARLEN` read-data. It added `ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`, support accounting, expected-beat storage, read-beat counters, request-time `ARLEN[4:0] + 5'd1` initialization, matched queue read-beat increments, four beat-count/`RLAST` assertions per transaction, docs, mdBook, and Knowledge Map coverage while preserving `.469` report-only behavior.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: none. `.471` passed syntax checks, guarded schedule JSON, reduced parser/report/ISF/FSM probes, t/248 support-accounting, Knowledge Map generation/check, mdBook build, docs path audit, memory architecture check, diff check, and doctrine gate. Filtered t/1438 was stopped without TAP in the HDL-heavy path; guarded strict check JSON exceeded default and 6 GiB RSS cutoffs; semantic JSON is not claimed.
- next_action: Start `.472`: audit multi-beat output-bank readiness after generated dynamic read same-ID issue-order queue runtime validation, preserving `.471` runtime validation and future-owning recapture widening, broader queues, mixed queues, scoreboards, direct backend, backend-language variants, and VHDL.

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
  `.295` used documented 90% host-cutoff retries only after default host-memory
  trips; a 92% retry request was rejected as too risky and was not run.
- Optional `slang` HDL validation is a future backend-validation candidate only;
  no `--verify-hdl` policy changed in `.194`
  (`docs/knowledge/hdl-validation-slang-candidate.md`).
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
