# ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR: Preserve Nested Bitwise Assertion Semantics

## Metadata

- Tree ID: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR`
- Status: `active`
- Roadmap lane: `R14 / generated verification correctness`
- Created: `2026-07-23`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Repair concurrent-property rendering so assertion/assumption/cover conditions
preserve the exact parsed AST semantics when intermediate expressions contain
nested bitwise operators of different precedence, then correct the shipped
AXI fixed-four read assertion and its coverage gap.

## Non-Goals

- Do not change the AXI fixed-four read admission behavior; it is already
  correct.
- Do not weaken or disable assertions as the repair.
- Do not pivot away from the active AXI write-request PNT frontier merely
  because that frontier exposed this pre-existing defect.
- Do not rewrite unrelated expression rendering without a proven contract.

## Root Cause Evidence

The shipped fixed-four read source expresses its 4-KiB guard with a nested
`(| addr[3] addr[2])` inside a long bitwise `&`. Rule lowering materializes the
inner OR as an intermediate and admits legal address `0x00000004`. Concurrent
property inlining instead emits the equivalent text without the required
parentheses, so SystemVerilog precedence interprets it as `(high & bit3) |
bit2`. The generated assertion therefore fails on the same legal command.

An assertion-enabled Verilator reproduction with legal address `0x00000004`
fails, while the generated behavioral guard remains correct. The issue is in
the assertion condition roundtrip/inlining path involving
`GeneratedModuleInfoBuilder::_render_check_condition_sv`, not the direct base
`BinaryOp->to_systemverilog` rendering of a manually built nested AST.

## Acceptance Criteria

- Preserve nested bitwise AST semantics in concurrent assert/assume/cover HDL.
- Keep the AXI fixed-four read admission set unchanged.
- Add a focused general regression under the concurrent-property owner and an
  assertion-enabled legal-bit2 AXI read regression.
- Prove direct and inlined/intermediate forms render and simulate equivalently.
- Keep the renderer-safe write-request predicate valid whether this repair is
  active or not.
- Update mdBook/facts/continuity if public verification behavior changes.
- Run focused property/AXI/backend and doctrine gates and commit per leaf.

## Task Tree

- ID: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR`
  Status: `active`
  Goal: `Preserve nested bitwise expression semantics across concurrent-property inlining and repair the shipped AXI read false assertion.`
  Children: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1`, `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.2`

- ID: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1`
  Status: `done`
  Goal: `Audit the exact assertion roundtrip owner and select the smallest general repair contract.`
  Acceptance: `Turn the legal 0x00000004 AXI read false assertion into a tracked deterministic reproduction; distinguish correct rule admission from incorrect property HDL; isolate whether intermediate inlining, AST reconstruction, or property rendering drops the grouping; compare a general AST-preserving fix with scoped workarounds; select exact t/1410-t/1412 and t/1507 coverage plus a following implementation leaf without changing behavior.`
  Verification: `Activated only after clean parent selector commit 1be57f7bd and clean continuity commit f57979155. A repository-local public AXI generation/AST trace proves the entire relevant property and expression graph is FSM::CoreAST: an overlapping-implication consequent reaches the renderer as an inlineable SignalRef; its driving AND reaches another inlineable SignalRef whose standalone driving OR renders without outer grouping. Direct BinaryOp rendering correctly emits high & (bit3 | bit2), while substitution erases that child-parent context and produces high & bit3 | bit2. Tracked t1544 passes 2 top-level subtests/13 nested assertions, freezing the direct renderer, property/CoreAST carrier, correct behavioral intermediate, malformed condition_sv, and malformed emitted property without changing product behavior. The audit selects explicit grouping around every successfully rendered inline-intermediate substitution; operator-pair special cases, global precedence plumbing, stopping inlining, CoreAST changes, and AXI source rewrites are rejected. Focused t1410-t1412+t1544+t1507 pass 5 files/23 top-level tests, and t404 passes 1 file/4 tests. Book/status/path truth gates pass 4 files/46 tests. An accidental broad invocation included known pre-existing t1250 focused-index drift and failed its one stale list comparison; the exact current gate excluded that separately owned test and passed, with no product failure. Knowledge Map generation/check passes at 1,060 facts/5,456 question keys. The mdBook renders exactly 72 files/16,513,744 bytes. Its first destination exposed a command-relative path trap and created that exact output outside the repo but on the same volume; the exact directory was censused, removed with zero residue, rebuilt successfully at repo-local book/build with the same census, and removed with zero residue. Eight disposable probe files/116,777 bytes are removed and .artifacts/tmp/tests is empty. MEMORY.md is 49 lines, README.md is 2,346 lines, syntax/diff hygiene and all six doctrine gates pass. Final canonical Stats-compatible capacity is 17,515,790,336/25,769,803,776 bytes = 16.313/24.000 GiB = 67.97%, with separate macOS kernel pressure level 1 and memory_pressure 75% free; guard occupancy is excluded from capacity truth. No product behavior changes and no background job remains.`
  Commit: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1: select AST-preserving substitution repair`

- ID: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.2`
  Status: `active`
  Goal: `Implement the selected general renderer repair and correct the AXI fixed-four read assertion proof.`
  Acceptance: `After .1 freezes the repair, preserve nested mixed-precedence bitwise ASTs through concurrent property rendering; add direct and intermediate/inlined regressions, assertion-enabled legal 0x00000004 AXI read proof, preservation gates, docs/facts/continuity, and commit. Keep rule admission and all unrelated generated HDL behavior unchanged.`
  Verification: `Activated only after clean audit commit 628ca0c33. Activation changes continuity pointers only: the selected grouping contract, current malformed assertion, correct behavioral admission, parser, carrier, CoreAST, renderer, emitter, generated HDL/runtime, public/report/semantic/MCP/support surfaces, tests, protocols/backends, HIAL/VIAL, scale, simulator profiles, and decision-0020 behavior remain unchanged until implementation begins. Book/status/path truth gates pass 4 files/46 tests. Knowledge Map generation/check remains synchronized at 1,060 facts/5,456 question keys. The mdBook renders exactly 72 files/16,515,405 bytes and its exact repository-local output is removed. .artifacts/tmp/tests is empty, MEMORY.md is 49 lines, README.md is 2,346 lines, diff hygiene and all six doctrine gates pass. Final canonical Stats-compatible capacity is 17,794,711,552/25,769,803,776 bytes = 16.573/24.000 GiB = 69.05%, with separate macOS kernel pressure level 1 and memory_pressure 75% free; guard occupancy is excluded from capacity truth. No background job remains.`
  Commit: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.2: activate substitution repair`

## Current Frontier

Clean audit commit `628ca0c33` activates implementation `.2` through a separate
continuity-only transition. The assertion defect and every shipped behavior
remain unchanged. `.2` now owns the one-branch inline-substitution grouping
repair and t1410-t1412/t1544/assertion-enabled-t1507 proof.

## Decisions

- `2026-07-23`: Record the defect as proposed and inactive. The active `.44`
  audit uses an exhaustively equivalent renderer-safe predicate, so this
  defect does not block the selected AXI write-request path.
- `2026-07-23`: Require a general renderer audit before changing the shipped
  read source. A source-only De Morgan rewrite would hide the underlying
  assertion compiler defect from other users.
- `2026-07-30`: Parent selector `.832` revalidates the current generated HDL:
  the behavioral path retains the nested OR through an intermediate while the
  concurrent property emits `high & bit3 | bit2`. Select audit `.1` ahead of
  broader HIAL/VIAL, scale, maintenance, protocol, and backend owners; activate
  it only after the clean selector commit.
- `2026-07-30`: Clean selector commit `1be57f7bd` activates audit `.1`
  continuity-only. No parser, lowering, assertion, HDL, runtime, public, or
  roadmap behavior changes during activation.
- `2026-07-30`: Exact recursive inspection rejects the suspected mixed-AST
  explanation. The generated property and all relevant leaves are CoreAST;
  direct precedence rendering is correct. Inline `SignalRef` substitution
  renders a driving child without carrying its former parent precedence, so
  the child-parent AST boundary disappears before the caller concatenates the
  strings.
- `2026-07-30`: Select explicit parentheses around every successfully rendered
  inline-intermediate replacement. This preserves the substituted AST as one
  expression for every operator/context with a one-branch change, while
  leaving cycle fallback, failed rendering, property operators, formal-only
  classification, CoreAST, behavioral lowering, and the emitter unchanged.
  Tracked t1544 characterizes the current defect; implementation `.2` must
  reconcile it and add the frozen focused/runtime coverage.
- `2026-07-30`: Clean audit commit `628ca0c33` activates implementation `.2`
  continuity-only. The malformed property and all product/test/runtime behavior
  remain unchanged during activation.

## Blockers

- None technical. Implementation `.2` is active.
