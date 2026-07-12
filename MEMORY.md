# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `IAL2-FEATURE-COMPLETENESS-FRONTIER.776: ship AHB BUSY-park source`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.777` is active; select the matching endpoint AHB subordinate BUSY-park `.ahb` profile alias contract (no-behavior selector). Mirror the `.765`/`.766` endpoint HBURST alias precedent: pick alias path `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`, support identity `intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park`, coverage key, source kind `ial2_profile_alias`, alias-only residue cleanup, focused test, and implementation owner.
- recently_done: `.776` (first behavior-bearing BUSY-park slice) shipped `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`. Added the `parked_transfer` field to PPIF.pm `_parse_ahb_subordinate_transfer_block` + `AhbSubordinate::_normalize_transfer` (relaxed validation to accept `{idle}`ignored+`{busy}`parked, fail-closed unless hburst seq policy). Gated on parked-busy: `ahb_seq_idle_clear` fires IDLE-only (verified generated IAL1 `(== HTRANS 2'b00)` vs shipped `(| idle busy)`), `_hburst_seq_policy_report` drops busy from `clears_on` + adds `parks_on=[busy]`, residue records shipped parking. Support-accounted (RegressionCorpus + LanguageSurfaceSection); focused `t/1494` passes; `t/248` -> 292/333; `t/297` unchanged. Shipped source + existing AHB sources unchanged (verified). FINDING: `--verify-hdl` surfaces 2 pre-existing Verilator WIDTHEXPAND warnings on the wait-counter, identical on the shipped source (family-wide, not this slice) — see AHB_VERIFY_HDL_WIDTHEXPAND finding. Synced README/ROADMAP_V2/mdBook/KM/task tree.
- in_flight_uncommitted: none expected after the `.772` handoff commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.777`, no-behavior selector for the matching endpoint AHB subordinate BUSY-park `.ahb` profile alias contract.

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
