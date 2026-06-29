# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.725: select AHB interconnect alias implementation`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.726` is active; implement the selected bounded public AHB aggregate `.ahb` profile-alias exposure.
- recently_done: `.724` selected aggregate AHB `.ahb` profile-alias contract selection. `.725` selected `.726`, bounded implementation of `ppif/ahb_interconnect.ahb`, mirroring `ppif/ahb_interconnect.ppif`, with support identity `intent.ahb_profile_alias_interconnect`, source kind `ial2_profile_alias`, coverage `ial2_ahb_profile_alias_interconnect_pipeline_cli`, report schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, generated requester/subordinate/interconnect `.isf` and `.fsm` artifacts, aggregate `ahb_tb.fsm`, HDL module `ahb_tb`, semantic root kind `top`, and `ahb_aggregate_profile_alias_deferred` removed only from aggregate `.ahb` reports.
- in_flight_uncommitted: none after the `.725` commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.725 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint `.ahb` aliases, and the aggregate `.ahb` implementation route. Broad corpus/accounting work must remain guarded.
- next_action: Run `IAL2-FEATURE-COMPLETENESS-FRONTIER.726`: implement `ppif/ahb_interconnect.ahb` without broadening AHB behavior.

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
