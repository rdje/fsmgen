# DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING: Lower Or Reject Reduction Expressions In Direct VHDL

## Metadata

- Tree ID: `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING`
- Status: `active`
- Roadmap lane: `Backends And Validation / direct VHDL correctness`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Make direct VHDL generation truthful for scheduled enable expressions that
contain SystemVerilog-style unary reductions, beginning with the scalar
`(|drive_start)` expression emitted by a transaction-invoked named drive.

## Origin And Evidence

Contract selection under
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2` generated the tracked
protocol-neutral named-drive probe through all three HDL targets. SystemVerilog
generation/runtime passed, and generated Verilog compiled with Icarus 13.0.
The direct VHDL scaffold command succeeded but emitted
`drive_zero_en and (|drive_zero_start)`, carrying the SystemVerilog reduction
token into VHDL instead of translating it or failing closed.

Code inspection traces the leak to `_sv_expr_to_vhdl` in
`perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm`: it translates spaced binary `|`
but has no unary reduction-expression branch. The current environment has no
`ghdl`, `nvc`, or `vcom`; the repository's VHDL external-validation contract
also remains explicitly deferred. The exact generated probe workspace was
removed after its three-file/19,070-byte census.

## Non-Goals

- Do not activate this tree while another task tree has uncommitted work.
- Do not silently claim full VHDL expression parity or GHDL validation.
- Do not couple this backend repair to named-drive priority lowering.
- Do not widen aggregate, package, composition, verification-output, or mixed-
  language VHDL support.

## Task Tree

- ID: `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING`
  Status: `active`
  Goal: `Make direct VHDL reduction-expression handling syntactically truthful and regression-backed.`
  Children: `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1, DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.2`

- ID: `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1`
  Status: `done`
  Goal: `Audit and freeze the exact unary reduction-expression contract.`
  Acceptance: `Activate only from a clean roadmap-selected boundary. Reproduce scalar and vector unary reduction OR, AND, and XOR shapes through direct VHDL; distinguish valid identity lowering for scalar operands from vector reductions; inspect declaration widths and expression contexts; select the smallest correct lowering or explicit fail-closed boundary; freeze syntax, diagnostics, GHDL availability/qualification, focused tests, preservation, docs, same-volume cleanup, and rollback without changing behavior.`
  Verification: `Activated only after clean parent selector commit 5f904d2d2 and clean continuity commit 77bcc9680. Repository-local public-pipeline and in-memory converter probes reproduce scalar/vector positive and complemented truthiness plus scalar/vector unary OR/AND/XOR. The actual named-drive operand is declaration-proven scalar. t1543 passes 3 top-level subtests/38 nested assertions and durably characterizes the current six-case converter matrix plus unchanged explicit one-operand source rejection. Direct-backend t1420 passes 64 subtests; the exact t386/t404 facade files pass 2 files/100 tests. The first aggregate command used obsolete short facade filenames after t1543/t1420 passed; the corrected tracked paths pass and no product failure occurred. Code trace establishes that declaration context already reaches continuous assignments but must also reach condition conversion. With no ghdl, nvc, or vcom available, the audit selects scalar identity/complement and vector/range/unresolved/compound/malformed fail-closed handling rather than unqualified native vector syntax. Book/status/path truth gates pass 4 files/45 tests. Knowledge Map generation/check passes at 1,058 facts/5,440 question keys. The mdBook renders exactly 72 files/16,485,893 bytes and the exact repository-local output is removed. Eight exact disposable audit files/18,546 bytes are removed; .artifacts/tmp/tests is empty. MEMORY.md is 50 lines, README.md is 2,342 lines, diff hygiene passes, and all six doctrine gates pass. Final canonical Stats-compatible capacity is 15,967,453,184/25,769,803,776 bytes = 14.871/24.000 GiB = 61.96%, with separate macOS kernel pressure level 1 and memory_pressure 73% free; guard occupancy is excluded from capacity truth. No product behavior changes and no background job remains.`
  Commit: `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1: select scalar reduction boundary`

- ID: `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.2`
  Status: `proposed`
  Goal: `Implement the reduction-expression contract selected by .1.`
  Acceptance: `Activate only after .1 commits cleanly. In the generated-expression adapter, lower parenthesized unary OR/AND/XOR over declaration-proven scalar identifiers or static bit selects to scalar identity and lower complemented forms to VHDL not. Thread declaration context into condition conversion. Before generic rewrites, reject every vector, range-slice, unresolved, compound, malformed, or residual unary reduction with a targeted direct-scaffold diagnostic. Do not widen the public source grammar or claim native vector-reduction/VHDL-compiler qualification. Update t1543 to the selected contract and t1542 to require token-free named-drive VHDL; preserve t1420 plus t386/t404 and all other expression/backend/public boundaries; synchronize docs/Knowledge Map/mdBook, clean exact same-volume artifacts, run focused and broader gates, and commit with a clean handoff.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

Audit `.1` is done and selects proposed implementation `.2`. The audit commit
must land cleanly before `.2` can activate. `.2` then owns scalar reduction
identity/complement, deterministic rejection of every unsupported reduction,
declaration-context threading, and executable regression proof.

## Decisions

- `2026-07-30`: Keep VHDL reduction-expression correctness separate from
  named-drive priority semantics. The shared scheduled FSM change may still be
  inspected through VHDL generation, but it cannot claim syntactically valid
  VHDL while the reduction token leaks.
- `2026-07-30`: Parent selector `.831` selects audit `.1` ahead of broader
  HIAL/VIAL, scale, AHB, ISF, simulator-profile, startup-alignment, defect, and
  other-backend owners. Selection changes no behavior; activation requires the
  clean selector commit.
- `2026-07-30`: Clean selector commit `5f904d2d2` activates only audit `.1`.
  The foreign reduction token and all backend/runtime behavior remain unchanged
  while the no-behavior evidence audit runs.
- `2026-07-30`: Audit `.1` proves the tracked named-drive operand is scalar,
  selects identity/complement for declared scalars and static bit selects, and
  selects pre-emission rejection for vector, range, unresolved, compound,
  malformed, or residual reductions. Public source arity remains unchanged;
  implementation belongs only to `.2` after this audit commits cleanly.

## Open Questions

- Which VHDL compiler becomes the authoritative external validation profile
  for a future native vector-reduction contract.

## Blockers

- No VHDL compiler is installed in the current environment. This blocks an
  executable VHDL validation claim, not the future audit or fail-closed repair.

## Rollback

Rollback of the audit removes its record, fact, and t1543 characterization;
restores `.1` to active at clean activation commit `77bcc9680`; and leaves the
current leak unchanged. After `.2` activates, rollback must preserve the
selected scalar-identity/vector-rejection boundary rather than restore silent
foreign-token emission.
