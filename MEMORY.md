# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD is `a1a6eec9a IAL2-FEATURE-COMPLETENESS-FRONTIER.807: select AHB active-transfer audit`; the selector committed cleanly and its message file was cleared before audit activation.
- active_work_unit: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1` is closing after runtime proof; pending `.2` owns exact one-next-phase completion-boundary recapture contract selection and must not activate until `.1` commits cleanly.
- DIRECTOR NORTH STAR (captured): the director's thinking-aloud future route (explicitly NO pivot) — a layered protocol-agnostic transactor architecture (transaction interface write/read single-or-burst upward; primitive per-(protocol,role) bus-adapter role blocks; composed into higher-order IAL2 entities that present the interface up the stack; sibling sub-blocks interact via it → bridges/converters; seed = the AHB requester `local-command`/`local-status`) is now captured as decision `docs/decisions/0020-ial2-layered-composable-transactor-roles.md` + proposed (not PNT-eligible) horizon owner `IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON`. Not scheduled; activate on director request.
- recently_done: `.1` generated-HDL t1519 proves two direct ready/OKAY NONSEQ/SEQ bus acceptances collapse to one internal admission/completion, captured address 0/NONSEQ, and storage 0x00000011 rather than 0x00002211. Endpoint-only boundary waiting would deadlock or accept the held phase, so `.2` is selected for atomic completion-boundary recapture contract work. Fact: `ial2-ahb-pipelined-active-transfer-runtime-audit`.
- RESOLVED (pre-existing two-subordinate BUSY report contradiction): `.799` aligned broader and burst residue for parked sources while preserving non-parking BUSY deferral; `.800` returns to paired contract selection.
- RESOLVED (AHB requester WRAP defect): pre-repair t1517 proved byte WRAP4 start=3 presented `3,1,2,3`; `.2` now increments then wraps in AhbRequester.pm and both direct seed paths. Current generated-HDL t1517 proves byte/halfword/word WRAP4 and byte WRAP8/16, including required `3,0,1,2`. Facts `ial2-ahb-requester-wrap-progression-runtime-audit` and `ial2-ahb-requester-wrap-progression-repair`.
- SURFACED (pre-existing public-sync drift): guarded ISF passed 293/295; t1131 omits an existing verification-observation presence key and t1250's spec index ends at t1453. Focused preservation also found t1474's old `.ahb` wrong-object regex omits the already-shipped two-subordinate wording while direct strict alias checking passes. Proposed inactive owner `PUBLIC-SYNC-TEST-DRIFT-REPAIR`; do not mix into `.788`.
- SURFACED (pre-existing, NOT AXI write `.44`): concurrent-property intermediate inlining loses grouping for the shipped read burst4 guard's nested bitwise OR, so its generated assertion falsely rejects legal address `0x00000004` while behavioral admission remains correct. Reproduced assertion-enabled; proposed general owner `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR`, fact `docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md`. The new write design uses an exhaustively equivalent renderer-safe predicate and is not blocked.
- SURFACED (pre-existing, NOT my regression): verifying `.4` via the heavy `t/1436` found 5 pre-existing failures, proven unrelated to the AW-driver change (commit `21bdd0947` touched neither the failing code nor tests): (1) a stale APB cardinality diagnostic regex in `t/1436` (~:3686) vs the extended message at `PPIF.pm:459`/`:245`; (2) a `WIDTHTRUNC` verilator lint in generated `axi0_capacity_status` SV (`!` on a 3-bit concat in the equality-to-zero lowering, from `AxiManagerCapacityStatus.pm`). Deterministic (not resource-induced). Tracked as proposed owner `IAL2-T1436-PREEXISTING-FAILURES`; `t/1436` is heavy + not in the routine gate, so these drifted undetected.
- SURFACED (pre-existing, NOT AXI `.22`): `mdbook test docs/book` compiles four untyped plain-text ISF diagrams as Rust and fails on Unicode/pseudocode; blame dates them to 2026-05-12..14 and `mdbook build` passes. Proposed owner `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1`; fact `docs/knowledge/mdbook-test-plain-text-fence-rustdoc-failure.md`.
- deferred_not_abandoned: decision 0020 and its transaction-layer horizon remain proposed/inactive; policy/multiple BUSY, distinct bus-BUSY status, larger bursts, general queues/outstanding transfers, and optional AHB signals remain outside the selected depth-one phase-recapture contract.
- in_flight_uncommitted: `.1` test/testbench, audit record/fact, book/roadmap/task/Memory/Knowledge Map closeout are being verified and committed; no generator/source/support/report/artifact/port/runtime behavior changed.
- blockers: none. Heavy audit runs use direct pressure/RSS monitoring because the macOS RAM-guard host metric remains a known proposed infra repair.
- next_action: Commit `.1` cleanly, then activate `.2` and contract-select the exact atomic completion-boundary recapture event/state/data ownership before any behavior implementation.

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
