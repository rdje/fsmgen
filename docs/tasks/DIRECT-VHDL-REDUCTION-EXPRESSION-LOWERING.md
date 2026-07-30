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
  Status: `active`
  Goal: `Audit and freeze the exact unary reduction-expression contract.`
  Acceptance: `Activate only from a clean roadmap-selected boundary. Reproduce scalar and vector unary reduction OR, AND, and XOR shapes through direct VHDL; distinguish valid identity lowering for scalar operands from vector reductions; inspect declaration widths and expression contexts; select the smallest correct lowering or explicit fail-closed boundary; freeze syntax, diagnostics, GHDL availability/qualification, focused tests, preservation, docs, same-volume cleanup, and rollback without changing behavior.`
  Verification: `Activated only after clean parent selector commit 5f904d2d2. Activation changes continuity pointers only; the current unary-reduction token leak, direct-VHDL/backend behavior, generated HDL, diagnostics, facade behavior, named-drive priority, parser/scheduler/lowering, other HDL targets, public reports/semantic/MCP APIs, AHB/accounting, HIAL/VIAL, scale, simulator profiles, decision 0020, and tests remain unchanged. Book/status/path gates pass 4 files/45 tests. Knowledge Map remains synchronized at 1,057 facts/5,433 question keys. The mdBook renders exactly 72 files/16,480,952 bytes and the exact repository-local output is removed. MEMORY.md is 50 lines, README.md is 2,341 lines, .artifacts/tmp/tests is empty, diff hygiene passes, and all six doctrine gates pass. Final canonical Stats-compatible capacity is 15,641,083,904/25,769,803,776 bytes = 14.567/24.000 GiB = 60.70%, with separate macOS kernel pressure level 1 and memory_pressure 72% free; guard occupancy is excluded from capacity truth. No background job remains.`
  Commit: `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1: activate reduction audit`

- ID: `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.2`
  Status: `proposed`
  Goal: `Implement the reduction-expression contract selected by .1.`
  Acceptance: `Activate only after .1 commits cleanly. Implement only the selected direct VHDL unary reduction translation or rejection, add facade/backend coverage and external VHDL compile coverage only when an authoritative compiler is available, preserve other expression families and backends, synchronize docs/Knowledge Map/mdBook, clean exact same-volume artifacts, run focused and broader gates, and commit with a clean handoff.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

Audit `.1` is active after clean parent selector commit `5f904d2d2`. It must
reproduce scalar and vector unary OR, AND, and XOR through the direct-VHDL
path, trace resolved widths and expression contexts, distinguish scalar
identity from vector reductions, and select exact translation or deterministic
fail-closed handling without changing product behavior.

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

## Open Questions

- Whether the first implementation should translate all unary reduction
  families or ship scalar identity plus fail-closed vector forms.
- Which VHDL compiler becomes the authoritative external validation profile.

## Blockers

- No VHDL compiler is installed in the current environment. This blocks an
  executable VHDL validation claim, not the future audit or fail-closed repair.

## Rollback

Rollback of activation restores this tree to proposed, `.1` to pending, and
clean selector commit `5f904d2d2` as the resume boundary. During the audit,
rollback must retain the exact reduction-token reproducer until corrected or
rejected.
