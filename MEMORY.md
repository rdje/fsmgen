# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD after this slice is `IAL2-FEATURE-COMPLETENESS-FRONTIER.783: select aggregate AHB BUSY-park .ahb alias contract`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.784` is pending; the direct implementation of the matching aggregate BUSY-park `.ahb` profile aliases. Add `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb` as byte-identical mirrors of the shipped generic `.ppif` sources. Support-account intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park (coverage ..._pipeline_cli, child count 3) + intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park (child count 4), source kind ial2_profile_alias, module ahb_tb, root top. Data-only via the existing suffix-keyed suppression (no adapter change): aliases keep the aggregate topology, preserve each child parks_on=[busy]/BUSY-free clears_on, and drop ahb_aggregate_profile_alias_deferred + ahb_subordinate_profile_alias_deferred. Add focused t/1497 (model t/1493/t/1495/t/1496), bump t/248 295->297 protocol/336->338 total, extend t/297, add language surface + behavior doc + mdBook. NB: the two-subordinate `--check` is slow (~63s); run heavy prove/fsmgen under monitoring.
- recently_done: `.783` (no-behavior selector) selected `.784`, the aggregate BUSY-park `.ahb` alias implementation. Confirmed data-only via a reserved `.ahb`-label parse of both `.782` BUSY-park sources: keeps aggregate topology (3/4), preserves child parks_on=[busy]/BUSY-free clears_on, drops both profile-alias residues via the existing suffix-keyed suppression with no PPIF/interconnect code change. Exact support identities/coverage/child-counts + the t/248 297/338 delta recorded in docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_ALIAS_CONTRACT_SELECTION.md + KM fact card; synced README/ROADMAP_V2/mdBook (14)/TASK_TREE/task tree/Memory. No behavior changed. Prior: `.782` shipped both aggregate BUSY-park `.ppif` stems (source data + AhbInterconnect.pm:1401 residue narrowing via `_all_subordinates_park_busy`; focused t/1496, t/248 295/336).
- in_flight_uncommitted: none expected after the `.783` commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.784`, the direct implementation of the matching aggregate BUSY-park `.ahb` profile aliases (two byte-identical `.ahb` mirrors + support-accounting + focused t/1497 + t/248 297/338 + language surface + behavior doc + mdBook); then continue the AHB feature-completeness frontier.

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
