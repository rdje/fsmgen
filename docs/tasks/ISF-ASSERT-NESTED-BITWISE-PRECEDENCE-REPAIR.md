# ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR: Preserve Nested Bitwise Assertion Semantics

## Metadata

- Tree ID: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR`
- Status: `proposed`
- Roadmap lane: `R14 / generated verification correctness`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
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
  Status: `proposed`
  Goal: `Preserve nested bitwise expression semantics across concurrent-property inlining and repair the shipped AXI read false assertion.`
  Children: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1`, `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.2`

- ID: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1`
  Status: `pending`
  Goal: `Audit the exact assertion roundtrip owner and select the smallest general repair contract.`
  Acceptance: `Turn the legal 0x00000004 AXI read false assertion into a tracked deterministic reproduction; distinguish correct rule admission from incorrect property HDL; isolate whether intermediate inlining, AST reconstruction, or property rendering drops the grouping; compare a general AST-preserving fix with scoped workarounds; select exact t/1410-t/1412 and t/1507 coverage plus a following implementation leaf without changing behavior.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.2`
  Status: `pending`
  Goal: `Implement the selected general renderer repair and correct the AXI fixed-four read assertion proof.`
  Acceptance: `After .1 freezes the repair, preserve nested mixed-precedence bitwise ASTs through concurrent property rendering; add direct and intermediate/inlined regressions, assertion-enabled legal 0x00000004 AXI read proof, preservation gates, docs/facts/continuity, and commit. Keep rule admission and all unrelated generated HDL behavior unchanged.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-23`: Record the defect as proposed and inactive. The active `.44`
  audit uses an exhaustively equivalent renderer-safe predicate, so this
  defect does not block the selected AXI write-request path.
- `2026-07-23`: Require a general renderer audit before changing the shipped
  read source. A source-only De Morgan rewrite would hide the underlying
  assertion compiler defect from other users.

## Blockers

- None technical. Activation/order follows the task-tree pivot doctrine.
