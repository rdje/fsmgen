# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `IAL2-FEATURE-COMPLETENESS-FRONTIER.771: select AHB aggregate HBURST alias contract`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.772` is active; implement the matching aggregate AHB HBURST-aware `.ahb` profile aliases.
- recently_done: `.771` (no-behavior selector) selected `.772`, direct data-only implementation of the matching aggregate `.ahb` profile aliases `ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb` (mirroring the shipped generic `.ppif` sources). Selected support identities `intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq` (child count 3) and `intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq` (child count 4), coverage keys `ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_pipeline_cli` / `ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli`, source kind `ial2_profile_alias`, module `ahb_tb`. Reserved `.ahb` label parser + scratchpad CLI probes confirmed both aliases lower to `ahb_tb`, preserve `subordinate_owned_hburst_in_word_seq_policy`, and drop `ahb_aggregate_profile_alias_deferred` (top) + `ahb_subordinate_profile_alias_deferred` (child) via existing suffix-keyed suppression with NO adapter change. `.772` = add 2 `.ahb` fixtures + 2 RegressionCorpus entries + focused `t/1493` + flip the two deferred-alias assertions in `t/1492` + docs/mdBook.
- in_flight_uncommitted: none expected after the `.771` handoff commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.771 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the selected aggregate HBURST `.ahb` alias contract. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~99% and trips the 88% cutoff on an otherwise-healthy host (`memory_pressure` showed 68% free); this blocks any command run under it, including the heavy t/248 gate. Lightweight single-file `fsmgen` commands were run directly per COMMIT.md (guard is for broad/heavy runs only). See surfaced finding + tracked follow-up.
- next_action: Run `.772`, ship the two aggregate AHB HBURST-aware `.ahb` profile aliases and their support-accounting/tests/docs.

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
