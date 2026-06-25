# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.463: generate dynamic read RLAST queue`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.464` selects the next exact IAL2 owner after generated dynamic read burst-last `RID && RLAST` same-ID issue-order queue behavior; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.463` shipped generated bounded two-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID `issue-order-queue` behavior. It added the public support-accounted sample `ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif`, compact runtime-ID queue slots with slot-local `ARID`, raw earliest matching `RID` response ownership, final completion/dequeue only on earliest matching captured runtime ID plus `RLAST`, same-cycle selected final dequeue plus one enqueue, non-final no-dequeue assertions, report mode `bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`, completion source `generated_dynamic_issue_order_queue_demux_last_beat`, status `generated_dynamic_read_rid_rlast_issue_order_queue`, first scope `read_rid_rlast_two_dynamic_transactions`, docs, fact card, and mdBook sync.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: none. Current host memory pressure stopped guarded focused t/1438, strict check JSON, and semantic JSON probes for `.463`; syntax checks, guarded schedule JSON, and guarded t/248 support-accounting passed. Broad t/1436/t1437/t1438, strict/semantic closeout, HDL validation, direct backend, backend-language variants, and VHDL are not claimed.
- next_action: Start `.464`: select the next exact IAL2 owner or cleanup prerequisite after generated dynamic read burst-last same-ID queues, without behavior changes.

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
