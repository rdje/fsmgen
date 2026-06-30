# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.762: audit AHB HBURST SEQ readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.763` is active; select the public contract for bounded endpoint-only AHB HBURST-aware byte-lane `SEQ` semantics.
- recently_done: `.762` selected `.763`, a no-behavior public contract selection for a new endpoint-only HBURST-aware byte-lane `SEQ` source family. Requester HBURST/wrap generation is already present, but the selected byte-lane `SEQ` subordinate bus has no HBURST binding and candidate `(burst HBURST width 3)` subordinate syntax fails closed. Aggregate byte-lane `SEQ` interconnects see global `HBURST` but generated interconnect output has `subordinate_hburst_refs=0`, so aggregate propagation remains a later owner.
- in_flight_uncommitted: none expected after `.762` commit workflow; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.762 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, generic two-subordinate behavior, matching two-subordinate `.ahb` alias behavior, remaining-residue audit, byte-lane/narrow-transfer readiness/contract/behavior, byte-lane `.ahb` alias behavior, aggregate byte-lane readiness/contract/behavior, aggregate byte-lane `.ahb` alias behavior, aggregate alias nested-residue cleanup, burst `SEQ` readiness/contract, shipped generic byte-lane in-word `SEQ` behavior, matching `SEQ` alias follow-on selection, shipped matching byte-lane in-word `SEQ` `.ahb` alias, aggregate `SEQ` readiness/contract selection, shipped generic aggregate byte-lane in-word `SEQ` `.ppif` behavior, matching aggregate `SEQ` alias implementation selection, shipped matching aggregate `SEQ` `.ahb` aliases, selected HBURST length/wrap `SEQ` readiness, and selected endpoint HBURST-aware `SEQ` contract ownership. The `.730`, `.737`, `.745`, and `.748` RAM-guarded attempts were blocked by pre-existing host memory pressure or sandbox process-inspection limits; direct lightweight/focused tests passed.
- next_action: Run `IAL2-FEATURE-COMPLETENESS-FRONTIER.763`: select the public contract for bounded endpoint-only AHB HBURST-aware byte-lane `SEQ` semantics.

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
