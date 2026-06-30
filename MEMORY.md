# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.755: select AHB aggregate SEQ readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.756` is active; audit readiness for bounded AHB aggregate byte-lane in-word `SEQ` propagation.
- recently_done: `.755` selected `.756`, no-behavior readiness audit for bounded AHB aggregate byte-lane in-word `SEQ` propagation. Current probes confirmed the endpoint alias `ppif/ahb_lite_subordinate_byte_lane_seq.ahb` exposes `transfer.seq_policy` and support-accounts as `intent.ahb_profile_alias_subordinate_byte_lane_seq`, while aggregate byte-lane sources still instantiate non-`SEQ` byte-lane subordinate children and aggregate reports still carry `ahb_burst_seq_support_deferred` at top-level and child-report surfaces. `.756` must audit source family names, one- and two-subordinate child naming, child `transfer.seq_policy` propagation, aggregate report shape, residue movement, validation, rollback, and aggregate `.ahb` alias sequencing before any behavior change.
- in_flight_uncommitted: `.755` selector docs/Memory/task-tree/Knowledge Map updates are ready for commit workflow; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.755 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, generic two-subordinate behavior, matching two-subordinate `.ahb` alias behavior, remaining-residue audit, byte-lane/narrow-transfer readiness/contract/behavior, byte-lane `.ahb` alias behavior, aggregate byte-lane readiness/contract/behavior, aggregate byte-lane `.ahb` alias behavior, aggregate alias nested-residue cleanup, burst `SEQ` readiness/contract, shipped generic byte-lane in-word `SEQ` behavior, matching `SEQ` alias follow-on selection, shipped matching byte-lane in-word `SEQ` `.ahb` alias, and aggregate `SEQ` readiness selection. The `.730`, `.737`, `.745`, and `.748` RAM-guarded attempts were blocked by pre-existing host memory pressure or sandbox process-inspection limits; direct lightweight/focused tests passed.
- next_action: Run `IAL2-FEATURE-COMPLETENESS-FRONTIER.756`: audit readiness for bounded AHB aggregate byte-lane in-word `SEQ` propagation; make no behavior change in the audit.

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
