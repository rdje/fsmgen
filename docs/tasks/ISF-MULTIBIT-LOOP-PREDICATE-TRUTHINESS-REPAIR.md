# ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR: Restore nonzero loop truthiness

## Metadata

- Tree ID: `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR`
- Status: `active`
- Roadmap lane: `R14 / ISF lowering correctness`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
- Owner: repo-local workflow

## Goal

Make bare multi-bit ISF `while`/`until` predicates obey nonzero truthiness in
generated FSM/HDL so a value such as five-bit `4` enters a `while` body and
zero exits it, unblocking the bounded AHB requester burst loop and its pending
BUSY-insertion source.

## Non-Goals

- Do not implement the AHB requester BUSY-insertion surface owned by
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.788`.
- Do not widen unrelated ISF control-flow, expression, backend, AXI/APB/AHB,
  verification-output, or VHDL behavior.
- Do not activate decision `0020` or its proposed transaction-interface horizon.

## Acceptance Criteria

- A focused direct ISF fixture proves a bare multi-bit loop predicate treats
  every nonzero value as true and zero as false at both loop entry and retest.
- The lowered FSM/HDL no longer tests a multi-bit loop condition as exactly
  one; one-bit loop behavior remains unchanged.
- Generated HDL simulation proves the shipped AHB requester can enter and
  finish an `INCR4` burst instead of stalling at the loop entry with
  `beats_remaining_q = 4`.
- Focused and broader relevant validation pass, with mdBook, Knowledge Map,
  task-tree index, and `MEMORY.md` synchronized.
- The completed leaf is committed through `COMMIT.md` before returning to
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.788`.

## Task Tree

- ID: `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR`
  Status: `active`
  Goal: `Restore nonzero truthiness for bare multi-bit ISF loop predicates.`
  Children: `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.1`, `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.2`

- ID: `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.1`
  Status: `done`
  Goal: `Repair and prove bare multi-bit while/until predicate lowering.`
  Acceptance: `Root-cause the emitted =1 selector behavior; implement the smallest shared ISF lowering repair that makes width>1 bare while/until predicates branch on nonzero at entry and retest while preserving one-bit behavior; add direct focused parser/schedule/FSM/HDL simulation coverage over every three-bit value; prove the generated AHB requester advances beyond its former beats_remaining_q=4 loop-entry stall; synchronize mdBook, a Knowledge Map fact, docs/TASK_TREE.md, the blocked .788 pointer, and MEMORY.md; run syntax, focused, relevant broad, mdBook, Knowledge Map, continuity, whitespace, and doctrine gates.`
  Verification: `LoweringIR syntax passed. t/1245 preserved the existing one-bit selector shape. New t/1510 passed structural/report checks plus generated-HDL Verilator simulation for all eight three-bit values and runtime proof that the public AHB requester crosses its former beats_remaining_q=4 stall. t/1473 requester preservation passed. ISF spec, mandatory downstream integration spec, public contract prose, mdBook 13d/13h, Knowledge Map fact/map, task/index, and Memory were synchronized. mdbook build, Knowledge Map, memory architecture, whitespace, and doctrine gates passed. The guarded broad ISF suite passed 293/295 files and every changed loop path; its only failures were the proven-pre-existing t/1131 public-key-list drift and t/1250 pre-t/1464 focused-index drift recorded under Decisions.`
  Commit: `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.1: restore nonzero loop truthiness`

- ID: `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.2`
  Status: `active`
  Goal: `Repair the AHB requester terminal-beat decrement ordering exposed after loop truthiness was restored.`
  Acceptance: `Root-cause and minimally repair the generated requester beat-loop sequence in which the beats_remaining_q==1 clause sets zero and the following logically complementary clause re-reads zero and decrements it to 31; preserve single and non-terminal burst behavior; add a generated-HDL INCR4 regression proving exactly four beat completions and request completion; synchronize AHB docs, a Knowledge Map fact, task/index/Memory, run focused and relevant broad gates, and commit before resuming .788.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-23`: Treat `.788` as blocked on this repair. A Verilator probe of
  generated `amba_requester_busy_insert` reached the width-five loop entry with
  `beats_remaining_q = 4`; generated HDL emitted true as
  `(beats_remaining_q == 1'b1)` and false as reduction-zero, so neither branch
  fired and the FSM stayed at loop-entry state 58 indefinitely. The same bare
  `(while beats_remaining_q ...)` exists in the shipped requester generator.
- `2026-07-23`: Repair shared ISF loop truthiness before resuming `.788`; do not
  hide the defect with an AHB-only explicit comparison or structural-only test.
- `2026-07-23`: After the shared condition repair allowed the requester to
  advance through remaining counts `4`, `3`, `2`, and `1`, runtime simulation
  exposed a second pre-existing defect: the terminal `when == 1` state writes
  zero, then the following `when != 1` state observes that new zero and writes
  `-1` (`31` at width five). Own that directly as `.2`; do not weaken the
  generated-HDL completion criterion.
- `2026-07-23`: Applied the reusable ISF public-sync checklist. `.1` changes
  lowering/runtime and generated `.fsm`/HDL behavior only for bare
  known-width multi-bit `while`/`until` conditions; it updates `ISF_SPEC`, the
  mandatory downstream integration spec, the public interface contract's
  tested-by prose, mdBook control-flow/lowering references, focused tests, and
  a Knowledge Map fact. Parser grammar, report schema/shape, manifest keys,
  public facade methods, resource/language registries, and library catalog are
  unchanged.
- `2026-07-23`: The guarded broad ISF suite independently confirmed two
  pre-existing public-sync failures outside `.1`: HEAD already contains
  `schedule_report_verification_observation_keys` in the public-contract
  payload but omits it from `public_top_level_presence_keys` (`t/1131`), and
  HEAD already tracks `t/1464` while the ISF spec focused-test index ends at
  `t/1453` (`t/1250`). `.1` adds its own `t/1510` spec link but does not absorb
  the older missing test range or public-key repair. Both need a dedicated
  public-contract/spec-index drift owner after this prerequisite tree dries
  out.

## Open Questions

- Whether the smallest correct owner is loop-state condition normalization or
  computed-test selector emission will be settled by `.1` using direct IR/FSM
  evidence; the public semantics remain nonzero=true and zero=false.

## Blockers

- None for `.1`; `.2` follows it before this tree can unblock
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.788`.

## Changelog

- `2026-07-23`: Created after runtime probing exposed the multi-bit loop-entry
  stall while implementing the AHB requester BUSY-insertion source.
