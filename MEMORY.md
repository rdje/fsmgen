# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `IAL2-FEATURE-COMPLETENESS-FRONTIER.781: select AHB aggregate BUSY-park contract`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.782` is active; the direct implementation shipping BOTH aggregate BUSY-park `.ppif` stems. Add `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif` (copy of `ahb_interconnect_byte_lane_hburst_seq.ppif`, child count 3) and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif` (copy of the two-subordinate, child count 4), each with the inlined child transfer `(ignored-transfer busy)`->`(parked-transfer busy)`. Support-account intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park + intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park (coverage ..._busy_park_pipeline_cli, kind ppif, module ahb_tb, root top). NO interconnect generator/parser/report code change (verbatim seq_policy clone auto-forwards parks_on=[busy]); narrow ONLY the aggregate HBURST residue at AhbInterconnect.pm:1401 (leave :1403 base). Add focused `t/1496`, bump t/248 293->295 protocol/334->336 total, extend t/297, add language surface + behavior doc docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md + mdBook. Preserve aggregate HBURST SEQ + t/1492/t/1493 and endpoint BUSY-park + t/1494/t/1495. NB: the two-subordinate `--check` is slow (~63s); run heavy prove/fsmgen under the RAM guard.
- recently_done: `.781` (no-behavior selector) selected `.782`, shipping BOTH aggregate BUSY-park `.ppif` stems (mirroring `.770`, which shipped both aggregate HBURST stems in one slice). Confirmed the delta is source data + residue narrowing only: the `(parked-transfer busy)` vocabulary is child-role-shared (AhbSubordinate.pm:224-245), `_seq_policy_propagation_report` clones child seq_policy verbatim (AhbInterconnect.pm:1177/:1207) so parks_on=[busy] surfaces with no new interconnect field, and only the aggregate HBURST residue at :1401 narrows. Exact support identities/coverage/child-counts and the t/248 295/336 delta recorded in docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_CONTRACT_SELECTION.md + KM fact card; synced README/ROADMAP_V2/mdBook (16c+14)/TASK_TREE/KM/task tree. No behavior changed.
- in_flight_uncommitted: none expected after the `.781` handoff commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.782`, the implementation shipping both aggregate BUSY-park `.ppif` stems (source data + AhbInterconnect.pm:1401 residue narrowing + support-accounting + focused t/1496 + t/248 295/336 + docs); then advance to the matching aggregate `.ahb` alias selector `.783`.

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
  director request; proposed `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION` owns the
  finding that in-file secondary views (`## Current Frontier`/`## Commit Log`/
  `## Verification Log`/`## Changelog`) lag the authoritative node list (needs a
  maintain-vs-retire director decision). None of these trees is currently PNT-eligible.
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
