# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `IAL2-FEATURE-COMPLETENESS-FRONTIER.775: select AHB BUSY-park contract`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.776` is active; implement the bounded endpoint AHB subordinate BUSY-parking source. FIRST BEHAVIOR-BEARING slice of the feature. Add `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` (copy of the shipped endpoint source with `(ignored-transfer busy)` -> `(parked-transfer busy)`); add optional `parked_transfer` field + relaxed `{idle,busy}`/`{idle}+{busy}` validation to `AhbSubordinate::_normalize_transfer` (:214/:221); gate on the parked-busy flag: `ahb_seq_idle_clear` (:708) fires IDLE-only, `_hburst_seq_policy_report` (:974) drops `busy` from `clears_on` and adds `parks_on=[busy]`, and the `ahb_burst_seq_support_deferred` residue narrows; keep `SEQ`-beat `seq_ok_base` (:526) as the fail-closed drift path. Support-account `intent.ppif_..._busy_park` / coverage `ial2_ppif_..._busy_park_pipeline_cli` / kind `ppif`; add focused `t/1494` (NONSEQ->SEQ->BUSY->SEQ), bump `t/248` (291->292 / 332->333) + `t/297`, language surface, mdBook, docs. Run `--verify-hdl`/prove under the RAM guard.
- recently_done: `.775` (no-behavior contract selection) selected `.776` and pinned the full contract: new additive stem `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` preserving the shipped source + `t/1491`; `(parked-transfer busy)` vocabulary; parser `parked_transfer` field; IDLE-only `ahb_seq_idle_clear`; `parks_on=[busy]` report; residue narrowing; `seq_ok_base` as fail-closed drift path. Wrote `docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_CONTRACT_SELECTION.md` + fact card; synced README/ROADMAP_V2/mdBook/task tree. No behavior changed.
- in_flight_uncommitted: none expected after the `.772` handoff commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.776`, implement the bounded endpoint AHB subordinate BUSY-in-burst parking source (first behavior-bearing BUSY-park slice).

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
