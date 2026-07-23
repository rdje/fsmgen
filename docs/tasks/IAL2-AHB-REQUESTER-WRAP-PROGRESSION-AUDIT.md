# IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT: Audit Sequential Wrap Address Updates

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT`
- Status: `done`
- Roadmap lane: `IAL2 / AHB requester correctness`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
- Owner: repo-local workflow

## Goal

Determine whether the generated AHB requester advances a wrapping burst to
`wrap_base_q + addr_step_q` instead of `wrap_base_q` at the wrap boundary, then
repair the generated requester and direct seed together if runtime evidence
confirms the risk.

## Origin And Evidence

Inspection during `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.2` found the
same sequential-clause mutation pattern that caused the terminal count
underflow. Inside `when wrap_mode_q`, the first clause compares
`addr_q + addr_step_q` with `wrap_high_q` and may write `addr_q = wrap_base_q`;
the following negated-equality clause can then re-evaluate using the newly
written address and write `addr_q = addr_q + addr_step_q`.

At tree creation this was a latent risk established by source/FSM semantics,
not a runtime-proven defect. It was recorded rather than folded into the
terminal-counter repair because that slice owned only `SINGLE`/`INCR4`
completion and the then-pending BUSY-insertion slice could not expand into
unselected WRAP behavior. `.1` later runtime-confirmed the risk, allowing `.2`
to own the exact repair.

## Non-Goals

- Do not activate this direction while the current AHB BUSY-insertion task is
  still in flight.
- Do not change wrap arithmetic, burst admission, or public surfaces without a
  generated-HDL reproduction and selected contract.
- Do not alter non-wrap address progression.

## Acceptance Criteria

- Add a generated-HDL `WRAP4` boundary probe that records every accepted-beat
  address and distinguishes `wrap_base_q` from `wrap_base_q + addr_step_q`.
- Trace the emitted IAL1/FSM states to confirm or disprove re-evaluation after
  the first address write.
- If confirmed, select and implement a mutually exclusive wrap/non-wrap
  progression that preserves `SINGLE`/`INCR4` and other shipped behavior.
- Synchronize the requester behavior record, mdBook, Knowledge Map, tests,
  task/Memory, and all relevant gates before commit.

## Task Tree

- ID: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT`
  Status: `done`
  Goal: `Runtime-prove or disprove the suspected sequential WRAP address-update defect before selecting any repair.`
  Children: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.1, IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.2`

- ID: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.1`
  Status: `done`
  Goal: `Probe generated-HDL WRAP4 boundary progression and select a repair only if the risk reproduces.`
  Acceptance: `Build a deterministic public-requester WRAP4 runtime probe, record accepted-beat addresses through the boundary, correlate any wrong base-plus-step result with the sequential generated states, and either close the concern with evidence or select a bounded implementation leaf. Make no behavior change in the audit.`
  Verification: `Runtime-confirmed the defect through task-owned t/1517 and ahb_requester_wrap_progression_audit_tb.svt. The public requester generated IAL1 carries sequential wrap-to-base then negated increment clauses; generated IAL0 emits distinct numbered decision/set states. For byte WRAP4 start=3, base=0, high=4, the first state writes addr_q=0 and the following state re-tests the mutation and writes addr_q=1. Verilator-generated HDL completes four clean NONSEQ/SEQ/SEQ/SEQ transfers but presents 3,1,2,3 instead of required 3,0,1,2. The common path structurally affects WRAP4/8/16; SINGLE/INCR* and paired BUSY INCR4 are not affected by this defect. Selected .2 to increment first then wrap when the incremented addr_q equals wrap_high_q, in both AhbRequester.pm and both direct fsm/amba_requester.fsm paths, with no new local/public/report/support/artifact identity. t1517 passes 1 file/2 top-level tests under the 4096-MiB descendant guard; direct memory was 81% free before/after. Recorded docs/IAL2_AHB_REQUESTER_WRAP_PROGRESSION_RUNTIME_AUDIT.md plus fact ial2-ahb-requester-wrap-progression-runtime-audit. mdBook build, Knowledge Map, memory architecture, document-path, whitespace, and all doctrine gates passed; the disposable book build was removed. No behavior changed in .1.`
  Commit: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.1: prove WRAP boundary skip`

- ID: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.2`
  Status: `done`
  Goal: `Repair requester fixed-wrap address progression without changing public contracts.`
  Acceptance: `Implement exactly the .1-selected repair. In AhbRequester.pm, replace the successful non-final wrap-mode pair (boundary equality -> set base; negated equality -> increment) with one unconditional addr_q increment inside wrap_mode_q followed by a guard that sets addr_q=wrap_base_q when the incremented addr_q equals wrap_high_q. Apply the same safe sequential algorithm to both corresponding successful-response paths in fsm/amba_requester.fsm so the generated IAL2 requester and direct seed remain aligned. Keep the non-wrap increment unchanged. Update t1517 from defect reproduction to correctness proof and extend its single generated-HDL binary across the shared WRAP4/WRAP8/WRAP16 path and representative byte/halfword/word step behavior as warranted; require wrap-to-base before the next transfer. Preserve t1511 SINGLE/INCR4, t1498 BUSY insertion, t1513/t1515 paired INCR4 behavior, public source syntax, report/support accounting and schemas, artifact names, ports, diagnostics, subordinate/interconnect behavior, direct-seed SystemVerilog/VHDL lowering, decision 0020 inactivity, backends beyond the existing seed proof, AXI/APB, and VHDL behavior beyond the aligned direct seed. Sync behavior docs, README, ROADMAP_V2, mdBook, Knowledge Map, task tree, and Memory; run focused syntax/runtime/verify and doctrine gates under resource monitoring.`
  Verification: `Implemented the exact .1-selected repair in AhbRequester.pm and both corresponding successful-response paths in fsm/amba_requester.fsm: wrap mode increments addr_q once, then replaces the incremented wrap_high_q value with wrap_base_q; the non-wrap increment is unchanged. t1517 now proves generated IAL1/IAL0 ordering, both direct-seed repair sites, absence of the old mutation/retest pair, and one generated-HDL binary across byte WRAP4 start 3 -> 3,0,1,2; halfword WRAP4 start 6 -> 6,0,2,4; word WRAP4 start 12 -> 12,0,4,8; byte WRAP8 start 7 -> 7,0..6; and byte WRAP16 start 15 -> 15,0..14, with exact NONSEQ/SEQ controls, beat counts, and clean completion. Perl syntax passed for AhbRequester.pm, t1517, and the updated t310 direct-SV expectation. Strict direct seed check passed (amba_requester, 38 signals, 7 states); strict public .ahb check passed (54 signals, 102 states, exact support identity); public requester --verify-hdl passed Verilator/Yosys. Focused preservation passed t1473 (1 file/4 tests), t1498+t1511+t1517+t310 (4 files/14 tests), direct VHDL t1420 (1 file/64 tests), and paired generated-HDL t1513+t1515 (2 files/7 tests, 774 seconds) under the 4096-MiB descendant guard. Direct memory remained healthy at 81% free; the guard's known macOS host percentage remained non-authoritative. The initial broad suite also reproduced only the already-durable t1474 stale wrong-object regex drift while direct strict alias checking passed; that proposed PUBLIC-SYNC-TEST-DRIFT-REPAIR concern was not mixed into this slice. Added repair record/fact; converted the .1 audit/fact to historical context; synced README, ROADMAP_V2, mdBook current behavior/examples, task tree, Memory, and Knowledge Map. mdBook build, Knowledge Map validation, memory architecture, document paths, diff/whitespace, and doctrine gates passed; disposable book output was removed. Public clauses, ports, schemas, support counts, artifact identities, SINGLE/INCR*, BUSY insertion/compositions, subordinate/interconnect behavior, AXI/APB, decision 0020 inactivity, and all out-of-scope backends remain unchanged.`
  Commit: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.2: repair fixed-wrap progression`

## Decisions

- `2026-07-23`: Keep this tree proposed and inactive. It is a distinct
  unproven WRAP concern, not part of the terminal-count prerequisite or the
  already-selected requester BUSY-insertion contract.
- `2026-07-23`: `IAL2-FEATURE-COMPLETENESS-FRONTIER.804` selected this
  canonical audit as the next exact AHB owner after the complete paired BUSY
  family. It remains proposed until `.804` commits and the repository is clean;
  `.1` then owns activation plus runtime proof/disproof before any repair.
- `2026-07-23`: Activated `.1` from clean commit `f4ebc90d6`; the paired BUSY
  family and selector are committed, so the pivot prerequisite is satisfied.
- `2026-07-23`: `.1` runtime-confirmed byte WRAP4 start `3` produces
  `3,1,2,3` instead of `3,0,1,2`. Selected `.2` to increment first and then
  wrap the incremented address on equality with `wrap_high_q`, updating the
  generated requester and direct seed together.
- `2026-07-23`: Activated `.2` from clean audit commit `ec9fa2ee3`.
- `2026-07-23`: `.2` repaired the generated requester and both direct-seed
  success paths with increment-then-wrap sequencing; generated-HDL coverage now
  proves representative WRAP4/8/16 byte/halfword/word progressions and all
  focused preservation gates pass. The correctness tree is complete.

## Blockers

- None.
