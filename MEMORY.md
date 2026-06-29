# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.723: ship AHB interconnect PPIF`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.724` is active; select the next exact IAL2/AHB follow-on owner after the bounded public AHB interconnect/decode PPIF shipment.
- recently_done: `.723` shipped `ppif/ahb_interconnect.ppif`, embedding one requester, one subordinate, and one interconnect object. It lowers through generated `amba_requester.isf`, `ahb_lite_subordinate.isf`, and `ahb_interconnect.isf` before generated `amba_requester.fsm`, `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, aggregate `ahb_tb.fsm`, and HDL module `ahb_tb`. Report schema is `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`; support accounting is `intent.ppif_ahb_interconnect` / `source_kind ppif` / `ial2_ppif_ahb_interconnect_pipeline_cli`. Behavior: fixed `HGRANT=1`, base-0 size-4 decode, `HSEL_REGS`, local `HADDR_REGS`, global `HREADY`, one-bit subordinate `HRESP_REGS` to two-bit requester `HRESP` OKAY/ERROR mapping, and two-cycle unmapped active-transfer ERROR.
- in_flight_uncommitted: none after the `.723` commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.723 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, and endpoint `.ahb` aliases. Broad corpus/accounting work must remain guarded; `t/248-regression-corpus-accounting.t` was run through `scripts/run_with_ram_guard.sh`.
- next_action: Run `IAL2-FEATURE-COMPLETENESS-FRONTIER.724`: select the next exact AHB follow-on owner without behavior changes.

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
