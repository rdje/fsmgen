# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `IAL2-FEATURE-COMPLETENESS-FRONTIER.779: select next AHB slice`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.780` is active; no-behavior readiness audit for bounded aggregate AHB BUSY-parking propagation (holding a child subordinate's in-word HBURST SEQ burst context across an HTRANS=BUSY beat inside the interconnect aggregate propagation, mirroring the shipped endpoint BUSY-park). Audit whether it can implement directly on new aggregate sources or needs a contract selection first: the child transfer change `(ignored-transfer idle)+(parked-transfer busy)`; whether `_seq_policy_propagation_report` (AhbInterconnect.pm:1177/:1207 verbatim seq_policy clone) needs any change beyond forwarding the child seq_policy; residue narrowing at AhbInterconnect.pm:1401/:1403 (drop `BUSY-in-burst handling`); child `seq_ok_base` fail-closed through the interconnect; one vs both aggregate stems; support identity/coverage/source-kind/artifact (module `ahb_tb`); later `.ahb` alias; test (model t/1492/t/1493/t/1494), t/248/t/297 impact, language surface, mdBook, KM; rollback/preservation. No behavior change in the audit.
- recently_done: `.779` (no-behavior selector) selected `.780`, the aggregate AHB BUSY-park propagation readiness audit. Rationale: every prior AHB burst feature shipped endpoint-first then propagated (`.764`->`.770`->`.772` for HBURST SEQ), BUSY-park now shipped at endpoint (`.776`/`.778`); endpoint residue defers `aggregate propagation` (AhbSubordinate.pm:1031) while aggregate residue still lists `BUSY-in-burst handling` first (AhbInterconnect.pm:1401/:1403). Bounded: interconnect clones child seq_policy verbatim so `(parked-transfer busy)` auto-forwards parks_on=[busy] into `composition.seq_policy_propagation`; delta is new aggregate stems + residue narrowing, reusing the shared `_normalize_transfer` parked-busy path. Rejected requester-side BUSY insertion (requester never drives bus HTRANS=BUSY; AhbRequester.pm:473), halfword/word SEQ, wider/indefinite bursts, optional signals as larger. Recorded in docs/IAL2_POST_AHB_ENDPOINT_BUSY_PARK_NEXT_SLICE_SELECTION.md + KM fact card; synced README/ROADMAP_V2/mdBook (16c+14)/TASK_TREE/KM/task tree. No behavior changed.
- in_flight_uncommitted: none expected after the `.779` handoff commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `.780`, the no-behavior readiness audit for bounded aggregate AHB BUSY-parking propagation; decide direct-implementation vs. contract-selection-first, then advance to `.781`.

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
