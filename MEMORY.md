# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD after this slice is `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.2: write the AW address-channel driver readiness audit`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.3` is pending (contract selection for the bounded **AW address-channel driver**). `.1` selected it (issue one `AWVALID` + AW payload `AWADDR`/`AWID`/`AWLEN`/`AWSIZE`/`AWBURST` against `AWREADY`, reusing `ppif/axi_aw_valid_ready.ppif` + the `AhbRequester.pm` drive-block/on-sample model, driven not observed). `.2` (done) wrote the readiness audit `docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_READINESS_AUDIT.md`: safe first-slice AW interface (inputs `aw_cmd_valid`/`awready`+payload; outputs `awvalid`+driven payload+`aw_busy`/`aw_done`), target ISF shape (`accept_command`/`assert_aw`/`finish` drive blocks + `aw_issue` transaction), fail-closed rules, and the exact owner map with `PPIF.pm` anchors (dispatch `:45-100`, clause `_contract_from_root` `:259`, `.axi` guard `:224`, predicates `:2822`/`:2845`; plus a new generator module, `RegressionCorpus.pm`/t248, `LanguageSurfaceSection.pm`/t297, a `t/14xx` modeled on `t/1473`, and a mdBook initiator section in `docs/book/src/16a-ial2-axi.md`). `.3` fixes the final `(axi-aw-driver …)` clause/module/schema names, driven-vs-sampled naming, `AWID` width policy, and whether the first slice drives `awaddr`+`awlen` only or the full burst-describing set (audit recommends the full set) — before the implementation leaf.
- recently_done: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.2` (done, this slice): wrote the AW-driver readiness audit (interface boundary + ISF shape + fail-closed rules + owner map + validation gates + deferrals), spot-verifying the `PPIF.pm` anchors; spawned `.3` (contract selection). `.1` earlier this session: selected the bounded AW address-channel driver (`docs/IAL2_AXI_MANAGER_INITIATOR_FIRST_INCREMENT_SELECTION.md`). Earlier (all committed): filed active owner `IAL2-AXI-MANAGER-INITIATOR-FRONTIER` (+ KM card ial2-axi-manager-initiator-pivot); `.785`/`.786`/`.787` AHB BUSY-insertion select/audit/contract; `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE` (proposed) for the AXI mdBook coverage gap. No behavior change in any; doc/continuity gates pass.
- deferred_not_abandoned: `IAL2-FEATURE-COMPLETENESS-FRONTIER.788` (implement the AHB requester BUSY-insertion source per the `.787` contract) is a durable pending leaf, deferred by the AXI-initiator pivot — resume anytime. Its full contract is in the `.788` task-tree node + docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_CONTRACT_SELECTION.md.
- in_flight_uncommitted: none expected after this commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The `.705` AHB source-reference artifact blocker is resolved through `.706`; `.707`-.772 now carry source facts, direct seed, public requester/subordinate/interconnect contracts, generated-IAL1 output reset/default substrate, public `.ppif` behavior, endpoint/aggregate `.ahb` aliases, byte-lane/narrow-transfer and byte-lane `SEQ` behavior, aggregate byte-lane and aggregate `SEQ` behavior, HBURST readiness/contract selection, shipped endpoint HBURST-aware byte-lane `SEQ` behavior + matching `.ahb` alias, shipped aggregate HBURST-aware `.ppif` behavior, and the complete matching aggregate HBURST `.ahb` alias family. Note (surfaced `.771`): the RAM guard's `host_memory_pct()` counts macOS inactive/cached memory as "used", so it reports ~90-99% and trips the 88% cutoff on an otherwise-healthy host (real usage ~55%, `memory_pressure` ~75% free); this blocks any command run under it, including the heavy t/248/prove gates. Lightweight/needed `fsmgen`/`prove` commands were run directly per COMMIT.md (guard is for broad/heavy runs only; real memory verified fine). Root-caused + tracked as proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (needs director approval to change the safety guard); fact card `docs/knowledge/ram-guard-macos-host-metric-over-reports.md`.
- next_action: Run `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.3`, the no-behavior contract selection for the bounded AW address-channel driver — resolve the open questions in `docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_READINESS_AUDIT.md` §8 (final `(axi-aw-driver …)` clause/module/schema names, driven-vs-sampled naming, `AWID` width policy, first-slice payload set) and record the contract in a repo-local note before the implementation leaf. (AHB `.788` BUSY-insertion impl stays a deferred pending leaf.)

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
  director request. Proposed `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE` owns presenting
  IAL2 as a coherent whole in the mdBook (one language / per-protocol profiles /
  optional `.axi`/`.ahb`/`.apb` aliases / layered lowering, decisions
  0014/0015/0016/0018) and backfilling the thin AXI chapter (142 `.ppif`, ~4%
  documented) — filed from a director question, documentation-only, director-activated.
  None of these trees is currently PNT-eligible.
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
