# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `IAL2-FEATURE-COMPLETENESS-FRONTIER.780: audit AHB aggregate BUSY-park readiness`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.781` is active; no-behavior public contract selection for the aggregate AHB BUSY-park source(s). Settle: source path(s)/intent name(s)/anchor(s), support identity, coverage key(s), source kind for the one-subordinate stem `ahb_interconnect_byte_lane_hburst_seq_busy_park` and, if included, the two-subordinate `ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`; whether one or both stems ship first (preserve shipped aggregate HBURST SEQ + t/1492/t/1493); confirm the child transfer reuses shipped `(parked-transfer busy)` with no interconnect parser change and `_seq_policy_propagation_report` needs no change beyond the verbatim clone; residue narrowing scope (AhbInterconnect.pm:1401 HBURST, and whether :1403 base is touched); focused test shape (model t/1492/t/1493/t/1494), t/248/t/297 impact, language surface, mdBook, KM; rollback/preservation; later matching aggregate `.ahb` alias. No behavior change in the selector.
- recently_done: `.780` (no-behavior audit) selected `.781`, the aggregate BUSY-park contract selection. Found the aggregate more ready than the endpoint was before `.774`: the interconnect composes child subordinate FSMs via `AhbSubordinate->generate($_)` (AhbInterconnect.pm:38-41) then `(?fsmc:...)` (:585-588), so a `(parked-transfer busy)` child parks BUSY through the shipped endpoint machinery with no interconnect generator change; `_seq_policy_propagation_report` clones child seq_policy verbatim (:1177/:1207) so parks_on=[busy] surfaces with no new field; the parked-busy vocabulary/parser/report is shared (AhbSubordinate.pm:224-245/:1014-1016) and the child `seq_ok_base` fail-closed path carries through composition. Bounded delta = new aggregate stem(s) + residue narrowing at :1401. Contract still open (stem names, one vs both, support identity/coverage/kind/artifact, residue scope, test, alias). Recorded in docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_READINESS_AUDIT.md + KM fact card; synced README/ROADMAP_V2/mdBook (16c+14)/TASK_TREE/KM/task tree. No behavior changed.
- in_flight_uncommitted: none expected after the `.780` handoff commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.781`, the no-behavior public contract selection for the aggregate AHB BUSY-park source(s); settle stem name(s)/support identity/coverage/residue scope, then advance to the `.782` implementation.

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
