# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD after this slice is `IAL2-FEATURE-COMPLETENESS-FRONTIER.787: select AHB requester BUSY-insertion contract`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.788` is pending; the FIRST behavior-bearing slice of the requester BUSY-insertion family — implement the bounded requester-side AHB single BUSY-beat insertion source per the `.787` contract. Add ppif/ahb_requester_busy_insert.ppif (copy of ppif/ahb_requester.ppif, actor amba_requester_busy_insert, (busy 2'b01), (busy-before-beat 2)); add optional busy + busy_before_beat parser fields + fail-closed validation to AhbRequester::_normalize_transfer + the PPIF adapter (reject busy_before_beat without busy, N outside 1..15, non-literal, duplicate, busy!=2'b01); gate on busy_before_beat a transfer_busy drive block (HTRANS=BUSY, hold request/lock/addr_q/write_q/size_q/burst_q/prot_q/wdata_q, no set) + a busy_inserted_q (width 1, reset 0) one-shot in the beat loop (:432-466) so one held BUSY beat drives before beat_index N then transfer_seq resumes; add busy_insertion report block + ahb_requester_busy_insert_support residue. Support-account intent.ppif_ahb_requester_busy_insert / coverage ial2_ppif_ahb_requester_busy_insert_pipeline_cli / kind ppif / expected module amba_requester_busy_insert. Add t/1498, bump t/248 297->298 protocol / 338->339 total + t/297, language surface + behavior doc + mdBook + README/ROADMAP_V2/KM, --verify-hdl closeout. Preserve ppif/ahb_requester.ppif + t/1473.
- recently_done: `.787` (no-behavior contract selection) selected `.788`, the direct implementation. Contract: a NEW ADDITIVE stem ppif/ahb_requester_busy_insert.ppif (actor amba_requester_busy_insert -> distinct HDL module; kind stays ahb_requester), preserving ppif/ahb_requester.ppif + .ahb mirror + t/1473. Adds (busy 2'b01) HTRANS encoding + (busy-before-beat N) clause: drive one held HTRANS=BUSY beat before the SEQ beat at beat_index N (N literal 1..15; BUSY precedes a SEQ beat, never NONSEQ first; sample N=2). Parser: optional busy + busy_before_beat, fail-closed at parse (busy required, N in 1..15, literal, no dup); runtime no-op if a burst never reaches beat_index N. Generator: transfer_busy drive block (hold address/control, no set) + busy_inserted_q one-shot -> one BUSY cycle then transfer_seq resumes from armed address/beat count (one-bit flag only, inside the byte-only WRAP4/INCR4 window). Report busy_insertion block + ahb_requester_busy_insert_support residue; no new bus-BUSY port (visible on HTRANS); receiving side already parks. Recorded in docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_CONTRACT_SELECTION.md + KM card ial2-ahb-requester-busy-insertion-contract-selection; synced task tree + TASK_TREE + Memory. No behavior change; doc/continuity gates pass. Prior: `.785` selected requester BUSY insertion, `.786` audited readiness.
- in_flight_uncommitted: none expected after the `.787` commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.788`, the direct implementation of the bounded requester-side AHB single BUSY-beat insertion source (add ppif/ahb_requester_busy_insert.ppif + parser busy/busy_before_beat fields + transfer_busy drive block + busy_inserted_q one-shot + report/residue + support accounting + t/1498 + t/248 298/339 + t/297 + language surface + behavior doc + mdBook + --verify-hdl); this is behavior-bearing (first of the family). Then continue the AHB feature-completeness frontier (matching .ahb alias next).

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
  director request. Proposed `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE` owns presenting
  IAL2 as a coherent whole in the mdBook (one language / per-protocol profiles /
  optional `.axi`/`.ahb`/`.apb` aliases / layered lowering, decisions
  0014/0015/0016/0018) and backfilling the thin AXI chapter (142 `.ppif`, ~4%
  documented) — filed from a director question, documentation-only, director-activated.
  None of these trees is currently PNT-eligible.
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
