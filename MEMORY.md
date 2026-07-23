# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: current HEAD after this slice is `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.1: restore nonzero loop truthiness`; use `git log -1 --oneline` for the exact hash.
- active_work_unit: `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR` is active; `.1` is done and `.2` is the next active leaf, repairing the generated AHB requester terminal-beat `1 -> 0 -> 31` sequential-clause defect before `IAL2-FEATURE-COMPLETENESS-FRONTIER.788` can resume.
- DIRECTOR NORTH STAR (captured): the director's thinking-aloud future route (explicitly NO pivot) — a layered protocol-agnostic transactor architecture (transaction interface write/read single-or-burst upward; primitive per-(protocol,role) bus-adapter role blocks; composed into higher-order IAL2 entities that present the interface up the stack; sibling sub-blocks interact via it → bridges/converters; seed = the AHB requester `local-command`/`local-status`) is now captured as decision `docs/decisions/0020-ial2-layered-composable-transactor-roles.md` + proposed (not PNT-eligible) horizon owner `IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON`. Not scheduled; activate on director request.
- recently_done: `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.1` makes bare known-width width>1 `while`/`until` predicates explicit width-matched nonzero tests at entry/retest while preserving one-bit selectors and authored report text. New t1510 proves all 0..7 values in generated HDL and the public AHB requester crosses its former remaining=4 stall. Fact: `docs/knowledge/isf-multibit-loop-predicate-truthiness.md`.
- SURFACED (pre-existing, now `.2`): after `.1` restored AHB loop entry, generated-HDL INCR4 reached remaining=1 but the requester's sequential `when == 1` writes zero and the following `when != 1` re-reads zero and decrements to width-five 31. `.2` owns the minimal generator repair plus exact four-beat completion proof.
- SURFACED (pre-existing public-sync drift): the guarded ISF suite passed 293/295 files; only t1131 (verification-observation payload key omitted from `public_top_level_presence_keys`) and t1250 (spec index ends at t1453 despite HEAD tracking t1464+) failed. Proven present at HEAD and untouched by `.1`; create a dedicated drift owner after the active prerequisite tree dries out.
- SURFACED (pre-existing, NOT AXI write `.44`): concurrent-property intermediate inlining loses grouping for the shipped read burst4 guard's nested bitwise OR, so its generated assertion falsely rejects legal address `0x00000004` while behavioral admission remains correct. Reproduced assertion-enabled; proposed general owner `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR`, fact `docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md`. The new write design uses an exhaustively equivalent renderer-safe predicate and is not blocked.
- SURFACED (pre-existing, NOT my regression): verifying `.4` via the heavy `t/1436` found 5 pre-existing failures, proven unrelated to the AW-driver change (commit `21bdd0947` touched neither the failing code nor tests): (1) a stale APB cardinality diagnostic regex in `t/1436` (~:3686) vs the extended message at `PPIF.pm:459`/`:245`; (2) a `WIDTHTRUNC` verilator lint in generated `axi0_capacity_status` SV (`!` on a 3-bit concat in the equality-to-zero lowering, from `AxiManagerCapacityStatus.pm`). Deterministic (not resource-induced). Tracked as proposed owner `IAL2-T1436-PREEXISTING-FAILURES`; `t/1436` is heavy + not in the routine gate, so these drifted undetected.
- SURFACED (pre-existing, NOT AXI `.22`): `mdbook test docs/book` compiles four untyped plain-text ISF diagrams as Rust and fails on Unicode/pseudocode; blame dates them to 2026-05-12..14 and `mdbook build` passes. Proposed owner `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1`; fact `docs/knowledge/mdbook-test-plain-text-fence-rustdoc-failure.md`.
- deferred_not_abandoned: `IAL2-FEATURE-COMPLETENESS-FRONTIER.788` retains the `.787` AHB requester BUSY-insertion contract but is blocked on prerequisite `.2`; decision 0020 remains proposed/inactive.
- in_flight_uncommitted: none expected after this commit; ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: `.788` cannot resume until `.2` proves the shipped requester completes generated-HDL INCR4. The guarded broad ISF suite's t1131/t1250 public-sync drift is pre-existing and separately queued for a dedicated owner after this active tree; all changed-path tests pass. The macOS RAM-guard metric caveat remains tracked by `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT`.
- next_action: Implement `.2`: minimally make the AHB terminal-beat decrement clauses mutually exclusive, add exact four-beat generated-HDL completion proof, sync AHB docs/fact/task/Memory, commit, then return to blocked `.788`; keep decision 0020 proposed/inactive until ongoing work dries out.

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
