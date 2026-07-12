# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD after this slice is `IAL2-FEATURE-COMPLETENESS-FRONTIER.786: audit AHB requester BUSY-insertion readiness`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.787` is pending; the no-behavior public contract selection for the requester-side AHB BUSY-beat insertion source, selected by `.786`. Settle: source path/intent/anchor/support identity/coverage/source kind; in-place widen of ppif/ahb_requester.ppif vs a new additive stem (preserve t/1473 + the .ahb mirror); the busy=2'b01 HTRANS encoding + insertion-clause syntax (spelling/placement, one-beat vs policy) and how PPIF.pm/AhbRequester record it; the transfer_busy drive block (drive HTRANS=BUSY, hold HADDR/HWRITE/HSIZE/HBURST/HWDATA, do not advance beat_index_q/beats_remaining_q or address) + beat-loop insertion point + SEQ re-entry (following beat SEQ not spurious NONSEQ); fail-closed for malformed/out-of-range insertion; local_status bus-BUSY reporting vs internal local_status.busy; requester residue add/narrow; test shape (model t/1473 + t/1494), t/248/t/297 impact, mdBook, preservation, rollback; matching .ahb alias sequencing. No behavior change in `.787`.
- recently_done: `.786` (no-behavior readiness audit) selected `.787`, a public contract selection for the requester BUSY-insertion source. Found the requester burst machinery ready but the contract surface open. Evidence: requester declares only idle/nonseq/seq (ppif/ahb_requester.ppif:65-71; AhbRequester.pm:224-232), no busy=2'b01 encoding, no transfer_busy drive block; beat loop :430-466 drives request_bus(IDLE)/transfer_nonseq(beat0)/transfer_seq(later) and advances counters on OKAY; local_status.busy (:175/:474) internal; requester _unsupported_residue (:566-590) carries NO BUSY-insertion deferral (implementation adds then narrows one). Machinery ready (beat_index_q/beats_remaining_q width 5, wrap regs, all eight burst encodings) so a held BUSY beat only drives HTRANS=BUSY re-driving same addr/control without advancing counters, inside the byte-only WRAP4/INCR4 window; receiving side already parks (parks_on=[busy] per child), no subordinate/interconnect change expected. Recorded in docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_READINESS_AUDIT.md + KM card ial2-ahb-requester-busy-insertion-readiness-audit; synced task tree + TASK_TREE + Memory. No behavior change; doc/continuity gates pass. Prior: `.785` selected requester-side BUSY insertion as the next AHB increment.
- in_flight_uncommitted: none expected after the `.786` commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.787`, the no-behavior public contract selection for the requester-side AHB BUSY-beat insertion source (settle source path/stem-vs-widen, busy=2'b01 encoding + insertion-clause syntax, transfer_busy drive block + insertion point/SEQ re-entry, fail-closed, local_status reporting, residue, tests/docs/preservation, .ahb alias sequencing); then implement it and continue the AHB feature-completeness frontier.

## Notes
- Before re-deriving a logged fact, consult `KNOWLEDGE_MAP.md` (derived question→fact
  index; cards under `docs/knowledge/`, bundle `knowledge-map/`). Write a fact card
  whenever you establish a durable fact or catch archaeology — lazily, never a sweep
  (`docs/tasks/KNOWLEDGE-MAP-ADOPT.md`).
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Proposed `FSMGEN-HIR-ROADMAP-FRONTIER` owns the source-facing HIR roadmap
  phase; proposed `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` now consults that HIR
  boundary before direct IAL2/IAL1 builder work; proposed
  `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON` owns the beyond-read-only MCP horizon
  (write/generation/sampling/elicitation/roots/service transport), filed at
  director request. None of these trees is currently PNT-eligible.
- Decision `0019` (done via `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION`): a task tree's
  live sources are the `## Task Tree` node list + `docs/TASK_TREE.md` + git; the
  in-file `## Current Frontier`/`## Verification Log`/`## Commit Log`/`## Changelog`
  are optional historical snapshots, NOT maintained per-slice. PNT selects the
  earliest active/pending unblocked leaf from the node list, not the frontier table.
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
