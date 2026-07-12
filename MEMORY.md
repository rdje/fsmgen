# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `IAL2-FEATURE-COMPLETENESS-FRONTIER.777: select AHB BUSY-park alias`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.778` is active; implement the matching endpoint AHB subordinate BUSY-park `.ahb` profile alias per the `.777` selection. Add `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb` as a byte-identical mirror of the shipped `.ppif` BUSY-park source; support-account in RegressionCorpus as `intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park` (coverage `ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`, kind `ial2_profile_alias`, expected module `ahb_lite_subordinate_byte_lane_hburst_seq_busy_park`, semantic root kind `fsm`); add focused `t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t`; bump `t/248` (292→293 protocol / 333→334 total) + `t/297`; add LanguageSurfaceSection entry + behavior doc `docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_PROFILE_ALIAS_BEHAVIOR.md`. Data-only: the suffix-keyed suppression (`PPIF.pm:89`–`:96`,`:146`) removes `ahb_subordinate_profile_alias_deferred` + `.ahb alias exposure` residue with NO adapter change (proven by reserved `.ahb`-label probe). Mirror the `.766`/`.772` alias impl precedent.
- recently_done: `.777` (no-behavior selector) selected `.778` and pinned the matching endpoint BUSY-park `.ahb` alias contract. Reverified the generic `.ppif` source support identity + `parks_on:[busy]`/`clears_on` report + preserved source-surface alias residue. A reserved `.ahb`-label CLI probe (scratchpad copy, NOT tracked) strict-checked, preserved the parks_on/clears_on shape + generated `.isf`/`.fsm`, and dropped `ahb_subordinate_profile_alias_deferred` + the `.ahb alias exposure` residue wording via the existing suffix-keyed suppression (`support_accounting.matched=false` only because no tracked fixture/catalog entry yet) → confirms `.778` is data-only. Recorded in `docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_ALIAS_CONTRACT_SELECTION.md` + KM fact card; synced README/ROADMAP_V2/mdBook (16c + 14)/TASK_TREE/task tree/KM. No behavior changed.
- in_flight_uncommitted: none expected after the `.777` handoff commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.778`, the direct implementation of the matching endpoint AHB subordinate BUSY-park `.ahb` profile alias (data-only alias fixture + RegressionCorpus entry + focused `t/1495` + `t/248`/`t/297` bump + language surface + behavior doc), per `docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_ALIAS_CONTRACT_SELECTION.md`.

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
