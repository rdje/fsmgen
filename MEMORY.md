# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `IAL2-FEATURE-COMPLETENESS-FRONTIER.770: ship AHB aggregate HBURST PPIF`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.771` is active; select the matching aggregate AHB HBURST-aware `.ahb` alias contract.
- recently_done: `.770` shipped `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`, support-accounted as `intent.ppif_ahb_interconnect_byte_lane_hburst_seq` and `intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq`. The sources lower through generated HBURST-aware subordinate `.isf`/`.fsm` artifacts, select HDL entry `ahb_tb`, forward requester/global `HBURST` directly to child-local `HBURST_REGS`/`HBURST_STATUS`/`HBURST_CONTROL`, preserve `composition.byte_lane_propagation`, and reuse `composition.seq_policy_propagation` with `subordinate_owned_hburst_in_word_seq_policy`, request-forwarding `burst`, child `bindings.bus.burst`, and child `transfer.seq_policy` metadata. Matching aggregate `.ahb` aliases remain deferred and are routed to `.771`.
- in_flight_uncommitted: none expected after the `.770` handoff commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.770 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior, shipped matching HBURST `.ahb` alias behavior, aggregate HBURST propagation readiness/contract routing, and shipped aggregate HBURST-aware `.ppif` behavior. The RAM-guarded t/248 attempt for `.764` stopped at pre-existing host memory 99.6% against the 88% cutoff; do not bypass the cutoff.
- next_action: Run `.771`, no-behavior public contract selection for matching aggregate AHB HBURST-aware `.ahb` aliases.

## Notes
- Before re-deriving a logged fact, consult `KNOWLEDGE_MAP.md` (derived question→fact
  index; cards under `docs/knowledge/`, bundle `knowledge-map/`). Write a fact card
  whenever you establish a durable fact or catch archaeology — lazily, never a sweep
  (`docs/tasks/KNOWLEDGE-MAP-ADOPT.md`).
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Proposed `FSMGEN-HIR-ROADMAP-FRONTIER` owns the source-facing HIR roadmap
  phase; proposed `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` now consults that HIR
  boundary before direct IAL2/IAL1 builder work. Neither tree is currently
  PNT-eligible.
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
