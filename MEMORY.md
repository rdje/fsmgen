# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD after this slice is `IAL2-FEATURE-COMPLETENESS-FRONTIER.784: ship aggregate AHB BUSY-park .ahb profile aliases`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.785` is pending; the no-behavior selector for the next bounded AHB feature-completeness increment after the aggregate BUSY-park `.ppif`/`.ahb` family completed. Compare the remaining candidates — requester-side BUSY insertion (the requester never drives bus HTRANS=BUSY; AhbRequester local_status.busy is internal), halfword/word burst SEQ (supported_sizes=[byte], 4-beat/4-byte window), wider/indefinite bursts (WRAP8/INCR8/WRAP16/INCR16/indefinite INCR; fail_closed modes, seq_beats_remaining_q width 2), multi-word/register-bank SEQ progression, and optional/property-gated AHB signals — and select the smallest next safe increment + its first owner leaf (readiness audit or contract selection), with evidence for why the others are larger. No behavior change in `.785`.
- recently_done: `.784` shipped both aggregate BUSY-park `.ahb` profile aliases `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` (child count 3) and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb` (child count 4) as byte-identical mirrors (cmp confirms) of the `.782` generic BUSY-park `.ppif` sources. Support-accounted as intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park + ..._two_subordinate_..._busy_park (source kind ial2_profile_alias, module ahb_tb). Data-only: aliases drop ahb_aggregate_profile_alias_deferred + ahb_subordinate_profile_alias_deferred via the existing suffix-keyed suppression, preserve each child parks_on=[busy]/BUSY-free clears_on, no adapter change. Added focused t/1497 (PASS, 5 subtests), bumped t/248 297/338 (both maps), extended t/297 .ahb boundary/fixtures; behavior doc docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_PROFILE_ALIAS_BEHAVIOR.md + KM card; synced LanguageSurfaceSection/README/ROADMAP_V2/mdBook (16c count 29->31, 14)/TASK_TREE/task tree/Memory. Prior: `.782` shipped the aggregate BUSY-park `.ppif` stems; `.783` selected the `.ahb` alias contract.
- in_flight_uncommitted: none expected after the `.784` commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.785`, the no-behavior selector for the next bounded AHB feature-completeness increment after the aggregate BUSY-park family (compare requester-side BUSY insertion / halfword-word burst SEQ / wider bursts / optional signals, pick the smallest safe next + first owner leaf); then continue the AHB feature-completeness frontier.

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
